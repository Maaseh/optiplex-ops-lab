#!/bin/bash

################################################
#
# Author: Thomas "maaseh" Bonnet
# Description: Search and install kernel updates
# This script is linked to a service
#
################################################


#Variable

LOG_FILE="/var/log/CustomLogs/weekly-updates/Kernel_Updates.log"
if [ ! -f $LOG_FILE ]; then
	touch $LOG_FILE
fi

set -euo pipefail

(
echo "=== Daily security update ==="
echo $(date)
echo ""

Kernel_Update=($(apt --just-print upgrade | grep -i kernel | awk '{print $2}' | awk '!seen[$0]++'))
Number_Update=$(echo ${#Kernel_Update[@]})
if [ $Number_Update -ge 1 ]; then
	apt update || { echo "Failed to update package list"; exit 1; }
	for i in ${Kernel_Update[@]}; do
		apt install --only-upgrade -y "$i" || echo "Failed to install $1"
	done
	echo "$Number_Update have been installed"
	if needrestart -r >/dev/null 2>&1; then
		echo "Restart needed. Restarting...."
		shutdown -r +1
	else
		echo "No restart needed"
		exit 0
	fi
else
	echo "No kernel update today"
	exit 1
fi
) 2>&1 >> $LOG_FILE
