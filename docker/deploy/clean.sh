containers() {

  while read line; do
    l=($line)

    # Stop all containers associate with image name
    docker ps -a -q --filter ancestor=${l[0]} | xargs --no-run-if-empty docker stop
  done <$1

  # Delete all stopped containers
  docker ps -q -f status=exited | xargs --no-run-if-empty docker rm
}

#-------------------------------------------------------------------------------

images() {
  while read line; do
    l=($line)

    # Delete all images associated with image name
    docker images --format '{{.Repository}}' | grep ${l[0]} | xargs --no-run-if-empty docker rmi
  done <$1

  # Delete all dangling (unused) images
  docker images -q -f dangling=true | xargs --no-run-if-empty docker rmi
}

#-------------------------------------------------------------------------------

networks() {

  while read line; do
    l=($line)
    docker network rm ${l[0]}
  done <$1

  # Delete all networks that
  # does not have at least one
  # container connected to it

  # NOTE - Temporary
  # docker network prune
}

#-------------------------------------------------------------------------------

secrets() {
  # TODO - Delete secrets
  # by name specified by file

  echo "Secrets"
}

#-------------------------------------------------------------------------------

stack() {

  # Remove a stack by name.
  # All associated services
  # will be stopped
  docker stack rm $(cat $1)
}

#-------------------------------------------------------------------------------

volumes() {
  while read line; do
    l=($line)

    # Remove volume by name
    docker volume rm ${l[0]}
  done <$1

  # Remove all unused volumes
  docker volume ls -qf dangling=true | xargs --no-run-if-empty -r docker volume rm
}

#-------------------------------------------------------------------------------

"$@"
