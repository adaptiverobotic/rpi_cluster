set -e

#-------------------------------------------------------------------------------

# Depending on the os architecture
# print the respective image name
determine_img_by_os() {
  echo "pi-hole-multiarch"
}

#-------------------------------------------------------------------------------

# Depending on image,
# print appropriate tag
determine_tag_by_img() {
  echo "debian_armhf"
}

#-------------------------------------------------------------------------------

# Globals
declare_variables() {
  readonly img=$(determine_img_by_os)
  readonly tag=$(determine_tag_by_img $img)
  readonly password=$2
}

#-------------------------------------------------------------------------------

# Start pihole as container
install_pihole() {
  IP_LOOKUP="$(ip route get 8.8.8.8 | awk '{ print $NF; exit }')"
  IP="${IP:-$IP_LOOKUP}"
  IPv6="${IPv6:-$IPv6_LOOKUP}"
  DOCKER_CONFIGS="$(pwd)"

  # Volume for storage
  docker volume create pihole

  # TODO - Mount the volume

  # -v "pihole:/etc/pihole/" \

  # Run the service
  docker run -d \
  --name pihole \
  -p 53:53/tcp -p 53:53/udp -p 80:80 \
  --mount source=pihole,target=/etc/pihole \
  -v "${DOCKER_CONFIGS}/.pihole/dnsmasq.d/:/etc/dnsmasq.d/" \
  -e ServerIP="$IP" \
  -e WEBPASSWORD=$password \
  --restart=unless-stopped \
  diginc/$img:$tag
}

#-------------------------------------------------------------------------------

# Remove the pihole container
uninstall_pihole() {

  if ! docker stop pihole; then
    echo "Could not stop container pihole or did not exist"
  fi

  if ! docker rm --force pihole; then
    echo "Could not remove container pihole or did not exist"
  fi

  if ! docker volume --force rm pihole; then
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
