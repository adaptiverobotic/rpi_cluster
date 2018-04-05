#!/bin/bash
set -e

# NOTE - Maybe we should not use set -e
# here. We need to make sure port 22 is open
# even if we fail. Otherwise we are locking
# ourselves out!

# Enable UFW firewall software
echo "y" | sudo ufw reset
echo "y" | sudo ufw enable

# TODO - Verify that port 22 is on the list

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

# TODO - Verify that port 22 is open,
# otherwise rever all changes to default
