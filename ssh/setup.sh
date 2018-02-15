#!/bin/bash
set -e

readonly hostname=$1

# Encompass this in if so we don't error out if the
# file dos not exist. This is only pertinent to new installs
echo "Removing all keys associated with $hostname from authorized_keys"

# Replace old keys associated with sysadmin machine with empty string
if "sed -i "/${hostname}/d" ~/.ssh/authorized_keys" > /dev/null; then
  echo "Hostname: $hostname removed"
else
  echo "Hostname: $hostname was not in authorized keys or the file doesn't exist"
fi
