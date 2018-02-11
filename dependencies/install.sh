#!/bin/bash
set -e

echo "Installing dependencies"

# Get absolute path of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Get list of dependencies
dependencies="${DIR}/assets/dependencies"

# Alias to import util script
util="/bin/bash ${DIR}/../util/util.sh"

# Alias to ssh function in util script
ssh_nodes="${util} ssh_nodes"
scp_nodes="${util} scp_nodes"

# SCP setup script to each node
$scp_nodes ${DIR}/setup.sh

# Run setup script on each node
$ssh_nodes /bin/bash setup.sh $(cat $dependencies) -y
