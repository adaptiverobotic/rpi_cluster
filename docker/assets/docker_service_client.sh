
#!/bin/bash
set -e

docker service create --name client --mode global --publish mode=host,target=5000,published=5000 --mount type=bind,source=/sys/class/net/eth0/address,target=/client/src/config/address --mount type=volume,source=cluster_test_app_sqlite3,target=/client/db --env MAC_ADDRESS_FILE=/client/src/config/address --network cluster_test_app jabaridash/cluster_test_app_client
