# Kubernetes HA Cluster Guide (AlmaLinux 9 + kubeadm)

## Architecture

| Component | IP |
|---------|----|
| node1 | 172.30.200.22 |
| node2 | 172.30.200.23 |
| node3 | 172.30.200.24 |
| kube-vip (API VIP) | 172.30.200.19:6443 |
| MetalLB (Ingress IP) | 172.30.200.21 |
| Network Interface | ens192 |
| OS | AlmaLinux 9 |
| Kubernetes | kubeadm |

---

## A. Base OS Preparation (ALL NODES)

### Hostname
```bash
hostnamectl set-hostname node1   # on node1
hostnamectl set-hostname node2   # on node2
hostnamectl set-hostname node3   # on node3
```

### /etc/hosts
```bash
cat >> /etc/hosts <<EOF
172.30.200.22 node1
172.30.200.23 node2
172.30.200.24 node3
EOF
```

### Disable Swap
```bash
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
```

### SELinux (permissive)
```bash
setenforce 0 || true
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
```

### Kernel & sysctl
```bash
modprobe overlay
modprobe br_netfilter

cat >/etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

cat >/etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sysctl --system
```

### Firewalld (lab/dev)
```bash
systemctl disable --now firewalld || true
```

---

## B. Container Runtime (ALL NODES)

```bash
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf -y install containerd.io
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl enable --now containerd
```

---

## C. Kubernetes Packages (ALL NODES)

```bash
cat >/etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl
EOF
```

```bash
dnf -y install kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet
```

---

## D. Cluster Init (node1)

```bash
export VIP=172.30.200.19
export IFACE=ens192
sudo ip addr add ${VIP}/32 dev ${IFACE}

kubeadm init \
  --control-plane-endpoint "172.30.200.19:6443" \
  --upload-certs \
  --pod-network-cidr "192.168.0.0/16"
```

```bash
mkdir -p ~/.kube
cp /etc/kubernetes/admin.conf ~/.kube/config
chown $(id -u):$(id -g) ~/.kube/config
```

---

## E. CNI (Calico) (node1)

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml
```

---

## F. kube-vip v0.8.4 (STATIC POD) – node1

```bash
export VIP=172.30.200.19
export IFACE=ens192

mkdir -p /etc/kubernetes/manifests
ctr -n k8s.io images pull ghcr.io/kube-vip/kube-vip:v0.8.4

ctr -n k8s.io run --rm --net-host \
  --cap-add CAP_NET_ADMIN --cap-add CAP_NET_RAW \
  ghcr.io/kube-vip/kube-vip:v0.8.4 kvgen \
  /kube-vip manifest pod \
    --interface ${IFACE} \
    --address ${VIP} \
    --controlplane \
    --arp \
    --leaderElection \
| tee /etc/kubernetes/manifests/kube-vip.yaml
```

```bash
kubectl -n kube-system get pods | grep kube-vip
sudo ip addr del 172.30.200.19/32 dev ens192 || true
```

---

## G. Join node2 & node3 (Control Plane)

```bash
kubeadm join 172.30.200.19:6443 \
  --token <TOKEN> \
  --discovery-token-ca-cert-hash sha256:<HASH> \
  --control-plane \
  --certificate-key <CERT_KEY>
```
```bash
mkdir -p ~/.kube
cp /etc/kubernetes/admin.conf ~/.kube/config
chown $(id -u):$(id -g) ~/.kube/config
```

```bash
export VIP=172.30.200.19
export IFACE=ens192

mkdir -p /etc/kubernetes/manifests
ctr -n k8s.io images pull ghcr.io/kube-vip/kube-vip:v0.8.4

ctr -n k8s.io run --rm --net-host \
  --cap-add CAP_NET_ADMIN --cap-add CAP_NET_RAW \
  ghcr.io/kube-vip/kube-vip:v0.8.4 kvgen \
  /kube-vip manifest pod \
    --interface ${IFACE} \
    --address ${VIP} \
    --controlplane \
    --arp \
    --leaderElection \
| tee /etc/kubernetes/manifests/kube-vip.yaml
```
```bash
kubectl taint nodes node1 node-role.kubernetes.io/control-plane- || true
  109  kubectl taint nodes node2 node-role.kubernetes.io/control-plane- || true
  110  kubectl taint nodes node3 node-role.kubernetes.io/control-plane- || true
```

## H. MetalLB

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml
kubectl -n metallb-system get pods
```

```bash
kubectl apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: ingress-pool
  namespace: metallb-system
spec:
  addresses:
  - 172.30.200.21/32
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2adv
  namespace: metallb-system
spec:
  ipAddressPools:
  - ingress-pool
EOF
```

```bash
kubectl -n metallb-system get ipaddresspool,l2advertisement
```

---

## I. ingress-nginx

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/cloud/deploy.yaml
```

```bash
kubectl -n ingress-nginx patch svc ingress-nginx-controller -p '{
  "spec": {
    "type": "LoadBalancer",
    "loadBalancerIP": "172.30.200.21"
  }
}'
```

---

## J. cert-manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.6/cert-manager.yaml
```

---

## K. Rancher

```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update

kubectl create namespace cattle-system

helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=rancher.stormhold.k8s \
  --set replicas=3
```

---

## DNS / hosts

```
172.30.200.21 rancher.stormhold.k8s
```