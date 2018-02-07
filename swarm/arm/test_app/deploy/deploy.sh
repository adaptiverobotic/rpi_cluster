# Generates list of nodes by hostname
node_hostnames() {
  node_file=assets/nodes

  # Delete if exists
  rm -f $node_file

  # Recreate files
  touch $node_file

  # Write out to temp file
  temp=$(docker node ls -q | xargs docker node inspect -f '{{ .Description.Hostname }}')

  # Break up into array
  nodes=($temp)

  # Loop through array and Write
  # line by line
  for i in "${nodes[@]}"
  do
     :
     echo ${nodes[i]} >> $node_file
  done
}

#-------------------------------------------------------------------------------

run_locally() {
  # Initialize docker networks
  ./docker.sh network assets/networks

  # Tag and build new images locally
  ./docker.sh build assets/images

  # Deploy services to swarm
  ./docker.sh service assets/services

  # Deploy stack to swarm
  # docker stack deploy -c ../docker-compose.yml $(cat assets/stack)
}

#-------------------------------------------------------------------------------

# Get the common username
# from the user file
user=$(cat assets/user)

# Generate list of node hostnames
node_hostnames

# If we successfully wrote the list
if [[ $? -eq 0 ]]; then

  while read line; do

    # Send files over and execute
    scp -r assets clean.sh deploy.sh docker.sh setup.sh $user@$line:
    ssh -n $user@$line "./setup.sh"

  done <assets/nodes

  run_locally
fi
