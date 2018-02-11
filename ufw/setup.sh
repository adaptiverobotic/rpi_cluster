#!/bin/bash
set -e

# Enable UFW firewall software
echo "y" | sudo ufw reset
echo "y" | sudo ufw enable

# Open all ports
for port in $@
do
  echo "Opening port: $port"
  echo "y" | sudo ufw allow $port

  # If something went wrong
  if [[ $? -ne 0 ]]; then
    echo "Something went wrong, disabling ufw"
    echo "y" |  sudo ufw disable
    break
  fi
done
