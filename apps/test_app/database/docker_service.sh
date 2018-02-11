docker service create \
--name database \
--publish 5432:5432 \
--replicas=1 \
--constraint 'node.role == manager' \
--mount type=volume,source=cluster_test_app_database,target=/var/lib/postgresql/data \
--secret DEFAULT_PASSWORD \
--env POSTGRES_PASSWORD_FILE=/run/secrets/DEFAULT_PASSWORD \
--network cluster_test_app \
jabaridash/cluster_test_app_database
