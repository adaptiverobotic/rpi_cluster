#!/bin/bash

set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

echo "Enabling passwordless ssh"

# Directory that contains
# files related to ssh
ssh_dir=$HOME/.ssh/

# Create if it does not
# already exist
mkdir -p $ssh_dir

echo "Generating public and private key pair"

# Generate public-private key pairs locally
echo "y" | ssh-keygen -f ${ssh_dir}id_rsa -t rsa -N ''

# Loop through each node
# and delete any old authorized_keys
# that are associate with this device
echo "Sending public key to all nodes"

# SCP setup script to node
$UTIL sshpass_nodes scp $(pwd)/setup.sh

echo "Deleting old keys"
$UTIL sshpass_nodes ssh ./setup.sh ${hostname}

# Copy the new public key to each node
echo "Sending new public keys"
while read ip;
do
  $UTIL my_sshpass $COMMON_USER@$ip ssh-copy-id -i ${ssh_dir}id_rsa.pub
done <$IPS

# Make changes official
# NOTE - idk y but this works
# when ssh from outside world
eval $(ssh-agent)
ssh-add

echo "Successfully added ssh key to each node"
