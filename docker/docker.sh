#!/bin/bash
set -e

build() {
  path=$2

  echo "Building images listed in: $1"

  while read line; do
    l=($line)
    docker build -t ${l[0]}:latest $path${l[1]}
  done <$1
}

#-------------------------------------------------------------------------------

network() {
  network_file=$1
  echo "Creating networks listed in: $network_file"

  # If the file exists
  if ls $network_file; then

    # Loop through and delete
    # each network by name
    while read line; do
      network=($line)
      docker network create -d ${network[1]} ${network[0]}
    done <$network_file

  # It did not exist
  else
    echo "No networks to remove"
  fi
}

#-------------------------------------------------------------------------------

pull() {
  image_file=$1
  echo "Pulling images listed in: $image_file"

  # If it exists
  if ls $image_file; then

    # Pull each image
    # listed in file
    while read line; do
      image=($line)
      docker pull ${image[0]}:latest
    done <$image_file

  # File not found
  else
    echo "No images to pull"
  fi
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

  while read line; do
    l=($line)

    # Echo the value and pipe that into docker create
    # secret. By convention, the name of secret is first
    # value, and the value is the second value
    echo ${l[1]} | docker secret create ${l[0]} -
  done <$1
}

#-------------------------------------------------------------------------------

service() {
  path=$2

  echo "Creating services listed in: $1"

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
  volume_file=$1
  echo "Creating volumes listed in: $volume_file"

  if ls $volume_file; then

    # Loop through file and
    # create each volume
    while read line; do
      l=($line)
      docker volume create -d ${l[1]} ${l[0]}
    done <$volume_file

  else
    echo "No volumes to create"
  fi
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
  volume_file=$1
  echo "Removing volumes listed in: $volume_file"

  if ls $volume_file; then
    while read line; do
      volume=($line)

      # TODO - Only if exists
      if docker volume rm ${volume[0]}; then
        echo "Volume: ${volume[0]} was removed"
      else
        echo "Volume: ${volume[0]} was not removed or failed"
      fi
    done <$volume_file
  else
    echo "No volumes to remove"
  fi

  # Remove all unused volumes
  docker volume ls -qf dangling=true | xargs --no-run-if-empty -r docker volume rm
}

#-------------------------------------------------------------------------------

clean_networks() {
  network_file=$1

  echo "Removing networks listed in: $network_file"

  # IF the file exists
  if ls $network_file; then

    # Loop through networks
    while read line; do
      network=($line)

      # TODO - Only if exists
      if docker network rm $network; then
        echo "Network: $network was removed"
      else
        echo "Network $network was did not exist or failed"
      fi
    done <$network_file

  # Otherwise something went wrong
  else
    echo "No networks to remove"
  fi

  # Delete all networks that
  # do not have at least one
  # container connected to it

  # NOTE - Temporary
  # docker network prune
}

#-------------------------------------------------------------------------------

clean_secrets() {
  echo "Removing secrets listed in: $1"

  #Delete secrets
  # by name specified by file
  while read line; do
    l=($line)

    # Echo the value and pipe that into docker create
    # secret. By convention, the name of secret is first
    # value, and the value is the second value
    if docker secret rm ${l[0]}; then
      echo "Secret: ${l[0]} removed"
    else
      echo "Secret: ${l[0]} could not be removed, or does not exists"
    fi
  done <$1
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

    # Clean containers associated with image names
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
