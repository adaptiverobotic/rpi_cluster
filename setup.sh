set -e

setup_cli() {
  ./cli/cli.sh build
  ./cli/cli.sh setup
}

setup_api() {
  sudo apt-get install python3-pip
  pip3 install -r api/assets/requirements.txt
}

setup_gui() {
  :
}
