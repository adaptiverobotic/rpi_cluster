#!/bin/bash
set -e

build() {
  path=$2

  echo "Building images listed in: $1"
  echo "$(cat $1)"

  while read line; do
    l=($line)
    docker build -t ${l[0]}:latest $path${l[1]}
  done <$1
}

#-------------------------------------------------------------------------------

network() {
  echo "Creating networks listed in: $1"
  echo "$(cat $1)"

  while read line; do
    l=($line)
    docker network create -d ${l[1]} ${l[0]}
  done <$1
}

#-------------------------------------------------------------------------------

pull() {
  echo "Pulling images listed in: $1"
  echo "$(cat $1)"

  while read line; do
    l=($line)
    docker pull ${l[0]}:latest
  done <$1
}

#-------------------------------------------------------------------------------

push() {
  echo "Pushing to docker hub images listed in: $1"
  echo "$(cat $1)"

  while read line; do
    l=($line)
    docker push ${l[0]}:latest
  done <$1
}

#-------------------------------------------------------------------------------

secret() {
  echo "Creating docker secrets listed in: $1"
  echo "$(cat $1)"

  while read line; do
    l=($line)
    echo $line
  done <$1
}

#-------------------------------------------------------------------------------

service() {
  path=$2

  echo "Creating services listed in: $1"
  echo "$(cat $1)"

  while read line; do

    echo "Starting docker service from $path"

    # Execute docker_service.sh in
    # each directory that is read from file

    # Run this in the background because some
    # docker task startups will hang, die, and
    # restart depending on the restart policy
    # of the service. We do not want this to
    # block the terminal.

    # TODO - Send to background
    /bin/bash ${path}${line}/docker_service.sh &>/dev/null &
  done <$1
}

#-------------------------------------------------------------------------------

volume() {
  echo "Creating volumes listed in: $1"
  echo "$(cat $1)"

  while read line; do
    l=($line)
    docker volume create -d ${l[1]} ${l[0]}
  done <$1
}

#-------------------------------------------------------------------------------

setup_app() {
  path=$1

  echo "Setting up volumes and secrets"

  # Initialize docker volumes
  volume ${path}assets/volumes

  # Ensures that all secrets are created
  secret ${path}assets/secrets
}
#-------------------------------------------------------------------------------

clean_containers() {
  echo "Removing containers associated with images listed in: $1"
  echo "$(cat $1)"

  while read line; do
    l=($line)

    # Stop all containers associate with image name
    docker ps -a -q --filter ancestor=${l[0]} | xargs --no-run-if-empty docker stop
  done <$1

  # Delete all stopped containers
  docker ps -q -f status=exited | xargs --no-run-if-empty docker rm
}

#-------------------------------------------------------------------------------

clean_images() {
  echo "Removing images listed in: $1"
  echo "$(cat $1)"

  # NOTE - Do we also want to
  # delete images that our images
  # depend on? Example, if database
  # depends on postgres, should we
  # also delete these? This may drastically
  # slow down deployment speed if we
  # do this every time. Perharps set a flag

  while read line; do
    l=($line)

    # Delete all images associated with image name
    docker images --format '{{.Repository}}' | grep ${l[0]} | xargs --no-run-if-empty docker rmi
  done <$1

  # Delete all dangling (unused) images
  docker images -q -f dangling=true | xargs --no-run-if-empty docker rmi
}

#-------------------------------------------------------------------------------

clean_volumes() {
  echo "Removing volumes listed in: $1"
  echo "$(cat $1)"

  while read line; do
    l=($line)

    # Remove volume by name
    # TODO - Only if exists
    if docker volume rm ${l[0]}; then
      echo "Volume: ${l[0]} was removed"
    else
      echo "Volume: ${l[0]} was not removed or failed"
    fi
  done <$1

  # Remove all unused volumes
  docker volume ls -qf dangling=true | xargs --no-run-if-empty -r docker volume rm
}

#-------------------------------------------------------------------------------

clean_networks() {
  echo "Removing networks listed in: $1"
  echo "$(cat $1)"

  while read line; do
    l=($line)

    # TODO - Only if exists
    if docker network rm ${l[0]}; then
      echo "Network: ${l[0]} was removed"
    else
      echo "Network ${l[0]} was did not exist or failed"
    fi
  done <$1

  # Delete all networks that
  # does not have at least one
  # container connected to it

  # NOTE - Temporary
  # docker network prune
}

#-------------------------------------------------------------------------------

clean_secrets() {
  echo "Removing secrets listed in: $1"
  echo "$(cat $1)"

  # TODO - Delete secrets
  # by name specified by file

  echo "Secrets"
}

#-------------------------------------------------------------------------------

clean_services() {
  echo "Removing services listed in: $1"
  echo "$(cat $1)"

  # TODO - Implement
}

#-------------------------------------------------------------------------------

clean_stacks() {
  echo "Removing stacks listed in: $1"
  echo "$(cat $1)"

  # TODO - not yet implemented

  # Remove a stack by name.
  # All associated services
  # will be stopped

  # TODO - Only if exists
  # docker stack rm $(cat $1)
}

#-------------------------------------------------------------------------------

cleanup() {
  clean_file=$1
  path=$2

  echo "Cleaning up old volumes, images, containers, etc."

  while read line; do
    l=($line)

    # Clean containers associated with
    # image names

    # TODO - they say there is a syntax error
    if [[ $line == "containers" ]]; then
      clean_containers ${path}assets/images

    # Otherwise just match the string
    # so clean_networks, clean_stacks, etc.
    else
      clean_$line ${path}assets/$line

    fi
  done <$clean_file
}

#-------------------------------------------------------------------------------

"$@"
