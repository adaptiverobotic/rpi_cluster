
# Start visualizer web app on port 9000
docker volume create portainer_data
docker run -d --restart=always -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer
