#!/bin/bash

################################################
#
# Author: Thomas "maaseh" Bonnet
# Description: Search and install kernel updates with reboot
# This script is linked to a systemd timer (weekly)
#
################################################

# Variables
LOG_DIR="/var/log/CustomLogs/weekly-updates"
LOG_FILE="$LOG_DIR/Kernel_updates.log"
REBOOT_DELAY=300  # 5 minutes

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Exit on any error
set -e

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

# Redirect all output to log file
(
    echo "=== Weekly kernel update ==="
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo ""
    
    # Update package lists
    echo "Updating package lists..."
    apt update || { echo "Failed to update package list"; exit 1; }
    echo ""
    
    # Check for kernel updates
    echo "Checking for kernel updates..."
    
    # Simple check - look for any kernel packages
    Kernel_Updates=$(apt list --upgradable 2>/dev/null | grep -E "(linux-image|pve-kernel)" | cut -d'/' -f1)
    
    if [[ -n "$Kernel_Updates" ]]; then
        echo "Kernel updates found:"
        echo "$Kernel_Updates"
        echo ""
        
        # Install updates
        echo "Installing kernel updates..."
        DEBIAN_FRONTEND=noninteractive apt install -y $Kernel_Updates
        
        echo ""
        echo "Kernel updates installed"
        
        # Check if reboot is needed
        if [ -f /var/run/reboot-required ]; then
            echo ""
            echo "REBOOT REQUIRED"
            echo "Rebooting in $REBOOT_DELAY seconds..."
            
            # Notify users
            wall "System will reboot in $REBOOT_DELAY seconds for kernel update"
            
            # Schedule reboot
            shutdown -r +5 "Kernel update reboot"
        else
            echo "No reboot required"
        fi
    else
        echo "No kernel updates available"
    fi
    
    echo ""
    echo "Script completed at: $(date)"
    echo "=================================="

) >> "$LOG_FILE" 2>&1

exit 0
