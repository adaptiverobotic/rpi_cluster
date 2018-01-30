user="$1"

echo "Pulling install script"
curl -sSL https://get.docker.com | sh

echo "Enabling Docker"
sudo systemctl enable docker

echo "Starting Docker"
sudo systemctl start docker

# Allow docker command with no sudo
sudo usermod -aG docker $user

echo "Finished Docker install process"
