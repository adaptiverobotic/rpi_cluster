set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

# Globals
declare_variables() {
  readonly compose_file="$(pwd)/assets/nextcloud-docker-compose.yml"
}

#-------------------------------------------------------------------------------

# Send the docker-compose.yml
# file over and start the services
install_nextcloud() {
  echo "Installing nextcloud"

  # Send the script, run it
  $UTIL scp_ssh_specific_nodes \
        $NAS_IP_FILE $(pwd)/setup.sh \
        ./setup.sh reinstall_nextcloud \
        $COMMON_USER $COMMON_PASS

  $UTIL print_success "SUCCESS: " "Installed nextcloud"
}

#-------------------------------------------------------------------------------

uninstall_nextcloud() {
  echo "Uninstalling nextcloud"

  # Send the script, run it
  $UTIL scp_ssh_specific_nodes \
        $NAS_IP_FILE $(pwd)/setup.sh \
        ./setup.sh uninstall_nextcloud

  $UTIL print_success "SUCCESS: " "Uninstalled nextcloud"
}

#-------------------------------------------------------------------------------

main() {
  declare_variables

  "$@"
}

#-------------------------------------------------------------------------------

main "$@"
