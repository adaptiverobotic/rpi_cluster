# We must install this dependency
# outside of the dependency script
# because we use sshpass in util
# to ssh into all nodes without password
# sudo apt-get install sshpass

# Build ip address list
# /bin/bash ip/list.sh

# Enable passwordless ssh
# /bin/bash ssh/install.sh

# Change all the hostnames
# /bin/bash hostname/change.sh

# Install dependencies
# /bin/bash dependencies/install.sh

# Configure firewall
# /bin/bash ufw/install.sh

# Setup network attached storage
# /bin/bash samba/install.sh

# Initialize docker swarm
# /bin/bash docker/install.sh

# Deploy test application
/bin/bash docker/deploy/deploy.sh services
