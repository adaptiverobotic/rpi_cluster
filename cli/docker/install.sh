#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

# Initialize global variables
# that will be reused throughout
# this script.
declare_variables() {
  :
}

#-------------------------------------------------------------------------------

# Installs latest version of
# docker on each nodes
install_docker() {
  echo "Installing docker on each node"
  $UTIL scp_ssh_specific_nodes $ALL_IPS_FILE $(pwd)/setup.sh ./setup.sh reinstall_docker
  echo "Successfully installed docker on each node"
}

#-------------------------------------------------------------------------------

# Uninstalled docker
# from each node
uninstall_docker() {
  echo "Uninstalling docker from each node"
  $UTIL scp_ssh_nodes $(pwd)/setup.sh ./setup.sh uninstall_docker
  echo "Succesfully uninstalled docker from each node"
}

#-------------------------------------------------------------------------------

# Kick off the script.
main() {
  declare_variables
  "$@"
}

#-------------------------------------------------------------------------------

main "$@"
