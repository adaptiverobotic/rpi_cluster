# Docker Swarm with Raspberry Pi + NAS

This repository contains the scripts that I used to deploy a [Docker Swarm][docker] cluster
using [Raspberry Pi][rpi] Single Board Computers (SBC) as nodes. 

## Compose files

I have written a series of commonly used `docker-compose.yml` files for easy deployments of services such as:

* [MySQL][mysql]
* [PostgreSQL][postgres]
* [Wordpress][wordpress]
* [Jenkins][jenkins]
* [Drone CI][drone]
* [MongoDB][mongo]
* [Portainer][portainer]

## Test Application

This repository also includes the source for a test application that is composed of several services. It is a proof of concept application that demonstrates the ease of deploying a multi-service application to a Docker Swarm based infrastructure.

## Deploy Scripts

As most people who use Docker Command Line Interface (CLI) know, deploying docker containers includes a lot of repetitve work - especially clean up. In response to this, I have written a few bash functions that automate some of the repetitive work when it comes to cleanup and deployment of docker services.

* [Deployment][deploy.sh]
* [Docker CLI][docker.sh]

## Network Attached Storage

The repo also includes the scripts that allow me to mount directories in the  local file systems of the nodes as a [Network Attached Storage][nas] (NAS). 

**NOTE:** This is a simple NAS based on [Samba][samba] without RAID or scheduled backup.
This implementation is not meant to be an end-all-be-all network drive solution. It is for easily sharing data between clients on the network.

[mysql]: https://hub.docker.com/_/mysql/
[postgres]: https://hub.docker.com/_/postgres/
[wordpress]: https://hub.docker.com/_/wordpress/
[jenkins]: https://hub.docker.com/_/jenkins/
[drone]: https://hub.docker.com/r/drone/drone/
[mongo]: https://hub.docker.com/_/mongo/
[portainer]: https://hub.docker.com/r/portainer/portainer/

[deploy.sh]: ../docker/deploy/deploy.sh
[docker.sh]: ../docker/deploy/deploy.sh

[docker]: https://docs.docker.com/engine/swarm/
[rpi]: https://en.wikipedia.org/wiki/Raspberry_Pi
[nas]: https://en.wikipedia.org/wiki/Network-attached_storage
[samba]: https://www.samba.org/
