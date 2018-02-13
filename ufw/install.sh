#!/bin/bash

# TODO - Find a better way, because this
# is the second time i locked myself out!
# set -e

# TODO - MAKE SURE PORT 22 IS OPEN
# OR WE HAVE SOME WAY BACK IN

echo "Configuring UFW firewall"

# Get absolute path of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Get list of dependencies
ports="${DIR}/assets/ports"

# Alias to import util script
util="/bin/bash ${DIR}/../util/util.sh"

# Alias to functions in util script
scp_nodes="${util} scp_nodes"
ssh_nodes="${util} ssh_nodes"

# SCP setup and password file script to each node
$scp_nodes ${DIR}/setup.sh

# Run setup script on each node
$ssh_nodes /bin/bash setup.sh $(cat $ports)
