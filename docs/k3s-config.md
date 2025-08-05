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

## Next Steps

- [ ] Complete Ubuntu Server installation on both VMs
- [ ] Configure static IP addresses
- [ ] Install and configure K3s cluster
- [ ] Set up cluster networking
- [ ] Deploy first test application
