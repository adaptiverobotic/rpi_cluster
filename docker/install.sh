set -e

join_swarm() {
  echo "Each node joining swarm"
}

disband_swarm() {
  echo "Removing all nodes from existing swarm"
  $ssh_specific_nodes $ips "docker swarm leave --force"
}

echo "Installing Docker"

# Get absolute path of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Get list of ips
ips="${DIR}/../assets/ips"
leader_file="${DIR}/../assets/leader"
worker_file="${DIR}/../assets/worker"

# Get common user
user=$(cat ${DIR}/../assets/user)

# Get root assets
assets="${DIR}/../assets/"

# Alias to import util script
util="${DIR}/../util/util.sh"

# Alias to functions in util script
ssh_specific_nodes="/bin/bash ${util} ssh_specific_nodes"
scp_specific_nodes="/bin/bash ${util} scp_specific_nodes"

# SCP setup script to each node
$scp_specific_nodes $ips ${DIR}/setup.sh

# Install docker on all nodes
$ssh_specific_nodes $ips /bin/bash setup.sh install_docker $user

# Read leader ip into a file
echo "Selecting leader node"
echo $(head -n 1 $ips) > $leader_file
echo "Leader will be: $(cat $leader_file), make sure it's ip is static"

# TODO - Read first two lines as managers
# this way if one leader goes out we aren't screwed

# Read workers' ips into a separate file
echo "Generating list of worker node ips"
echo $(tail -n +2 ${ips}) | tr " " "\n" > $worker_file

# Send list of workers to leader so that leader can SSH through all
# of the workers and make them join the swarm
$scp_specific_nodes $leader_file $assets $util

# Loop through each node
# and remove it from existing swarm
disband_swarm

# Initialize the swarm
echo "Initializing new swarm"
$ssh_specific_nodes $leader_file /bin/bash setup.sh init_swarm

join_swarm
