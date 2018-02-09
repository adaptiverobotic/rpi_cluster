echo "Configuring Samba"

# Get absolute path of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Get list of dependencies
conf="${DIR}/assets/smb.conf"

# Alias to import util script
util="/bin/bash ${DIR}/../util/util.sh"

# Alias to functions in util script
scp_nodes="${util} scp_nodes"
ssh_nodes="${util} ssh_nodes"

# SCP setup and config file script to each node
$scp_nodes ${DIR}/setup.sh $conf

# Run setup script as sudo on each node
$ssh_nodes sudo /bin/bash setup.sh
