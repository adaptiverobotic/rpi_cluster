#!/bin/bash

set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

# Creates the local .ssh directory
# if it does not already exist.
declare_variables() {
  readonly ssh_dir=$HOME/.ssh
  mkdir -p $ssh_dir
}

#-------------------------------------------------------------------------------

# Generate id_rsa and id_rsa.pub
# and store it in ~/.ssh locally
generate_keys() {
  echo "Generating public and private key pair"
  echo "y" | ssh-keygen -f $ssh_dir/id_rsa -t rsa -N ''
  echo "Successfully generated public and private key pair"
}

#-------------------------------------------------------------------------------

# Send the setup script
# to all the nodes. We are
# using sshpass to automate
# this before we have ssg keys
send_assets() {
  echo "Sending setup script to each node"
  $UTIL sshpass_specific_nodes $ALL_IPS scp $(pwd)/setup.sh
  echo "Successfully sent setup script to each node"
}

#-------------------------------------------------------------------------------

# SSH into remote machines, and
# delete all keys from authorized_keys
# that are associated with this machine.
delete_keys() {
  echo "Deleting old keys"
  $UTIL sshpass_specific_nodes $ALL_IPS ssh ./setup.sh
  echo "Successfully deleted old keys"
}

#-------------------------------------------------------------------------------

# Copy contents of
# id_rsa.pub into authorized_keys
# of each node
send_keys() {
  echo "Sending public key to each node"
  $UTIL sshpass_specific_nodes $ALL_IPS ssh-copy-id -i $ssh_dir/id_rsa.pub
  echo "Successfully sent public key to each node"
}

#-------------------------------------------------------------------------------

# Disables password login
# over ssh. NOTE - ONLY CALL
# THIS AFTER WE HAVE VERIFIED THAT
# SSH KEYS HAVE BEEN PROPERLY
# ADMINISTERED. OTHERWISE WE
# WILL BE LOCKED OUT OF OUR CLUSTER
disable_password_login() {
  echo "Disabling password login on each node"
  # $UTIL sshpass_nodes ./setup.sh disable_password_login
  echo "Successfully disabled password login on each node"
}

#-------------------------------------------------------------------------------

# For whatever reason,
# I have to run this.
# TODO - Figure out why
finalize() {
  # Make changes official
  # NOTE - idk y but this works
  # when ssh from outside world
  # eval $(ssh-agent)
  ssh-add
}

#-------------------------------------------------------------------------------

# NOTE - Main purposely does not
# accept parameters. Every
# time you call this script
# everybody gets a new key.
# no other option. For the time
# being, this is the simplest
# solution that works for the
# scope of this project.
main() {
  echo "Installing ssh keys on cluster"
  declare_variables
  generate_keys
  send_assets
  delete_keys
  send_keys
  disable_password_login
  finalize
  echo "Successfully installed ssh keys on cluster"
}

#-------------------------------------------------------------------------------

main
