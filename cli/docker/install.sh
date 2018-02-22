#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

# Initialize global variables
# that will be reused throughout
# this script.
declare_variables() {
  readonly setup_script="$(pwd)/setup.sh"
}

#-------------------------------------------------------------------------------

# Install docker
# on each nodes
install_docker() {
  echo "Installing docker on each node"
  $UTIL scp_ssh_specific_nodes $ALL_IPS_FILE $setup_script ./setup.sh install_docker
  echo "Successfully installed docker on each node"
}

#-------------------------------------------------------------------------------

# Uninstall docker
# from each node
uninstall_docker() {
  echo "Uninstalling docker from each node"
  $UTIL scp_ssh_specific_nodes $ALL_IPS_FILE $setup_script ./setup.sh uninstall_docker
  echo "Succesfully uninstalled docker from each node"
}

#-------------------------------------------------------------------------------

# Reinstall docker
# on each node
reinstall_docker() {
  echo "Reinstalling docker on each node"
  $UTIL scp_ssh_specific_nodes $ALL_IPS_FILE $setup_script ./setup.sh reinstall_docker
  echo "Succesfully reinstalled docker from each node"
}

#-------------------------------------------------------------------------------

# Kick off the script.
main() {
  declare_variables
  "$@"
}

#-------------------------------------------------------------------------------

main "$@"
