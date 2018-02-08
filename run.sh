# Build ip address list
/bin/bash ips/list.sh

# Enable passwordless ssh
/bin/bash ssh/install.sh

# Configure firewall
/bin/bash ufw/install.sh

# Setup network attached storage
/bin/bash samba/install.sh

# Initialize docker swarm
/bin/bash docker/install.sh

# Deploy test_app
/bin/bash docker/deploy/deploy.sh services
