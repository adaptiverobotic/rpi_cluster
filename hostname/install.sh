#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

echo "Changing hostname of each node to takte the pattern: $COMMON_HOST-[provider]-xxx"

# SCP setup script to each node
$UTIL scp_nodes $(pwd)/setup.sh

# Run setup script on each node
$UTIL ssh_nodes sudo ./setup.sh $COMMON_HOST-$1
