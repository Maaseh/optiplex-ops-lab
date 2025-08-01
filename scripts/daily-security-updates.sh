#!/bin/bash

################################################
#
# Author: Thomas "maaseh" Bonnet
# Description: Search and install security updates
# This script is linked to a service
#
################################################


#Variable

LOG_FILE="/var/log/CustomLogs/daily-updates/Security_updates.log"
if [ ! -f $LOG_FILE ]; then
	touch $LOG_FILE
fi

set -euo pipefail

(
echo "=== Daily security update ==="
echo $(date)
echo ""

Security_Update=($(apt --just-print upgrade | grep -i security | awk '{print $2}' | awk '!seen[$0]++'))
Number_Update=$(echo ${#Security_Update[@]})
if [ $Number_Update -ge 1 ]; then
	apt update || { echo "Failed to update package list"; exit 1; }
	for i in ${Security_Update[@]}; do
		apt install --only-upgrade -y "$i" || echo "Failed to install $1"
	done
	echo "$Number_Update have been installed"
	exit 0
else
	echo "No security update today"
	exit 1
fi
) 2>&1 >> $LOG_FILE
