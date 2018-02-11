#!/bin/bash
set -e

hostname=$1

# Encompass this in if so we don't error out if the
# file dos not exist. This is only pertinent to new installs
if "sed -i "/${hostname}/d" ~/.ssh/authorized_keys"; then
  echo "Hostname: $hostname removed"
else
  echo "Hostname: $hostname was not in authorized keys or the file doesn't exist"
fi
