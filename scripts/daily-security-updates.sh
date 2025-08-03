#!/bin/bash
################################################
#
# Author: Thomas "maaseh" Bonnet
# Description: Search and install security updates
# This script is linked to a systemd service (daily)
#
################################################

# Variables
LOG_DIR="/var/log/CustomLogs/daily-updates"
LOG_FILE="$LOG_DIR/Security_updates.log"

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
    echo "=== Daily security update ==="
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo ""
    
    # Update package lists
    echo "Updating package lists..."
    apt update || { echo "Failed to update package list"; exit 1; }
    echo ""
    
    # Check for security updates
    echo "Checking for security updates..."
    
    # Get security updates from security repositories
    Security_Updates=$(apt list --upgradable 2>/dev/null | grep -E "security|Security" | cut -d'/' -f1)
    
    if [[ -n "$Security_Updates" ]]; then
        echo "Security updates found:"
        echo "$Security_Updates"
        echo ""
        
        # Count updates
        Number_Updates=$(echo "$Security_Updates" | wc -l)
        echo "Total security updates: $Number_Updates"
        echo ""
        
        # Install security updates
        echo "Installing security updates..."
        DEBIAN_FRONTEND=noninteractive apt install -y $Security_Updates
        
        echo ""
        echo "Security updates installation completed"
        
        # Check if reboot is needed (for kernel security updates)
        if [ -f /var/run/reboot-required ]; then
            echo ""
            echo "WARNING: Reboot required!"
            echo "Some security updates require a system reboot."
            # On ne reboot PAS automatiquement pour les daily updates
        fi
        
    else
        echo "No security updates available today"
    fi
    
    echo ""
    echo "Script completed at: $(date)"
    echo "=================================="

) >> "$LOG_FILE" 2>&1

exit 0
