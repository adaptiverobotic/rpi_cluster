./upload.sh

if [ $? -eq 0 ]
then
  docker pull jabaridash/cluster_test_postgres:latest
  docker pull jabaridash/cluster_test_server:latest
  docker pull jabaridash/cluster_test_client:latest
fi
