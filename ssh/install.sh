#!/bin/bash

set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

# Creates the local .ssh directory
# if it does not already exist.
setup_local() {
  echo "Enabling passwordless ssh"

  # Directory that contains
  # files related to ssh
  ssh_dir=$HOME/.ssh/

  # Create if it does not
  # already exist
  mkdir -p $ssh_dir
}

#-------------------------------------------------------------------------------

# Generate id_rsa and id_rsa.pub
# and store it in ~/.ssh locally
generate_keys() {
  echo "Generating public and private key pair"

  # Generate public-private key pairs locally
  echo "y" | ssh-keygen -f ${ssh_dir}id_rsa -t rsa -N ''
}

#-------------------------------------------------------------------------------

# Send the setup script
# to all the nodes. We are
# using sshpass to automate
# this before we have ssg keys
send_assets() {
  # SCP setup script to node
  $UTIL sshpass_nodes scp $(pwd)/setup.sh
}

#-------------------------------------------------------------------------------

# SSH into remote machines, and
# delete all keys from authorized_keys
# that are associated with this machine.
delete_keys() {
  echo "Deleting old keys"
  $UTIL sshpass_nodes ssh ./setup.sh ${hostname}
}

#-------------------------------------------------------------------------------

# Copy contents of
# id_rsa.pub into authorized_keys
# of each node
send_keys() {
  # Loop through each node
  # and delete any old authorized_keys
  # that are associate with this device
  echo "Sending public key to all nodes"

  # Copy the new public key to each node
  echo "Sending new public keys"
  while read ip;
  do
    $UTIL my_sshpass $COMMON_USER@$ip ssh-copy-id -i ${ssh_dir}id_rsa.pub
  done <$IPS
}

#-------------------------------------------------------------------------------

# For whatever reason,
# I have to run this.
# TODO - Figure out why
finalize() {
  # Make changes official
  # NOTE - idk y but this works
  # when ssh from outside world
  eval $(ssh-agent)
  ssh-add

  echo "Successfully added ssh key to each node"
}

#-------------------------------------------------------------------------------

# Calls necessary functions
# to enable passwordless ssh
# between this machine and each node
install() {
  # Create .sshdir
  setup_local

  # Create key pair
  generate_keys

  # Setup script
  send_assets

  # Delete old keys
  delete_keys

  # Send new keys
  send_keys

  # IDK
  finalize
}

"$@"
