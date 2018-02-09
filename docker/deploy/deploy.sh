echo "Deploying test application"

# Get absolute path of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Path to file with leader
leader_file="${DIR}/../../assets/leader"

# Alias to import util script
util="${DIR}/../../util/util.sh"

# Alias to functions in util script
ssh_specific_nodes="/bin/bash ${util} ssh_specific_nodes"
scp_specific_nodes="/bin/bash ${util} scp_specific_nodes"

# SCP setup script to each node
$scp_specific_nodes $leader_file ${DIR}/setup.sh

# Install docker on all nodes
$ssh_specific_nodes $leader_file /bin/bash setup.sh services
