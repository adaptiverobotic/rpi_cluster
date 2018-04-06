set -e

#-------------------------------------------------------------------------------

# Globals
declare_variables() {
  readonly user=$2; shift
  readonly pass=$2
}

#-------------------------------------------------------------------------------

# Start app
install_nextcloud() {

  echo "Installing nextcloud"
  echo "Creating volume for storage: nextcloud"
  docker volume create nextcloud

  echo "Starting service: nextcloud"
  docker service create \
  --detach \
  --name nextcloud \
  --mode replicated \
  --replicas 1 \
  --publish mode=ingress,target=80,published=80 \
  --mount type=volume,src=nextcloud,dst=/var/www/html \
  -e NEXTCLOUD_ADMIN_USER=$user \
  -e NEXTCLOUD_ADMIN_PASSWORD=$pass \
  -e SQLITE_DATABASE=nextcloud \
  nextcloud

  echo "Successfully started service: nextcloud"
}

#-------------------------------------------------------------------------------

# Deletes old instance
uninstall_nextcloud() {
  echo "Uninstalling nextcloud"

  if ! docker service rm nextcloud; then
    echo "Could not stop service nextcloud"
  fi

  if ! docker stop nextcloud; then
    echo "Could not stop nextcloud or nothing to stop"
  fi

  echo "Removing nextcloud container"
  if ! docker rm nextcloud --force; then
    echo "Coult not remove container or nothing to remove"
  fi

  echo "Removing old volume"
  if ! docker volume rm nextcloud --force; then
    echo "Could not remove volume or nothing to remove"
  fi

  # TODO - Remove associated images

  echo "Successfully uninstalled nextcloud"
}

#-------------------------------------------------------------------------------

# Removes and reinstalls
# nextcloud
reinstall_nextcloud() {
  uninstall_nextcloud
  install_nextcloud
}

#-------------------------------------------------------------------------------

main() {
  declare_variables "$@"
  "$@"
}

#-------------------------------------------------------------------------------

main "$@"
