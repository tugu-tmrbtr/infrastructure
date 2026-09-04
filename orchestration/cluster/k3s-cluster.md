# 🚀 K3s HA Cluster – FULL FRIENDLY GUIDE (AlmaLinux 9)

> **Status:** ✅ Rancher
> **Scope:** AlmaLinux 9 + K3s HA + kube-vip + MetalLB + Ingress-NGINX + Rancher
> **Style:** Friendly, copy‑paste ready, production‑safe

---

## 🧱 Architecture Overview

```
Client / Browser
   ↓
MetalLB VIP (172.30.200.21)
   ↓
Ingress‑NGINX
   ↓
Rancher UI

kubectl / nodes
   ↓
kube‑vip API VIP (172.30.200.19)
   ↓
K3s Control Plane (3 nodes, embedded etcd)
```

---

## 📌 Environment

### Nodes

| Node  | IP           |
| ----- | ------------ |
| node1 | 172.30.200.22 |
| node2 | 172.30.200.23 |
| node3 | 172.30.200.24 |

### VIPs

| Purpose                   | IP           |
| ------------------------- | ------------ |
| Kubernetes API (kube‑vip) | 172.30.200.19 |
| Ingress / LB (MetalLB)    | 172.30.200.21 |

### OS / Network

* OS: **AlmaLinux 9**
* Interface: **ens192**

---

# 🟢 STEP 1: AlmaLinux 9 – Pre‑Setup (ALL NODES)

### 1.1 Hostname

```bash
hostnamectl set-hostname nodeX
```

### 1.2 Disable SELinux

```bash
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
```

### 1.3 Disable Swap

```bash
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
```

### 1.4 Kernel + sysctl

```bash
cat <<EOF >/etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter
```

```bash
cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF
sysctl --system
```

### 1.5 Firewall

```bash
systemctl enable firewalld --now
firewall-cmd --permanent --add-port={6443,2379-2380,10250,80,443}/tcp
firewall-cmd --permanent --add-port=8472/udp
firewall-cmd --reload
```

### 1.6 Time sync

```bash
dnf install -y chrony
systemctl enable chronyd --now
```

### 1.7 /etc/hosts

```bash
cat <<EOF >>/etc/hosts
172.30.200.19 k8s-api-vip
172.30.200.21 rancher.starfall.k3s
172.30.200.22 node1
172.30.200.23 node2
172.30.200.24 node3
EOF
```

Reboot:

```bash
reboot
```

---

# 🟢 STEP 2: K3s HA – First Control Plane (node1)

```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --cluster-init \
  --tls-san=172.30.200.19 \
  --disable=traefik \
  --disable=servicelb \
  --write-kubeconfig-mode=644
```

```bash
mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sed -i 's/127.0.0.1/172.30.200.19/g' ~/.kube/config
kubectl get nodes
```

Save token:

```bash
cat /var/lib/rancher/k3s/server/node-token
```

---

# 🟢 STEP 3: kube‑vip (Kubernetes API HA)

### 3.1 RBAC + ServiceAccount

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube-vip
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kube-vip
rules:
- apiGroups: [""]
  resources: ["services","endpoints","nodes","pods"]
  verbs: ["get","list","watch"]
- apiGroups: ["coordination.k8s.io"]
  resources: ["leases"]
  verbs: ["get","list","watch","create","update","patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-vip
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kube-vip
subjects:
- kind: ServiceAccount
  name: kube-vip
  namespace: kube-system
EOF
```

### 3.2 kube‑vip DaemonSet

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: kube-vip
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: kube-vip
  template:
    metadata:
      labels:
        app: kube-vip
    spec:
      serviceAccountName: kube-vip
      hostNetwork: true
      containers:
      - name: kube-vip
        image: ghcr.io/kube-vip/kube-vip:v0.7.0
        args: ["manager"]
        env:
        - name: vip_interface
          value: "ens192"
        - name: address
          value: "172.30.200.19"
        - name: vip_cidr
          value: "32"
        - name: port
          value: "6443"
        - name: vip_arp
          value: "true"
        - name: cp_enable
          value: "true"
        - name: vip_leaderelection
          value: "true"
        securityContext:
          privileged: true
          capabilities:
            add: ["NET_ADMIN","NET_RAW"]
      nodeSelector:
        node-role.kubernetes.io/control-plane: "true"
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
EOF
```

Verify:

```bash
ip addr show ens192 | grep 172.30.200.19
ping -c 2 172.30.200.19
```

---

# 🟢 STEP 4: Join node2 & node3

```bash
export K3S_URL="https://172.30.200.19:6443"
export K3S_TOKEN="<NODE_TOKEN>"

curl -sfL https://get.k3s.io | sh -s - server \
  --server $K3S_URL \
  --token $K3S_TOKEN \
  --disable=traefik \
  --disable=servicelb
```

---

# 🟢 STEP 5: MetalLB (Ingress VIP)

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
```

```bash
cat <<EOF | kubectl apply -f -
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
  name: ingress-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - ingress-pool
  interfaces:
  - ens192
EOF
```

---

# 🟢 STEP 6: Ingress‑NGINX

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml
```

```bash
kubectl patch svc ingress-nginx-controller -n ingress-nginx \
  -p '{"spec":{"externalTrafficPolicy":"Local"}}'
```

Verify:

```bash
kubectl get svc -n ingress-nginx
# EXTERNAL-IP = 172.30.200.21
```

---

# 🟢 STEP 7: Cert-Manager (TLS)

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
```

```bash
kubectl wait -n cert-manager \
--for=condition=ready pod \
-l app.kubernetes.io/instance=cert-manager \
--timeout=300s
```

---

# 🟢 STEP 8: Rancher (SUCCESS 🎉)

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

```bash
mkdir -p /root/.kube
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
sed -i 's/127.0.0.1/172.30.200.19/g' /root/.kube/config
export KUBECONFIG=/root/.kube/config
```

```bash
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update
kubectl create namespace cattle-system
```

```bash
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.starfall.k3s \
  --set replicas=3 \
  --set ingress.ingressClassName=nginx \
  --set ingress.tls.source=rancher \
  --timeout=15m --wait
```

Access:
👉 **[https://rancher.starfall.k3s](https://rancher.starfall.k3s)**

---

## ✅ DONE

* K3s HA ✅
* API HA (kube‑vip) ✅
* LoadBalancer (MetalLB) ✅
* Ingress‑NGINX ✅
* Rancher HA ✅

🎉 **Production‑ready K3s HA cluster complete!**