set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

# Displays the OS in lower case
determine_os() {
  lsb_release -i           \
  | grep "Distributor ID:" \
  | awk '{print $3}'       \
  | tr '[A-Z]' '[a-z]'
}

#-------------------------------------------------------------------------------

# Globals
declare_variables() {
  readonly os=$(determine_os)
  readonly user=$2; shift
  readonly pass=$2;
}

#-------------------------------------------------------------------------------

# Make the smb.conf
make_samba_conf() {
  echo "Generating samba config file"

  cat > $(pwd)/smb.conf << EOF
  [global]
    workgroup = HOME

  [home]
    comment   = home
    path      = /home/$user
    read only = no
    guest ok  = no
EOF

  echo "Successfully generating config file"
}

#-------------------------------------------------------------------------------

# Make the Dockerfile
make_dockerfile() {
  local img=""

  # Pick image based off of OS type
  if [ "$os" = "ubuntu" ]; then
    img="ubuntu"
  elif [ "$os" = "raspbian" ]; then
    img="resin/rpi-raspbian"
  else
    echo "ERROR: OS '$os' not supported"
    return 1
  fi

  echo "Generating Dockerfile"

  cat > $(pwd)/Dockerfile << EOF
  FROM $img

  # Copy config files
  # and entrypoint script
  # into the docker container
  COPY smb.conf /smb.conf
  COPY entrypoint.sh /entrypoint.sh

  # Create non-root user
  RUN useradd -ms /bin/bash $user

  # SMB ports
  EXPOSE 137/udp 138/udp 139/tcp 445/tcp

  # HTTP / HTTPS ports
  EXPOSE 80 443

  # FTP port
  EXPOSE 21

  # NFS ports
  EXPOSE 111 2049

  CMD ./entrypoint.sh
EOF

  echo "Successfully generated Dockerfile"
}

#-------------------------------------------------------------------------------

# Build the samba image
# from our Dockerfile
build_samba() {
  # Make required files
  make_samba_conf
  make_dockerfile

  echo "Installing samba"
  echo "Building image: samba"
  docker build -t samba .
}

#-------------------------------------------------------------------------------

# Installs samba
install_samba() {

  build_samba

  # TODO - Consider Flocker for volume
  # propogation across nodes. Not a priority,
  # but that would make this a lot more of a
  # functional product

  echo "Create volume: samba"
  docker volume create samba

  echo "Runnning container: samba"
  # docker run                              \
  # -d                                      \
  # --name=samba                            \
  # -p 137:137                              \
  # -p 138:138                              \
  # -p 139:139                              \
  # -p 445:445                              \
  # -e COMMON_USER=$user                    \
  # -e COMMON_PASS=$pass                    \
  # --restart=always                        \
  # --mount source=samba,target=/home/$user \
  # samba:latest

  # TODO - Test this woring woth RPi, works on Ubuntu
  docker service create                           \
  --detach                                        \
  --name samba                                    \
  --mode replicated                               \
  --replicas 1                                    \
  --publish mode=ingress,target=137,published=137 \
  --publish mode=ingress,target=138,published=138 \
  --publish mode=ingress,target=139,published=139 \
  --publish mode=ingress,target=445,published=445 \
  --mount type=volume,src=samba,dst=/home/$user   \
  --env COMMON_USER=$user                         \
  --env COMMON_PASS=$pass                         \
  samba

  echo "Successfully start container: samba"
}

#-------------------------------------------------------------------------------

# Uninstalls samba
uninstall_samba() {
  echo "Uninstalling samba"

  if ! docker service rm samba; then
    echo "No service samba, or could not remove"
  fi

  if ! docker stop samba; then
    echo "No container samba, or could not stop"
  fi

  if ! docker rm samba --force; then
    echo "No container samba, or could not remove"
  fi

  if ! docker volume rm samba --force; then
    echo "No container samba, or could not remove"
  fi

  # NOTE - This may present problems if we are
  # installing other containers such as apache, etc
  # before we install samba. Find a better way.

  if ! docker system prune --force; then
    echo "Could not prune system"
  fi

  if ! docker rmi samba --force; then
    echo "Could not remove image: samba"
  fi

  echo "Successfully uninstalled samba"
}

#-------------------------------------------------------------------------------

# Uninstalls and
# reinstalls samba
reinstall_samba() {
  echo "Reinstalling samba"
  uninstall_samba
  install_samba
  echo "Successfully reinstalled samba"
}

#-------------------------------------------------------------------------------

main() {
  declare_variables "$@"

  "$@"
}

#-------------------------------------------------------------------------------

main "$@"
