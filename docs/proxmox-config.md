# Proxmox Configuration

## Repository Configuration

### 1. Disable Enterprise Repository

Comment all lines in the enterprise repository file:

```bash
nano /etc/apt/sources.list.d/pve-enterprise.list
```

Comment the line by adding `#` at the beginning:
```
#deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise
```

### 2. Configure Ceph Repository

Edit the Ceph repository file:

```bash
nano /etc/apt/sources.list.d/ceph.list
```

Comment the enterprise line and add the no-subscription line:
```
# Comment this line:
#deb https://enterprise.proxmox.com/debian/ceph-quincy bookworm enterprise

# Add this line:
deb http://download.proxmox.com/debian/ceph-quincy bookworm no-subscription
```

### 3. Update Main Sources List

Add the following repositories to the main sources file:

```bash
nano /etc/apt/sources.list
```

Add these lines:
```
deb http://ftp.debian.org/debian bookworm main contrib
deb http://ftp.debian.org/debian bookworm-updates main contrib

# Proxmox VE pve-no-subscription repository provided by proxmox.com,
# NOT recommended for production use
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription

# security updates
deb http://security.debian.org/debian-security bookworm-security main contrib
```

### 4. Update Package Lists

After configuring repositories, update the package lists:

```bash
apt update
apt upgrade -y
```

## Notes

- The `pve-no-subscription` repository is suitable for testing and learning environments
- For production environments, consider using the enterprise repository with a valid subscription
- These changes eliminate the "No valid subscription" warnings in the web interface

## Cluster Setup

### Prerequisites

Before creating the cluster, ensure:

- All nodes must be able to connect to each other via UDP ports 5405-5412 for corosync to work
- Date and time must be synchronized
- An SSH tunnel on TCP port 22 between nodes is required
- If you are interested in High Availability, you need to have at least three nodes for reliable quorum. All nodes should have the same version
- We recommend a dedicated NIC for the cluster traffic, especially if you use shared storage
- The root password of a cluster node is required for adding nodes
- Online migration of virtual machines is only supported when nodes have CPUs from the same vendor. It might work otherwise, but this is never guaranteed

### Cluster Creation Steps

**Cluster Name:** OptiplexCluster  
**Network:** 172.16.10.0/24  

#### 1. Create Cluster on First Node (pve1 - 172.16.10.10)

```bash
pvecm create OptiplexCluster
```

#### 2. Add Second Node (pve2 - 172.16.10.11)

```bash
pvecm add 172.16.10.10
```

Enter the root password of the first node when prompted.

#### 3. Verify Cluster Status

On both nodes, verify the cluster is working:

```bash
pvecm status
```

### Expected Output

Successful cluster status should show:

```
Cluster information
-------------------
Name:             OptiplexCluster
Config Version:   2
Transport:        knet
Secure auth:      on

Quorum information
------------------
Nodes:            2
Quorate:          Yes

Votequorum information
----------------------
Expected votes:   2
Total votes:      2
Quorum:           2
Flags:            Quorate

Membership information
----------------------
    Nodeid      Votes Name
0x00000001          1 172.16.10.10
0x00000002          1 172.16.10.11
```

### Network Ports

Ensure the following ports are open between cluster nodes:

- **TCP 22:** SSH tunnel
- **UDP 5405-5412:** Corosync cluster communication
- **TCP 8006:** Proxmox web interface
- **TCP 3128:** SPICE proxy (optional)

### Web Interface Access

After cluster creation, both nodes can be managed from either web interface:

- **pve1:** https://172.16.10.10:8006
- **pve2:** https://172.16.10.11:8006

The cluster provides a **unified management interface** - you can manage both nodes from a single web interface. In the sidebar, you'll see both nodes under the datacenter tree structure.

## Storage Configuration

### Adding Additional Storage (2TB NVMe)

Each node can have additional local storage configured for VMs and containers.

#### 1. Format the Additional Disk

```bash
# Format the second NVMe drive with ext4
mkfs.ext4 /dev/nvme0n1
```

#### 2. Create Mount Point and Mount

```bash
# Create mount point
mkdir /mnt/data-storage

# Mount the disk
mount /dev/nvme0n1 /mnt/data-storage
```

#### 3. Make Mount Permanent

Add to `/etc/fstab` for automatic mounting at boot:

```bash
echo "/dev/nvme0n1 /mnt/data-storage ext4 defaults 0 2" >> /etc/fstab
```

#### 4. Add Storage to Proxmox

```bash
# Add the storage to Proxmox configuration
pvesm add dir data-storage --path /mnt/data-storage --content images,iso,vztmpl,backup,snippets
```

#### 5. Verify Storage

The new storage should appear in the web interface under:
**Datacenter → Storage → data-storage**

### Storage Architecture

**Current setup uses local storage per node:**
- Each node manages its own storage independently
- VMs created on a node use that node's local storage
- Simple and robust for learning environment
- No shared storage dependencies
