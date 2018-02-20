set -e

#-------------------------------------------------------------------------------

# Globals
declare_variables() {
  readonly db_name="nextcloud"
  readonly user=$1; shift
  readonly pass=$1
}

#-------------------------------------------------------------------------------

# Start app
start_nextcloud() {
  echo "Creating volume for storage: nextcloud"
  docker volume create nextcloud

  echo "Starting container: nextcloud"
  docker run -d \
  -p 80:80 \
  --restart=always \
  --name nextcloud \
  -v nextcloud:/var/www/html \
  -e NEXTCLOUD_ADMIN_USER=$user \
  -e NEXTCLOUD_ADMIN_PASSWORD=$pass \
  -e SQLITE_DATABASE=nextcloud \
  nextcloud
}

#-------------------------------------------------------------------------------

# Deletes old instance
remove_nextcloud() {
  echo "Stopping nextcloud"
  if ! docker stop nextcloud; then
    echo "Could not stop nextcloud or nothing to stop"
  fi

  echo "Removing nextcloud container"
  if ! docker rm --force nextcloud; then
    echo "Coult not remove container or nothing to remove"
  fi

  echo "Removing old volume"
  if ! docker volume rm --force nextcloud; then
    echo "Could not remove volume or nothing to remove"
  fi
}

#-------------------------------------------------------------------------------

main() {
  declare_variables "$@"
  remove_nextcloud
  start_nextcloud
}

main "$@"
