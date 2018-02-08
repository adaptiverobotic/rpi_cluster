echo "Enabling passwordless ssh"

# Get absolute path of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Get list of ips
ips="${DIR}/../assets/ips"

# Get common user name
user=$(cat ${DIR}/../assets/user)

# Get common password
password="${DIR}/../assets/password"

# Alias to import util script
util="/bin/bash ${DIR}/../util/util.sh"

# Alias to functions in util script
scp_nodes="${util} scp_nodes"
ssh_nodes="${util} ssh_nodes"

# SCP setup and password file script to each node
$scp_nodes $user $ips ${DIR}/setup.sh $password

# Run setup script on each node
$ssh_nodes $user $ips /bin/bash setup.sh $user $(cat $ips)
