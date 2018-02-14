#!/bin/bash
set -e

#-------------------------------------------------------------------------------

build() {
  local build_file=$1

  # Path to app folder. This
  # should directly contain
  # the Dockerfile
  local path=$2

  echo "Building images listed in: $build_file"

  # If the image file exists
  if [[ -f  "$build_file" ]]; then

    # Loop through list and
    # build each image
    while read line; do
      image=($line)
      docker build -t ${image[0]}:latest $path${image[1]}
    done <$build_file

  # File not found
  else
    echo "No images to build"
  fi
}

#-------------------------------------------------------------------------------

network() {
  local network_file=$1
  echo "Creating networks listed in: $network_file"

  # If the network file exists
  if [[ -f "$network_file"  ]]; then

    # Loop through and delete
    # each network by name
    while read line; do
      network=($line)
      docker network create -d ${network[1]} ${network[0]}
    done <$network_file

  # It did not exist
  else
    echo "No networks to create"
  fi
}

#-------------------------------------------------------------------------------

pull() {
  local image_file=$1
  echo "Pulling images listed in: $image_file"

  # If it exists
  if [[ -f "$image_file" ]]; then

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
  local push_file=$1
  echo "Pushing to docker hub images listed in: $push_file"

  # If the file exists
  if [[ -f "$push_file" ]]; then

    # Loop through, and push
    # all images to docker registry
    while read line; do
      image=($line)
      docker push ${image[0]}:latest
    done <$push_file

  # File not found
  else
    echo "No images to push"
  fi
}

#-------------------------------------------------------------------------------

secret() {
  local secret_file=$1
  echo "Creating docker secrets listed in: $secret_file"

  if [[ -f "$secret_file" ]]; then
    while read line; do
      secret=($line)

      # Echo the value and pipe that into docker create
      # secret. By convention, the name of secret is first
      # value, and the value is the second value
      echo ${secret[1]} | docker secret create ${secret[0]} -
    done <$secret_file

  # File not found
  else
    echo "No secrets to create"
  fi
}

#-------------------------------------------------------------------------------

service() {
  # NOTE - Unused at the moment

  local service_file=$1
  local path=$2

  echo "Creating services listed in: $service_file"

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
  local volume_file=$1
  echo "Creating volumes listed in: $volume_file"

  # File found
  if [[ -f "$volume_file" ]]; then

    # Loop through file and
    # create each volume
    while read line; do
      l=($line)

      # Support for different drivers
      # docker volume create -d ${l[1]} ${l[0]}
      docker volume create ${l[0]}
    done <$volume_file

  # File not found
  else
    echo "No volumes to create"
  fi
}

#-------------------------------------------------------------------------------

clean_containers() {
  local image_file=$1
  echo "Removing containers associated with images listed in: $image_file"

  # File found
  if [[ -f "$image_file" ]]; then

    # Loop through list of images
    # and  stop all containers associated
    # with that image
    while read line; do
      image=($line)

      # Stop all containers associate with image name
      docker ps -a -q --filter ancestor=${image[0]} | xargs --no-run-if-empty docker stop
    done <$image_file

  # File not found
  else
    echo "No list of associated images to clean containers from"
  fi

  docker container prune -f

  # Delete all stopped containers. This includes containers stop in
  # the previous loop, and other dangling containers.
  docker ps -q -f status=exited | xargs --no-run-if-empty docker rm
}

#-------------------------------------------------------------------------------

clean_images() {
  local image_file=$1

  echo "Removing images listed in: $image_file"

  # File found
  if [[ -f "$image_file" ]]; then
    # NOTE - Do we also want to
    # delete images that our images
    # depend on? Example, if database
    # depends on postgres, should we
    # also delete these? This may drastically
    # slow down deployment speed if we
    # do this every time. Perharps set a flag

    while read line; do
      image=($line)

      # Delete all images associated with image name
      docker images --format '{{.Repository}}' | grep ${image[0]} | xargs --no-run-if-empty docker rmi
    done <$image_file

  # File not found
  else
    echo "No images to remove"
  fi

  docker image prune -a -f

  # Delete all dangling (unused) images
  docker images -q -f dangling=true | xargs --no-run-if-empty docker rmi
}

#-------------------------------------------------------------------------------

clean_volumes() {
  local volume_file=$1
  echo "Removing volumes listed in: $volume_file"

  if [[ -f "$volume_file" ]]; then
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
  local network_file=$1

  echo "Removing networks listed in: $network_file"

  # IF the file exists
  if [[ -f "$network_file" ]]; then

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
}

#-------------------------------------------------------------------------------

clean_secrets() {
  local secret_file=$1
  echo "Removing secrets listed in: $secret_file"

  # File found
  if [[ -f "$secret_file" ]]; then
    # Delete secrets
    # by name specified by file
    while read line; do
      secret=($line)

      if docker secret rm ${secret[0]}; then
        echo "Secret: ${secret[0]} removed"
      else
        echo "Secret: ${secret[0]} could not be removed, or does not exists"
      fi
    done <$secret_file

  # File not found
  else
    echo "No secrets to remove"
  fi
}

#-------------------------------------------------------------------------------

clean_services() {
  local service_file=$1

  echo "Removing services listed in: $service_file"

  if [[ -f "$service_file" ]]; then
    cat "$service_file"

    #Delete secrets
    # by name specified by file
    while read line; do
      service=($line)

      if docker service rm ${service[0]}; then
        echo "Service: ${service[0]} removed"
      else
        echo "Service: ${service[0]} could not be removed, or does not exists"
      fi
    done <$service_file
  else
    echo "No services to remove"
  fi
}

#-------------------------------------------------------------------------------

clean_stacks() {
  local stack_file=$1
  echo "Removing stacks listed in: $stack_file"

  # TODO - not yet implemented

  # Remove a stack by name.
  # All associated services
  # will be stopped
}

#-------------------------------------------------------------------------------

cleanup() {
  local clean_file=$1
  local path=$2

  echo "Cleaning up old volumes, images, containers specified in $clean_file"

  # File found
  if [[ -f "$clean_file" ]]; then
    # Loop through cleanup file
    # matching each line with the
    # respective function. Example,
    # if a line says images, we will
    # execute clean_images()
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

  # File not found
  else
    echo "Nothing to cleanup"
  fi
}

#-------------------------------------------------------------------------------

main() {
  "$@"
}

main "$@"
