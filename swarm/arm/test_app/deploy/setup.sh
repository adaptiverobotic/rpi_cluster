# Remove old data
./clean.sh assets/clean

# Initialize docker volumes
./docker.sh volume assets/volumes

# Ensures that all secrets are created
./docker.sh secret assets/secrets
