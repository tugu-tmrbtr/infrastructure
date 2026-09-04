# MySQL + phpMyAdmin Kubernetes Deployment

This project sets up a MySQL database and phpMyAdmin interface on a Kubernetes cluster using:

- Separate YAML files for each resource
- Persistent storage for MySQL
- Internal service connections
- Ingress routing to `phpmyadmin.local`

---

## 🗂 Project Structure

```bash
.
├── namespace.yaml
├── mysql-pv.yaml
├── mysql-pvc.yaml
├── mysql-deployment.yaml
├── mysql-service.yaml
├── phpmyadmin-deployment.yaml
├── phpmyadmin-service.yaml
├── phpmyadmin-ingress.yaml
└── README.md

```

## 🚀 Deployment Steps
Apply the manifests in order to deploy the full stack:

```bash
# 1. Create namespace
kubectl apply -f namespace.yaml

# 2. Create persistent volume (cluster-wide)
kubectl apply -f mysql-pv.yaml

# 3. Create PVC in namespace
kubectl apply -f mysql-pvc.yaml

# 4. Deploy MySQL
kubectl apply -f mysql-deployment.yaml
kubectl apply -f mysql-service.yaml

# 5. Deploy phpMyAdmin
kubectl apply -f phpmyadmin-deployment.yaml
kubectl apply -f phpmyadmin-service.yaml

# 6. Create Ingress rule
kubectl apply -f phpmyadmin-ingress.yaml
```

## 📋 Get All Resources in Namespace
To list all workloads (pods, deployments, services, replica sets) in the php-mysql-admin namespace:

```bash
kubectl get all -n php-mysql-admin
```

## 🧹 Cleanup
To completely remove all resources created by this setup:

```bash
# Delete the entire namespace and all resources within
kubectl delete namespace php-mysql-admin

# Delete the PersistentVolume (cluster-scoped) separately
kubectl delete -f mysql-pv.yaml

# Delete local /mnt/data/mysql
sudo rm -rf /mnt/data/mysql
```