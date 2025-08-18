# K3s Configuration

## VM Creation

### Base VMs Setup

Created two VMs with Ubuntu Server 24.04.2 LTS for the K3s cluster:

#### VM Master (k3s-master) - PVE1
- **VM ID:** 100
- **OS:** Ubuntu Server 24.04.2 LTS
- **RAM:** 6GB (6144MB)
- **vCPU:** 3 cores
- **Disk:** 40GB (qcow2 format)
- **Storage:** data-storage (pve1)
- **Network:** vmbr0 bridge

#### VM Worker (k3s-worker) - PVE2
- **VM ID:** 101
- **OS:** Ubuntu Server 24.04.2 LTS
- **RAM:** 6GB (6144MB)
- **vCPU:** 3 cores
- **Disk:** 40GB (qcow2 format)
- **Storage:** data-storage (pve2)
- **Network:** vmbr0 bridge

### VM Configuration Notes

- **BIOS:** SeaBIOS (default)
- **TPM:** Disabled
- **QEMU Agent:** Enabled
- **Cache:** Write back
- **Network Model:** VirtIO

## Cluster Configuration

### Network Configuration

- **Network Range:** 172.16.10.0/24
- **Gateway:** 172.16.10.1
- **DNS:** 172.16.10.1, 8.8.8.8

### Node Details

#### K3s Master Node
- **IP Address:** 172.16.10.100
- **Hostname:** k3s-master
- **Role:** Control Plane (API Server, etcd, Scheduler)
- **Services:** System services, Ingress Controller, Monitoring

#### K3s Worker Node  
- **IP Address:** 172.16.10.101
- **Hostname:** k3s-worker
- **Role:** Worker Node (Application workloads)
- **Services:** Application pods, Databases, Web services

### Cluster Status

```bash
# Cluster nodes
kubectl get nodes
# NAME         STATUS   ROLES                  AGE
# k3s-master   Ready    control-plane,master   
# k3s-worker   Ready    <none>                 

# All system pods
kubectl get pods -A
```

### K3s Installation Commands

#### Master Node (172.16.10.100)
```bash
curl -sfL https://get.k3s.io | sh -
```

#### Worker Node (172.16.10.101)
```bash
curl -sfL https://get.k3s.io | K3S_URL=https://172.16.10.100:6443 K3S_TOKEN=<master-token> sh -
```

## Cluster Validation

### Test Application Deployment
```bash
# Deploy test nginx pod
kubectl run test-nginx --image=nginx --port=80

# Expose as NodePort service
kubectl expose pod test-nginx --port=80 --type=NodePort

# Verify cluster networking
kubectl get pods -o wide
kubectl get services
```

### Persistent Storage Configuration

#### Created PVC for testing
```yaml
# /etc/rancher/k3s/pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 2Gi
```

#### Deployed Grafana with persistent storage
```yaml
# grafana-simple.yaml
apiVersion: v1
kind: Pod
metadata:
  name: grafana
  labels:
    app: grafana
spec:
  containers:
  - name: grafana
    image: grafana/grafana:latest
    ports:
    - containerPort: 3000
    volumeMounts:
    - name: grafana-data
      mountPath: /var/lib/grafana
  volumes:
  - name: grafana-data
    persistentVolumeClaim:
      claimName: test-pvc
```

### Services Access
- **Grafana:** Accessible via service port-forward on port 3000
- **Test applications:** Accessible via NodePort on both nodes (172.16.10.100 and 172.16.10.101)

## Current Status

✅ **Cluster operational** - Both nodes ready and communicating  
✅ **Networking validated** - Pod-to-pod and external access working  
✅ **Persistent storage** - Local path provisioner configured and tested  
✅ **First real application** - Grafana deployed with persistent data  

## Next Steps

- [ ] Deploy Prometheus for monitoring data source
- [ ] Configure ingress controller for domain-based access
- [ ] Deploy GitLab CE for CI/CD pipeline
- [ ] Set up monitoring dashboards in Grafana
- [ ] Implement backup strategy for persistent volumes
