#!/bin/bash

################################################
#
# Author: Thomas "maaseh" Bonnet
# Description: Create VMs on Proxmox cluster
# Type: Manual execution script
#
################################################

# Variables
LOG_DIR="/var/log/CustomLogs/vm-creation"
LOG_FILE="$LOG_DIR/vm_creation_$(date +%Y%m%d_%H%M%S).log"
ISO_DIR="/var/lib/vz/template/iso"
STORAGE_VM="data-storage"  # Storage for VM disks on 2TB NVMe
STORAGE_ISO="local"        # Storage for ISO files
BRIDGE="vmbr0"            # Network bridge

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Exit on any error
set -e

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

# Start logging
(
    echo "=== Proxmox VM Creation Script ==="
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo ""
) | tee "$LOG_FILE"

# Function to log and display
log_msg() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Function to log error and exit
log_error() {
    echo "ERROR: $1" | tee -a "$LOG_FILE"
    exit 1
}

# Get next available VM ID
get_next_vmid() {
    local next_id=100
    while qm status $next_id &>/dev/null; do
        ((next_id++))
    done
    echo $next_id
}

# Main script starts here
log_msg "Starting VM creation process..."
log_msg ""

# Get next VM ID
VM_ID=$(get_next_vmid)
log_msg "Next available VM ID: $VM_ID"
log_msg ""

# VM Name
read -p "Enter a name for the VM: " VM_NAME
if qm list 2>/dev/null | grep -q "$VM_NAME"; then
    log_msg "WARNING: $VM_NAME already exists, adding '_$VM_ID' to the name"
    VM_NAME="${VM_NAME}_${VM_ID}"
fi
log_msg "VM Name: $VM_NAME"

# RAM allocation
while true; do
    read -p "Enter the amount of RAM in MB (512-16384): " VM_RAM
    if ! [[ $VM_RAM =~ ^[0-9]+$ ]]; then
        log_msg "ERROR: Not a valid number"
        continue
    elif [[ $VM_RAM -lt 512 ]]; then
        log_msg "ERROR: Minimum 512MB required"
        continue
    elif [[ $VM_RAM -gt 16384 ]]; then
        log_msg "WARNING: More than 16GB - you have 32GB total"
        read -p "Continue anyway? (y/n): " confirm
        if [[ $confirm == "y" || $confirm == "Y" ]]; then
            break
        fi
    else
        break
    fi
done
log_msg "RAM: ${VM_RAM}MB"

# Disk space
while true; do
    read -p "Enter disk size in GB (10-500): " VM_DISK
    if ! [[ $VM_DISK =~ ^[0-9]+$ ]]; then
        log_msg "ERROR: Not a valid number"
        continue
    elif [[ $VM_DISK -lt 10 || $VM_DISK -gt 500 ]]; then
        log_msg "ERROR: Disk must be between 10GB and 500GB"
        continue
    else
        break
    fi
done
log_msg "Disk: ${VM_DISK}GB"

# vCPU allocation
while true; do
    read -p "Enter number of vCPUs (1-8): " VM_VCPU
    if ! [[ $VM_VCPU =~ ^[0-9]+$ ]]; then
        log_msg "ERROR: Not a valid number"
        continue
    elif [[ $VM_VCPU -lt 1 || $VM_VCPU -gt 8 ]]; then
        log_msg "ERROR: vCPUs must be between 1 and 8"
        continue
    else
        break
    fi
done
log_msg "vCPUs: $VM_VCPU"

# Search for ISO files
log_msg ""
log_msg "Searching for ISO files..."
ISO_FILES=($(find $ISO_DIR -name "*.iso" 2>/dev/null))

if [[ ${#ISO_FILES[@]} -eq 0 ]]; then
    log_error "No ISO files found in $ISO_DIR. Upload ISOs via web interface first."
fi

# Show available ISOs
log_msg "Available ISO files:"
for i in "${!ISO_FILES[@]}"; do
    log_msg "$((i+1)). $(basename "${ISO_FILES[i]}")"
done

# ISO selection
while true; do
    read -p "Select ISO number: " CHOICE
    if [[ $CHOICE =~ ^[0-9]+$ ]] && [[ $CHOICE -ge 1 ]] && [[ $CHOICE -le ${#ISO_FILES[@]} ]]; then
        VM_ISO="$STORAGE_ISO:iso/$(basename "${ISO_FILES[$((CHOICE-1))]}")"
        log_msg "Selected: $(basename "${ISO_FILES[$((CHOICE-1))]}")"
        break
    else
        log_msg "ERROR: Enter a number between 1 and ${#ISO_FILES[@]}"
    fi
done

# OS Type
log_msg ""
log_msg "Select OS type:"
log_msg "1. Linux (RHEL/Ubuntu/Debian)"
log_msg "2. Windows"
log_msg "3. Other"
read -p "Choice [1]: " OS_CHOICE
case $OS_CHOICE in
	1)
		OS_TYPE="l26"
		log_msg "OS Type: Linux"
		;;
    	2) 
        	OS_TYPE="win10"
        	log_msg "OS Type: Windows"
        	;;
    	3) 
        	OS_TYPE="other"
        	log_msg "OS Type: Other"
        	;;
    	*) 
        	OS_TYPE="l26"
		log_msg "OS Type: Linux (default)"
        	;;
esac

# Network selection
log_msg ""
log_msg "Network configuration:"
log_msg "1. NAT (default)"
log_msg "2. Bridge (full network access)"
read -p "Choice [1]: " NET_CHOICE
if [[ $NET_CHOICE == "2" ]]; then
    NET_MODEL="virtio,bridge=$BRIDGE"
    log_msg "Network: Bridged"
else
    NET_MODEL="virtio,bridge=$BRIDGE,firewall=1"
    log_msg "Network: NAT with firewall"
fi

# Boot options
BOOT_ORDER="order=ide2;scsi0"
if [[ $OS_TYPE == "l26" ]]; then
    BIOS_TYPE="seabios"
else
    BIOS_TYPE="ovmf"  # UEFI for Windows
fi

# Summary
log_msg ""
log_msg "===== VM Configuration Summary ====="
log_msg "VM ID:      $VM_ID"
log_msg "Name:       $VM_NAME"
log_msg "RAM:        ${VM_RAM}MB"
log_msg "Disk:       ${VM_DISK}GB"
log_msg "vCPUs:      $VM_VCPU"
log_msg "ISO:        $(basename "$VM_ISO")"
log_msg "OS Type:    $OS_TYPE"
log_msg "Storage:    $STORAGE_VM"
log_msg "Network:    $NET_MODEL"
log_msg "===================================="
log_msg ""

read -p "Create this VM? (y/n): " CONFIRM
if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    log_msg "Operation cancelled by user"
    exit 0
fi

log_msg ""
log_msg "Creating VM..."

# Create the VM
qm create $VM_ID \
    --name "$VM_NAME" \
    --memory $VM_RAM \
    --cores $VM_VCPU \
    --sockets 1 \
    --cpu host \
    --net0 $NET_MODEL \
    --ide2 "$VM_ISO,media=cdrom" \
    --ostype $OS_TYPE \
    --scsi0 "$STORAGE_VM:$VM_DISK" \
    --scsihw virtio-scsi-pci \
    --bootdisk scsi0 \
    --boot "$BOOT_ORDER" \
    --tablet 0 \
    --agent 1 2>&1 | tee -a "$LOG_FILE"

# Check if creation was successful
if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
    log_msg ""
    log_msg "✓ VM created successfully!"
    log_msg ""
    log_msg "=== Next Steps ==="
    log_msg "1. Start VM:        qm start $VM_ID"
    log_msg "2. View console:    qm console $VM_ID"
    log_msg "3. Install OS from ISO"
    log_msg ""
    log_msg "For RHEL/AlmaLinux: Install qemu-guest-agent after OS installation"
    log_msg "Command: yum install qemu-guest-agent"
    log_msg ""
    
    # Save VM info for future reference
    VM_INFO_FILE="$LOG_DIR/vm_${VM_ID}_info.txt"
    {
        echo "VM_ID=$VM_ID"
        echo "VM_NAME=$VM_NAME"
        echo "CREATED=$(date)"
        echo "RAM=${VM_RAM}MB"
        echo "DISK=${VM_DISK}GB"
        echo "VCPU=$VM_VCPU"
    } > "$VM_INFO_FILE"
    
    log_msg "VM info saved to: $VM_INFO_FILE"
else
    log_error "Failed to create VM. Check the log: $LOG_FILE"
fi

log_msg ""
log_msg "Script completed at: $(date)"
log_msg "=================================="

exit 0
