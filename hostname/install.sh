#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

echo "Changing hostname of each node"

# SCP setup and password file script to each node
$UTIL scp_nodes $(pwd)/setup.sh

# Run setup script on each node
$UTIL ssh_nodes sudo ./setup.sh $COMMON_USER
