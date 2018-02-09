echo "Installing dependencies"

# Get absolute path of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Get list of dependencies
dependencies="${DIR}/assets/dependencies"

# Alias to import util script
util="/bin/bash ${DIR}/../util/util.sh"

# Alias to functions in util script
ssh_nodes="${util} ssh_nodes"

# Run setup script on each node
$ssh_nodes sudo apt-get install $(cat $dependencies) -y
