# Remove old data
./clean.sh assets/clean

# Initialize docker networks
./network.sh assets/networks

# Initialize docker volumes
./volume.sh assets/volumes

# Ensures that all secrets are created
./secret.sh assets/secrets

# Tag and build new images locally
./build.sh assets/images

# Deploy stack to Swarm
./run.sh assets/stack

# Push latest images up to docker hub
# ./push.sh assets/images
