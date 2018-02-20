set -e

#-------------------------------------------------------------------------------

declare_variables() {
  :
}

#-------------------------------------------------------------------------------

start_pihole() {

  # Does not work MAC
  IP_LOOKUP="$(ip route get 8.8.8.8 | awk '{ print $NF; exit }')"
  IP="${IP:-$IP_LOOKUP}"
  IPv6="${IPv6:-$IPv6_LOOKUP}"
  DOCKER_CONFIGS="$(pwd)"

  docker volume create pihole


  # TODO - Figure out why doesn't work

  docker run -d \
  --name pihole \
  -p 53:53/tcp -p 53:53/udp -p 80:80 \
  -v "pihole:/etc/pihole/" \
  -v "${DOCKER_CONFIGS}/dnsmasq.d/:/etc/dnsmasq.d/" \
  -e ServerIP="192.168.2.100" \
  -e WEBPASSWORD=raspberry \
  --restart=unless-stopped \
  diginc/pi-hole:arm_v3.1
}

#-------------------------------------------------------------------------------

remove_pihole() {
  docker volume --force rm pihole

  docker stop pihole

  docker rm --force pihole
}

#-------------------------------------------------------------------------------

main() {
  declare_variables "$@"
}

#-------------------------------------------------------------------------------

main "$@"
