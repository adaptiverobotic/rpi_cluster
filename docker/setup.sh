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

  # Get this device's ip address
  ip=$(./util/util.sh my_ip)

  # Leave swarm, make a new one
  echo "Leaving old swarn and creating new one"
  docker swarm leave --force

  # Make a new one
  echo "Initializing swarm, advertising ip: $ip"
  docker swarm init --advertise-addr $ip

  # Check exit status
  if [ $? -ne 0 ]
  then
    echo "Failed to init swarm, tokens not generated"
    exit 1
  fi

  echo "Leaving old swarms"
  ./util/util.sh ssh_specific_nodes worker "docker swarm leave --force"

  # Get the join-token for workers and managers
  echo "Generating join tokens for joining the new swarm"
  ./util/util.sh ssh_specific_nodes worker $(docker swarm join-token worker | grep "docker")
  # ./util/util.sh ssh_specific_nodes manager $(docker swarm join-token manager | grep "docker")
}

#-------------------------------------------------------------------------------

user=$2

# Move util to the right spot
# so that it can properly read
# in the assets/user file for
# user with scp and ssh
mkdir -p util
mv util.sh util/util.sh

"$@"
