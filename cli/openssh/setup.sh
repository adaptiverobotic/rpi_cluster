#!/bin/bash
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

declare_variables() {

  # NOTE - If we want to still support Raspberry Pi,
  # we must dynamically figure out the OS and by that
  # choose the image. We do this with the above function.
  # We then use some sort of if-else logic to decide on
  # which docker image to pull.
  readonly image="ubuntu:16.04"

  # Make sure correct number
  # of arguments is supplied
  if [ $# -ne 3 ]; then
    echo "ERROR: Incorrect number of arguments, Found: $#, Required: 3. Aborting."
    return 1
  fi

  # Read in the args
  readonly port=$1; shift
  readonly user=$1; shift
  readonly pass=$1;
}

#-------------------------------------------------------------------------------

# Influenced by StackOVerflow post:
# https://stackoverflow.com/questions/28134239/how-to-ssh-into-docker
create_dockerfile() {
  cat > $(pwd)/Dockerfile << EOF
  FROM $image

  # Install SSH server and client
  RUN apt-get update &&  \
      apt-get install -y \
      openssh-server     \
      openssh-client

  # Change the root password
  RUN mkdir /var/run/sshd
  RUN echo 'root:$pass' | chpasswd

  # TODO - Create a non-root user

  # Allow Root login
  RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

  # SSH login fix. Otherwise user is kicked off after login
  RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

  ENV NOTVISIBLE "in users profile"
  RUN echo "export VISIBLE=now" >> /etc/profile

  EXPOSE 22
  CMD ["/usr/sbin/sshd", "-D"]
EOF
}

#-------------------------------------------------------------------------------

uninstall_openssh() {
  echo "Uninstalling Open SSH"

  # Stop any old instances of the container
  if ! docker stop openssh --force; then
    echo "No container to stop named: openssh"
  fi

  # Remove any old instance of the container
  if ! docker rm openssh --force; then
    echo "No container to remove named: openssh"
  fi

  # Remove any old image labels openssh
  if ! docker rmi openssh --force; then
    echo "No image to remove named: openssh"
  fi
}

#-------------------------------------------------------------------------------

install_openssh() {
  uninstall_openssh
  create_dockerfile
  docker build -t openssh .
  docker run -d -p $port:22 --name openssh openssh
}

#-------------------------------------------------------------------------------

main() {
  declare_variables "${@:2}"

  $1
}

main "$@"
