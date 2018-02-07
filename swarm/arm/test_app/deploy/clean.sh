containers() {
  while read line; do
    l=($line)
    docker rm $(docker stop $(docker ps -a -q --filter ancestor=${l[0]} --format="{{.ID}}"))
  done <$1
}

#-------------------------------------------------------------------------------

images() {
  while read line; do
    l=($line)
    docker rmi $(docker images --format '{{.Repository}}' | grep ${l[0]})
  done <$1
}

#-------------------------------------------------------------------------------

networks() {
  while read line; do
    l=($line)
    docker network rm ${l[0]}
  done <$1
}

#-------------------------------------------------------------------------------

secrets() {
  while read line; do
    l=($line)
    docker volume rm ${l[0]}
  done <$1
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
