#!/bin/bash
set -e

# TODO - Perhaps instead of installing on this
# machine (sysadmin), maybe we should install
# network address translation to the SSH server,
# and just let that server act as out "gateway-ish"
# server from and to the outside world. Ultimately,
# it will just be managing network traffic.

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

# Globals
declare_variables() {
  local src=$( $UTIL my_ip )
  local dhcp_leader=$(head -n 1 $DHCP_IP_FILE)
  local swarm_leader=$(head -n 1 $IPS)
  local nas_leader=$(head -n 1 $NAS_IP_FILE)
}

#-------------------------------------------------------------------------------

enable_forwarding() {
  :
}

#-------------------------------------------------------------------------------

# 53:53 (dns)
# 8081:80 (admin console)
port_forward_dhcp() {
  :
}

#-------------------------------------------------------------------------------

# 137:137
# 138:138
# 139:139
# 445:445 (smb)
# 8000:80 (nextcloud)
port_forward_nas() {
  :
}

#-------------------------------------------------------------------------------

# 80:80 (entry site)
# 9000:9000 (portainer)
port_forward_swarm() {
  :
}

#-------------------------------------------------------------------------------

# Set up port forwarding
# for all 3 clusters
setup_port_forward() {
  port_forward_dhcp
  port_forward_nas
  port_forward_swarm
}

#-------------------------------------------------------------------------------

main() {
  declare_variables
  enable_forwarding

  "$@"
}

#-------------------------------------------------------------------------------
