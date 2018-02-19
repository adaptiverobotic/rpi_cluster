set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

declare_variables() {
  readonly compose_file="$(pwd)/assets/nextcloud-docker-compose.yml"
}

#-------------------------------------------------------------------------------

# Send the docker-compose.yml
# file over and start the services
start_nextcloud() {
  echo "Starting nextcloud"
  # $UTIL scp_ssh_specific_nodes $NAS \
  #       $compose_file \
  #       docker-compose -f nextcloud-docker-compose.yml \
  #       up

  $UTIL scp_ssh_specific_nodes $NAS \
        $(pwd)/setup.sh \
        ./setup.sh $COMMON_USER $COMMON_PASS

  echo "Successully started nextcloud"
}

#-------------------------------------------------------------------------------

main() {
  declare_variables "$@"

  "$@"
}

main "$@"
