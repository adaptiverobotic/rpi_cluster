docker service create \
--name portainer \
--secret PORTAINER_PASSWORD \
--publish 9000:9000 \
--mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
portainer/portainer \
--admin-password-file '/run/secrets/PORTAINER_PASSWORD' \
-H unix:///var/run/docker.sock
