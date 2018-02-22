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
  echo "Starting nextcloud"

  $UTIL scp_ssh_specific_nodes $NAS_IP_FILE $(pwd)/setup.sh ./setup.sh $COMMON_USER $COMMON_PASS
  $UTIL print_success "SUCCESS: " "Installed nextcloud"
}

#-------------------------------------------------------------------------------

main() {
  declare_variables

  "$@"
}

#-------------------------------------------------------------------------------

main "$@"
