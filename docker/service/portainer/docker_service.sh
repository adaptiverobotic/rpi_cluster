docker service create \
--name portainer \
--mode global \
--publish mode=host,target=9000,published=9000 \
--mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
--mount type=volume,source=portainer,target=/data \
portainer/portainer \
-H unix:///var/run/docker.sock
