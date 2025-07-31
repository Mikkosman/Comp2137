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
