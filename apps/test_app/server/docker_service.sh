#!/bin/bash
set -e

docker service create \
--name server \
--publish 8085:8085 \
--replicas=1 \
--constraint 'node.role == manager' \
--secret DEFAULT_PASSWORD \
--env DB_PASSWORD_FILE=/run/secrets/DEFAULT_PASSWORD \
--network cluster_test_app \
jabaridash/cluster_test_app_server
