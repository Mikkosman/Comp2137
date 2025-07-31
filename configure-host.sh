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
