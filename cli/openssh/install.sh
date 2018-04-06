#!/bin/bash
set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

declare_variables() {
  readonly ssh_port=2222
  readonly leader_ip_file="$TEMP_DIR/openssh_leader"

  # Create temporary openssh leader file
  # and write first ip in ssh ips file out to it
  # This was, we can deploy openssh as a service
  # in the future without changingg much code
  local leader_ip=$(head -n 1 $SSH_IP_FILE)
  echo $leader_ip > $leader_ip_file
}

#-------------------------------------------------------------------------------

send_assets() {
  echo "Sending setup script to SSH server leader: $leader_ip"
  $UTIL scp_specific_nodes $leader_ip_file $( pwd )/setup.sh
  $UTIL print_success "SUCCESS: " "Sent setup scripts to SSH server"
}

#-------------------------------------------------------------------------------

install_openssh() {
  echo "Installing Open SSH on $leader_ip"
  $UTIL ssh_specific_nodes $leader_ip_file ./setup.sh install_openssh $ssh_port $COMMON_USER $COMMON_PASS
  $UTIL print_success "SUCCESS: " "Installed Open SSH"
}

#-------------------------------------------------------------------------------

uninstall_openssh() {
  echo "Uninstlling Open SSH from $leader_ip"
  $UTIL ssh_specific_nodes $leader_ip_file ./setup.sh uninstall_openssh
  $UTIL print_success "SUCCESS: " "Uninstalled Open SSH"
}

#-------------------------------------------------------------------------------

main() {
  declare_variables "$@"
  send_assets

  "$@"
}

#-------------------------------------------------------------------------------

main "$@"
