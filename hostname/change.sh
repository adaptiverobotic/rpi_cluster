#!/bin/bash
set -e

echo "Changing hostname of each node"

# Get absolute path of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Get common user name
user=$(cat ${DIR}/../assets/user)

# Alias to import util script
util="/bin/bash ${DIR}/../util/util.sh"

# Alias to functions in util script
scp_nodes="${util} scp_nodes"
ssh_nodes="${util} ssh_nodes"

# SCP setup and password file script to each node
$scp_nodes ${DIR}/setup.sh

# Run setup script on each node
$ssh_nodes sudo /bin/bash setup.sh $user
