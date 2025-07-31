#!/bin/bash

# Enable verbose mode if passed
VERBOSE_FLAG=""
if [[ "$1" == "-verbose" ]]; then
  VERBOSE_FLAG="-verbose"
fi

# Define variables
CONFIG_SCRIPT="./configure-host.sh"

# Exit if configure-host.sh is missing
if [[ ! -f "$CONFIG_SCRIPT" ]]; then
  echo "Error: $CONFIG_SCRIPT not found."
  exit 1
fi

echo "Copying script to server1..."
scp "$CONFIG_SCRIPT" remoteadmin@server1-mgmt:/root/

echo "Running script on server1..."
ssh remoteadmin@server1-mgmt -- "/root/configure-host.sh -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4 $VERBOSE_FLAG"

echo "Copying script to server2..."
scp "$CONFIG_SCRIPT" remoteadmin@server2-mgmt:/root/

echo "Running script on server2..."
ssh remoteadmin@server2-mgmt -- "/root/configure-host.sh -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3 $VERBOSE_FLAG"

echo "Updating /etc/hosts on host VM..."
sudo ./configure-host.sh -hostentry loghost 192.168.16.3 $VERBOSE_FLAG
sudo ./configure-host.sh -hostentry webhost 192.168.16.4 $VERBOSE_FLAG

echo "Configuration completed successfully."
