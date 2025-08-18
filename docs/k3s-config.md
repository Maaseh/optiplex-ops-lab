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

- **Network Range:** 10.0.10.0/24
- **Gateway:** 10.0.10.1
- **DNS:** 10.0.10.1, 8.8.8.8

### Node Details

**K3S Master Node**

- **IP Address:** 10.0.10.100
- **Hostname:** k3s-master
- **Role:** Control Pane (API Server, etcd, Scheduler)
- **Services:** System services, Ingress Controller, Monitoring

**K3S Worker Node**

- **IP Address:** 10.0.10.101
- **Hostname:** k3s-worker
- **Role:** Worker node (Application workload)
- **Services:** application pods, Databases, Web Services

### Cluster Status

```

```

### K3S Installation Commands

**Master Node**

```
curl -sfL https://get.k3s.io | sh -

```

**Worker Node**

```
curl -sfL https://get.k3s.io | K3S_URL=https://10.0.10.100:6443 K3S_TOKEN=<master-token> sh -
```
## Next Steps

- [x] Complete Ubuntu Server installation on both VMs
- [x] Configure static IP addresses
- [x] Install and configure K3s cluster
- [x] Set up cluster networking
- [ ] Deploy first test application
