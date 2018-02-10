echo "Enabling passwordless ssh"

# Get absolute path of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Get common user name
user=$(cat ${DIR}/../assets/user)

# Get list of ips
ips="${DIR}/../assets/ips"

# Copy the ssh key to each node in list.
# NOTE - At some later date, perhaps we should
# run this script on the leader. In the event
# that the leader wants to ssh into each node
# it should be able to do that without being
# prompted for a password for each node. For now,
# this works for simply setting up the cluster.
/bin/bash ${DIR}/setup.sh $user $(cat $ips)
