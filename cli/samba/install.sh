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

# samba.sh. setup.sh
send_assets() {
  echo "Sending samba setup script to each NAS server"
  $UTIL scp_specific_nodes $NAS_IP_FILE $(pwd)/samba.sh $(pwd)/setup.sh
  $UTIL print_success "SUCCESS: " "Sent setup scripts to NAS servers"
}

#-------------------------------------------------------------------------------

# Installs samba
install_samba() {
  echo "Installing samba"
  $UTIL ssh_specific_nodes $NAS_IP_FILE sudo ./setup.sh reinstall_samba $COMMON_USER $COMMON_PASS
  $UTIL print_success "SUCCESS: " "Installed samba"
}

#-------------------------------------------------------------------------------

# Uninstalls samba
uninstall_samba() {
  echo "Uninstalling samba"
  $UTIL ssh_specific_nodes $NAS_IP_FILE sudo ./setup.sh uninstall_samba
  $UTIL print_success "SUCCESS: " "Uninstalled samba"
}

#-------------------------------------------------------------------------------

# Uninstalls and
# reinstalls samba
reinstall_samba() {
  echo "reinstalling samba"
  $UTIL ssh_specific_nodes $NAS_IP_FILE sudo ./setup.sh reinstall_samba $COMMON_USER $COMMON_PASS
  $UTIL print_success "SUCCESS: " "Reinstalled samba"
}

#-------------------------------------------------------------------------------

main() {
  declare_variables
  send_assets
  "$@"
}

#-------------------------------------------------------------------------------

main "$@"
