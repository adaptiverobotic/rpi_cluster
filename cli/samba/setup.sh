set -e

#-------------------------------------------------------------------------------

# Globals
declare_variables() {
  readonly user=$2; shift
  readonly pass=$2;
}

#-------------------------------------------------------------------------------

# Make the smb.conf
make_samba_conf() {
  echo "Generating samba config file"

  cat > $(pwd)/smb.conf << EOF
  [home]
    comment   = home
    path      = /home/$user
    read only = no
    guest ok  = no

  [global]
    workgroup = SIMPLE
EOF

  echo "Successfully generating config file"
}

#-------------------------------------------------------------------------------

# x86 or armv7 image
get_img_by_os() {
  echo "rpi-raspbian"
}

#-------------------------------------------------------------------------------

# x86 or armv7 image
get_tag_by_img() {
  echo "latest"
}

#-------------------------------------------------------------------------------

# Make the Dockerfile
make_dockerfile() {
  local img="rpi-raspbian"
  local tag="latest"
  local repo="resin"

  echo "Generating Dockerfile"

  cat > $(pwd)/Dockerfile << EOF
  #FROM $repo/$img:$tag
  FROM ubuntu

  COPY smb.conf /smb.conf
  COPY samba.sh /samba.sh

  RUN useradd -ms /bin/bash $user

  EXPOSE 137/udp 138/udp 139/tcp 445/tcp

  CMD ./samba.sh
EOF

  echo "Successfully generated Dockerfile"
}

#-------------------------------------------------------------------------------

# Installs samba
install_samba() {

  # Make required files
  make_samba_conf
  make_dockerfile

  echo "Installing samba"
  echo "Building image: samba"
  docker build -t samba .

  echo "Create volume: samba"
  docker volume create samba

  echo "Runnning container: samba"
  docker run   \
  -d           \
  --name=samba \
  -p 137:137   \
  -p 138:138   \
  -p 139:139   \
  -p 445:445   \
  -e COMMON_USER=$user     \
  -e COMMON_PASS=$pass     \
  --restart=unless-stopped \
  --mount source=samba,target=/home/$user \
  samba:latest

  echo "Successfully start container: samba"
}

#-------------------------------------------------------------------------------

# Uninstalls samba
uninstall_samba() {
  echo "Uninstalling samba"

  if ! docker stop samba; then
    echo "No container samba, or could not stop"
  fi

  if ! docker rm samba --force; then
    echo "No container samba, or could not remove"
  fi

  if ! docker volume rm samba --force; then
    echo "No container samba, or could not remove"
  fi

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
  echo "Successfully resinstalled samba"
}

#-------------------------------------------------------------------------------

main() {
  declare_variables "$@"

  "$@"
}

#-------------------------------------------------------------------------------

main "$@"
