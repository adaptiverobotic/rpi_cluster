base_ip=$1
user=$2
base=$3
begin=$5+1
end=$6

# ------------------------------------------------------------------------------

echo "Initializing leader"
leader_ip=$base_ip$(($base+$4))
echo "Leader: $leader_ip"

leader_user=$user@$leader_ip

# Initialize the swarm, and generate the join tokens
str=$(ssh $leader_user "sudo ~/setup/generate_tokens.sh $leader_ip")

# Check exit status
if [ $? -ne 0 ]
then
  echo "Initializing swarm was unsuccessful"
  exit 1
fi

# ------------------------------------------------------------------------------

echo "Pulling down join-tokens"

# Get output from last command
# but only the lines starting with docker
sep='$($str | grep docker)'

# Put them in new line
echo "${str//$sep/$'\n'}" > tokens.txt

join_worker=$(head -n 1 tokens.txt)
join_manager=$(tail -n 1 tokens.txt)

# Remove temp file
rm -f tokens.txt

# ------------------------------------------------------------------------------

echo "Initializing manager"
manager_ip=$base_ip$(($base+$5))

echo "Manager: $manager_ip"

manager_user=$user@$manager_ip

ssh $manager_user "docker swarm leave --force && $join_manager"

# ------------------------------------------------------------------------------

echo "Initializing workers"
# Loop through all ips in range
for ((i=$begin;i<$end;i++));
do
  worker_ip=$base_ip$(($base+$i))

  echo "Worker: $worker_ip"

  worker_user=$user@$worker_ip

  # TODO - HOW TO REMOVE FROM SWARM IF IN SWARM
  ssh $worker_user bash -c "'

    docker swarm leave --force && $join_worker  
  '"

done

# ------------------------------------------------------------------------------

# Check exit status
if [ $? -ne 0 ]
then
  echo "Swarm was not successfully created"
  exit 1
else
  echo "Swarm successfully created"
  exit 0
fi
