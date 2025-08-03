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

### Next Steps

- Configure similar storage on the second node if needed
- Create VM templates
- Set up backup policies

## Security Configuration

### User Management and Sudo Setup

#### 1. Install Required Packages

```bash
apt update
apt install sudo needrestart
```

#### 2. Create Administrative Group

```bash
# Create sysadmins group
groupadd sysadmins
```

#### 3. Create Administrative User

```bash
# Create user with proper group assignment
useradd -m -s /bin/bash -g sysadmins -c "Thomas Bonnet" maaseh

# Set password
passwd maaseh
```

#### 4. Configure Sudoers

Edit the sudoers file:

```bash
visudo
```

Add the following lines:

```
# User privilege specification
root    ALL=(ALL:ALL) ALL

# Group privilege specification  
%sysadmins      ALL=(ALL:ALL) ALL
%sudo   ALL=(ALL:ALL) ALL
```

#### 5. Create Directory Structure with Proper Permissions

```bash
# Create scripts directory
mkdir -p /bin/scripts/CustomScripts

# Create logs directories
mkdir -p /var/log/CustomLogs/daily-updates
mkdir -p /var/log/CustomLogs/weekly-updates

# Set ownership
chown -R maaseh:sysadmins /bin/scripts/CustomScripts
chown -R maaseh:sysadmins /var/log/CustomLogs

# Set permissions (setgid bit for group inheritance)
chmod 2774 /bin/scripts/CustomScripts
chmod 2774 /var/log/CustomLogs/daily-updates
chmod 2774 /var/log/CustomLogs/weekly-updates
```

#### 6. Verify Configuration

Test the setup:

```bash
# Switch to new user
su - maaseh

# Test sudo access
sudo whoami  # Should return "root"

# Verify directory permissions
ls -la /bin/scripts/
ls -la /var/log/CustomLogs/
```

## Automated Updates System

### Overview

The system implements a two-tier update strategy:
- **Daily security updates**: Critical security patches without reboot
- **Weekly kernel updates**: Kernel and system updates with intelligent reboot

### Security Updates (Daily)

#### Script: daily-security-updates.sh

**Location**: `/bin/scripts/CustomScripts/daily-security-updates.sh`

**Features**:
- Detects security updates using `apt-get -s dist-upgrade`
- Installs only security-related packages
- Comprehensive logging to `/var/log/CustomLogs/daily-updates/Security_updates.log`
- Service restart detection with `needrestart`
- Error handling and validation

#### Service Configuration

**Service file**: `/etc/systemd/system/security-updates.service`

```ini
[Unit]
Description=Daily Security Updates
After=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/scripts/CustomScripts/daily-security-updates.sh
User=root
```

**Timer file**: `/etc/systemd/system/security-updates.timer`

```ini
[Unit]
Description=Daily Security Updates Timer
Requires=security-updates.service

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=1h

[Install]
WantedBy=timers.target
```

### Kernel Updates (Weekly)

#### Script: weekly-kernel-updates.sh

**Location**: `/bin/scripts/CustomScripts/weekly-kernel-updates.sh`

**Features**:
- Detects kernel updates using targeted package filtering
- Installs kernel, headers, and related packages
- Intelligent reboot detection with `needrestart -r`
- Cluster notification via `wall` command
- Configurable reboot delay (60 seconds default)
- Comprehensive logging to `/var/log/CustomLogs/weekly-updates/Kernel_updates.log`

#### Service Configuration

**Service file**: `/etc/systemd/system/kernel-updates.service`

```ini
[Unit]
Description=Weekly Kernel Updates

[Service]
Type=oneshot
ExecStart=/bin/scripts/CustomScripts/weekly-kernel-updates.sh
User=root
```

**Timer file**: `/etc/systemd/system/kernel-updates.timer`

```ini
[Unit]
Description=Weekly Kernel Updates Timer
Requires=kernel-updates.service

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
```

### Enable and Start Services

```bash
# Enable and start security updates
systemctl enable security-updates.timer
systemctl start security-updates.timer

# Enable and start kernel updates  
systemctl enable kernel-updates.timer
systemctl start kernel-updates.timer

# Verify timers are active
systemctl list-timers
```

### Monitoring and Logs

**Log locations**:
- Security updates: `/var/log/CustomLogs/daily-updates/Security_updates.log`
- Kernel updates: `/var/log/CustomLogs/weekly-updates/Kernel_updates.log`

**Check timer status**:
```bash
# View timer status
systemctl status security-updates.timer
systemctl status kernel-updates.timer

# View recent service runs
journalctl -u security-updates.service
journalctl -u kernel-updates.service
```

### Security Best Practices

- **Avoid direct root login** for daily operations
- **Use groups for role-based access** (sysadmins, developers, etc.)
- **Regular security updates** via automated scripts
- **Monitor sudo usage** in logs (/var/log/auth.log)
- **Staggered reboots** in cluster environment (pve1 at 3h, pve2 at 4h)
- **Comprehensive logging** for audit and troubleshooting
