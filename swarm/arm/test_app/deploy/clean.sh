# Stop all services associate with stack
docker stack rm $(cat assets/stack)

while read line; do
  if [[ $line == "secrets" ]]; then
    ./rm_secrets.sh assets/secrets

  elif [[ $line == "networks" ]]; then
    ./rm_networks.sh assets/networks

  elif [[ $line == "volumes" ]]; then
    ./rm_volumes.sh assets/volumes

  elif [[ $line == "containers" ]]; then
    ./rm_containers.sh assets/images

  elif [[ $line == "images" ]]; then
    ./rm_images.sh assets/images
  fi

done <$1
