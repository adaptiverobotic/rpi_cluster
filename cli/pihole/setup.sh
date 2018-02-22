set -e

#-------------------------------------------------------------------------------

# Displays the OS in lower case
determine_os() {
  lsb_release -i \
  | grep "Distributor ID:" \
  | awk '{print $3}' \
  | tr '[A-Z]' '[a-z]'
}

#-------------------------------------------------------------------------------

# Globals
declare_variables() {
  readonly os=$(determine_os)
  readonly password=$2
}

#-------------------------------------------------------------------------------

# Start pihole as container
install_pihole() {
  local img=""

  # Pick image based off of OS type
  if [ "$os" = "ubuntu" ]; then
    img="pi-hole"
  elif [ "$os" = "raspbian" ]; then
    img="pi-hole-multiarch:debian_armhf"
  else
    echo "ERROR: OS '$os' not supported"
    return 1
  fi

  IP_LOOKUP="$(ip route get 8.8.8.8 | awk '{ print $NF; exit }')"
  IP="${IP:-$IP_LOOKUP}"
  IPv6="${IPv6:-$IPv6_LOOKUP}"
  DOCKER_CONFIGS="$(pwd)"

  # Volume for storage
  docker volume create pihole

  # Run the container
  docker run -d \
  --dns=127.0.0.1 \
  --dns=8.8.8.8 \
  --name pihole \
  -p 53:53/tcp -p 53:53/udp -p 80:80 \
  --mount source=pihole,target=/etc/pihole \
  -v "${DOCKER_CONFIGS}/.pihole/dnsmasq.d/:/etc/dnsmasq.d/" \
  -e ServerIP="$IP" \
  -e WEBPASSWORD=$password \
  -e DNS1=8.8.8.8 \
  -e DNS2=8.8.4.4 \
  -e DNS=127.0.0.1 \
  -e TZ=America/New_York \
  -e VIRTUAL_HOST=pihole \
  --restart=always \
  diginc/$img

  # echo "Starting service: pihole"

  # docker service create \
  # --detach \
  # --dns=127.0.0.1 \
  # --dns=8.8.8.8 \
  # --name pihole \
  # --publish mode=host,target=53,published=53 \
  # --publish mode=host,target=80,published=80 \
  # --mount type=volume,src=pihole,dst=/etc/pihole \
  # --mount type=bind,src=${DOCKER_CONFIGS}/.pihole/dnsmasq.d/,dst=/etc/dnsmasq.d/ \
  # --env ServerIP="$IP" \
  # --env WEBPASSWORD=$password \
  # --env DNS1=8.8.8.8 \
  # --env DNS2=8.8.4.4 \
  # --env DNS=127.0.0.1 \
  # --env TZ=America/New_York \
  # --env VIRTUAL_HOST=pihole \
  # diginc/$img:$tag
}

#-------------------------------------------------------------------------------

# Remove the pihole container
uninstall_pihole() {

  if ! docker service rm pihole; then
    echo "Could not remove pihole"
  fi

  if ! docker stop pihole; then
    echo "Could not stop container pihole or did not exist"
  fi

  if ! docker rm pihole --force; then
    echo "Could not remove container pihole or did not exist"
  fi

  if ! docker volume rm pihole --force; then
    echo "Could not remove volume pihole or doesn't exist"
  fi

  # TODO - Remove all images associate with pihole
}

#-------------------------------------------------------------------------------

# Remove and reinstall
reinstall_pihole() {
  uninstall_pihole
  install_pihole
}

#-------------------------------------------------------------------------------

main() {
  declare_variables "$@"

  "$@"
}

#-------------------------------------------------------------------------------

main "$@"
