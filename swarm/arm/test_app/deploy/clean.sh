containers() {

  while read line; do
    l=($line)

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
  docker network prune

  while read line; do
    l=($line)
    docker network rm ${l[0]}
  done <$1
}

#-------------------------------------------------------------------------------

secrets() {
  echo "Secrets"
}

#-------------------------------------------------------------------------------

stack() {
  docker stack rm $(cat $1)
}

#-------------------------------------------------------------------------------

volumes() {
  while read line; do
    l=($line)
    docker volume rm ${l[0]}
  done <$1

  docker volume ls -qf dangling=true | xargs --no-run-if-empty -r docker volume rm
}

#-------------------------------------------------------------------------------

switch() {
  if [[ $1 == "stack" ]]; then
    stack assets/stack

  elif [[ $1 == "secrets" ]]; then
    secrets assets/secrets

  elif [[ $1 == "networks" ]]; then
    networks assets/networks

  elif [[ $1 == "volumes" ]]; then
    volumes assets/volumes

  elif [[ $1 == "containers" ]]; then
    containers assets/images

  elif [[ $1 == "images" ]]; then
    images assets/images
  fi
}

#-------------------------------------------------------------------------------

while read line; do
  switch $line
done <$1
