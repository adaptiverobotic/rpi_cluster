install_docker() {
  echo "Installing docker on $user"

  # Allow docker command with no sudo
  curl -sSL https://get.docker.com | sh
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -aG docker $user

  echo "Finished Docker install process"
}

#-------------------------------------------------------------------------------

uninstall_docker() {
  echo ""
  # NOTE - DO NOT INSTALL DOCKER FROM apt-get
  # IT IS A NIGHTMARE TO UNINSTALL
}

#-------------------------------------------------------------------------------

init_swarm() {

  # Leave swarm, make a new one
  x=$(docker swarm leave --force)
  y=$(docker swarm init --advertise-addr 192.168.2.100)

  # Check exit status
  if [ $? -ne 0 ]
  then
    echo "Failed to init swarm, tokens not generated"
    exit 1
  fi

  # Get the join-token for workers and managers
  echo $(docker swarm join-token worker | grep "docker") > worker_token.sh
  echo $(docker swarm join-token manager | grep "docker") > manager_token.sh

  # Make them executable
  chmod 777 worker_token.sh
  chmod 777 manager_token.sh

  # Move util to the right spot
  # so that it can properly read
  # in the assets/user file for
  # user with scp and ssh
  mkdir util
  mv util.sh util/util.sh

  # Send join script over to each node, then execute it
  ./util/util.sh scp_specific_nodes worker worker_token.sh
  ./util/util.sh ssh_specific_nodes worker "docker swarm leave --force"
  ./util/util.sh ssh_specific_nodes worker /bin/bash worker_token.sh
}

#-------------------------------------------------------------------------------

user=$2

"$@"
