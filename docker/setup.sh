install_docker() {
  echo "Installing docker on $user"

  # Allow docker command with no sudo
  curl -sSL https://get.docker.com | sh
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -aG docker $user

  echo "Finished Docker install process"
}

#-------------------------------------------------------------------------------

uninstall_docker() {
  echo ""
  # NOTE - DO NOT INSTALL DOCKER FROM apt-get
  # IT IS A NIGHTMARE TO UNINSTALL
}

#-------------------------------------------------------------------------------

user=$2


"$@"
