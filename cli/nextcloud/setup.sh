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
  docker stop nextcloud

  echo "Removing nextcloud container"
  docker rm nextcloud

  echo "Removing old volume"
  docker volume rm nextcloud
}

#-------------------------------------------------------------------------------

main() {
  declare_variables "$@"
  remove_nextcloud
  start_nextcloud
}

main "$@"
