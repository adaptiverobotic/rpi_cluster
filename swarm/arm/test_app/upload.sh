./build.sh

if [ $? -eq 0 ]
then
  docker push jabaridash/cluster_test_postgres:latest
  docker push jabaridash/cluster_test_server:latest
  docker push jabaridash/cluster_test_client:latest
fi
