#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

# Global variables
declare_variables() {
  readonly provider=$2;
  readonly dependencies="$(cat $ROOT_DIR/$provider/assets/dependencies)"
}

#-------------------------------------------------------------------------------

# Send setup script
# to each node
send_assets() {
  echo "Sending dependency install script to each node"
  $UTIL scp_nodes $(pwd)/setup.sh
  echo "Successfully sent dependency install script to each node"
}

#-------------------------------------------------------------------------------

# Print dependency
# list to the console
display_dependencies() {
  local install=$1

  echo ""
  echo "The following will be ${install}ed on each node:"
  echo "------------------------------------------------"
  printf '%s\n' "${dependencies[@]}"
  echo "------------------------------------------------"
  echo ""
}

#-------------------------------------------------------------------------------

# Install dependencies
# for a given provider
# from each node
install() {
  display_dependencies "install"
  $UTIL ssh_nodes ./setup.sh install "$dependencies"
  echo "Successfully installed dependencies on each node"
}

#-------------------------------------------------------------------------------

# Uninstall dependencies
# for a given provider
# from each node
uninstall() {
  display_dependencies "uninstall"
  $UTIL ssh_nodes ./setup.sh uninstall "$dependencies"
  echo "Successfully uninstalled dependencies from each node"
}

#-------------------------------------------------------------------------------

main() {
  declare_variables "$@"

  send_assets

  "$@"
}

#-------------------------------------------------------------------------------

main "$@"
