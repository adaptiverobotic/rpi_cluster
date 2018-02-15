#!/bin/bash

set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

# Creates the local .ssh directory
# if it does not already exist.
declare_variables() {

  # Directory that contains
  # files related to ssh
  readonly ssh_dir=$HOME/.ssh/

  # Create if doesn't exist
  mkdir -p $ssh_dir
}

#-------------------------------------------------------------------------------

# Generate id_rsa and id_rsa.pub
# and store it in ~/.ssh locally
generate_keys() {
  echo "Generating public and private key pair"
  echo "y" | ssh-keygen -f ${ssh_dir}id_rsa -t rsa -N '' > /dev/null
  echo "Successfully generated public and private key pair"
}

#-------------------------------------------------------------------------------

# Send the setup script
# to all the nodes. We are
# using sshpass to automate
# this before we have ssg keys
send_assets() {

  echo "Sending setup script to each node"
  $UTIL sshpass_nodes scp $(pwd)/setup.sh
  echo "Successfully sent setup script to each node"
}

#-------------------------------------------------------------------------------

# SSH into remote machines, and
# delete all keys from authorized_keys
# that are associated with this machine.
delete_keys() {
  echo "Deleting old keys"
  $UTIL sshpass_nodes ssh ./setup.sh "$hostname"
  echo "Successfully deleted old keys"
}

#-------------------------------------------------------------------------------

# Copy contents of
# id_rsa.pub into authorized_keys
# of each node
send_keys() {
  # Loop through each node
  # and delete any old authorized_keys
  # that are associate with this device
  echo "Sending public key to each node"
  $UTIL sshpass_nodes ssh-copy-id -i ${ssh_dir}id_rsa.pub
  echo "Successfully sent public key to each node"
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
}

#-------------------------------------------------------------------------------

# Calls necessary functions
# to enable passwordless ssh
# between this machine and each node
install() {
  echo "Installing ssh keys on cluster"

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

  echo "Successfully installed ssh keys on cluster"
}

#-------------------------------------------------------------------------------

main() {
  declare_variables

  "$@"
}

#-------------------------------------------------------------------------------

main "$@"
