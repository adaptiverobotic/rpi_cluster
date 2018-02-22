#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

# Globals
declare_variables() {
  :
}

#-------------------------------------------------------------------------------

# Install pi-hole
install_pihole() {
  echo "Installing pi-hole on dhcp server"
  $UTIL scp_ssh_specific_nodes $DHCP_IP_FILE $(pwd)/setup.sh ./setup.sh reinstall_pihole $COMMON_PASS
  $UTIL print_success "SUCCESS: " "Installed pi-hole on dhcp server"
}

#-------------------------------------------------------------------------------

# Remove pi-hole
uninstall_pihole() {
  echo "Uninstaling pi-hole from dhcp server"
  $UTIL scp_ssh_specific_nodes $DHCP_IP_FILE $(pwd)/setup.sh ./setup.sh uninstall_pihole
  $UTIL print_success "SUCCESS: " "Uninstalled pi-hole on dhcp server"
}

#-------------------------------------------------------------------------------

main() {
  declare_variables "$@"

  "$@"
}

#-------------------------------------------------------------------------------

main "$@"
