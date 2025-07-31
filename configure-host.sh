#!/bin/bash

# Ignore termination signals
trap '' TERM HUP INT

# Initial values
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -verbose)
      VERBOSE=true
      shift
      ;;
    -name)
      DESIRED_NAME="$2"
      shift 2
      ;;
    -ip)
      DESIRED_IP="$2"
      shift 2
      ;;
    -hostentry)
      HOSTENTRY_NAME="$2"
      HOSTENTRY_IP="$3"
      shift 3
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done
if [[ -n "$DESIRED_NAME" ]]; then
  CURRENT_NAME=$(hostname)

  if [[ "$CURRENT_NAME" != "$DESIRED_NAME" ]]; then
    echo "$DESIRED_NAME" > /etc/hostname
    hostnamectl set-hostname "$DESIRED_NAME"

    # Update /etc/hosts line for 127.0.1.1
    if grep -q "^127.0.1.1" /etc/hosts; then
      sed -i "s/^127.0.1.1.*/127.0.1.1 $DESIRED_NAME/" /etc/hosts
    else
      echo "127.0.1.1 $DESIRED_NAME" >> /etc/hosts
    fi

    logger "Hostname changed from $CURRENT_NAME to $DESIRED_NAME"

    if $VERBOSE; then
      echo "Hostname updated from $CURRENT_NAME to $DESIRED_NAME"
    fi
  else
    if $VERBOSE; then
      echo "Hostname already set to $DESIRED_NAME"
    fi
  fi
fi
if [[ -n "$DESIRED_IP" ]]; then
  NETPLAN_FILE=$(find /etc/netplan -name "*.yaml" | head -n 1)
  LAN_IFACE=$(ip -o -4 addr show | awk '/192\.168\.16\./ {print $2; exit}')
  CURRENT_IP=$(ip -o -4 addr show dev "$LAN_IFACE" | awk '{print $4}' | cut -d/ -f1)

  if [[ "$CURRENT_IP" != "$DESIRED_IP" ]]; then
    # Backup the netplan config
    cp "$NETPLAN_FILE" "$NETPLAN_FILE.bak"

    # Rewrite the netplan config
    cat > "$NETPLAN_FILE" <<EOF
network:
  version: 2
  ethernets:
    $LAN_IFACE:
      dhcp4: no
      addresses: [$DESIRED_IP/24]
      gateway4: 192.168.16.2
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
EOF

    # Apply netplan changes
    netplan apply

    # Update /etc/hosts
    sed -i "/\s$(hostname)$/d" /etc/hosts
    echo "$DESIRED_IP $(hostname)" >> /etc/hosts

    logger "IP address changed from $CURRENT_IP to $DESIRED_IP on $LAN_IFACE"

    if $VERBOSE; then
      echo "IP address changed from $CURRENT_IP to $DESIRED_IP on $LAN_IFACE"
    fi
  else
    if $VERBOSE; then
      echo "IP address already set to $DESIRED_IP"
    fi
  fi
fi
if [[ -n "$HOSTENTRY_NAME" && -n "$HOSTENTRY_IP" ]]; then
  # Check if the entry already exists with correct IP
  if grep -qE "^$HOSTENTRY_IP\s+$HOSTENTRY_NAME\$" /etc/hosts; then
    if $VERBOSE; then
      echo "/etc/hosts already contains: $HOSTENTRY_IP $HOSTENTRY_NAME"
    fi
  else
    # Remove any existing lines for this hostname
    sed -i "/\s$HOSTENTRY_NAME$/d" /etc/hosts

    # Add new correct entry
    echo "$HOSTENTRY_IP $HOSTENTRY_NAME" >> /etc/hosts

    logger "/etc/hosts updated: $HOSTENTRY_NAME set to $HOSTENTRY_IP"

    if $VERBOSE; then
      echo "/etc/hosts updated: $HOSTENTRY_NAME set to $HOSTENTRY_IP"
    fi
  fi
fi
