generate_tokens() {
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
  echo $(docker swarm join-token worker | grep "docker") > ${assets}worker_token
  echo $(docker swarm join-token manager | grep "docker") > ${assets}manager_token
}

#-------------------------------------------------------------------------------

echo "Installing Docker"

# Get absolute path of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

assets="${DIR}/assets/"

# Get list of ips
ips="${DIR}/../assets/ips"

# Get common user
user=$(cat ${DIR}/../assets/user)

# Alias to import util script
util="/bin/bash ${DIR}/../util/util.sh"

# Alias to functions in util script
scp_nodes="${util} scp_nodes"
ssh_nodes="${util} ssh_nodes"

# SCP setup and password file script to each node
$scp_nodes ${DIR}/setup.sh

# Install docker on all nodes
$ssh_nodes /bin/bash setup.sh install_docker $user

# Initialize a docker swarm
generate_tokens
