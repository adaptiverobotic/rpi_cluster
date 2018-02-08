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

This repository also includes the source for a [test application][test_app] that is composed of several services. It is a proof of concept application that demonstrates the ease of deploying a multi-service application to a Docker Swarm based infrastructure.

## Deploy Scripts

As most people who use Docker Command Line Interface (CLI) know, deploying docker containers includes a lot of repetitve work - especially when cleaning up. In response to this, I have written a few bash functions to address these drawbacks.

* [Deployment][deploy.sh]
* [Docker CLI][docker.sh]

## Network Attached Storage

The repo also includes the scripts that allow me to mount directories in the  local file systems of the nodes as a [Network Attached Storage][nas] (NAS). 

**NOTE:** This is a simple NAS based on [Samba][samba] without RAID or scheduled backup.
This implementation is not meant to be an end-all-be-all network drive solution. It is for easily sharing data between clients on the network.

[mysql]: ../docker/compose/mysql.yml
[postgres]: ../docker/compose/postgres.yml
[wordpress]: ../docker/compose/wordpress.yml
[jenkins]: ../docker/compose/jenkins
[drone]: ../docker/compose/drone.yml
[mongo]: ../docker/compose/mongo.yml
[portainer]: ../docker/stack/portainer.yml

[test_app]: ../docker/test_app

[deploy.sh]: ../docker/deploy/deploy.sh
[docker.sh]: ../docker/deploy/deploy.sh

[docker]: https://docs.docker.com/engine/swarm/
[rpi]: https://en.wikipedia.org/wiki/Raspberry_Pi
[nas]: https://en.wikipedia.org/wiki/Network-attached_storage
[samba]: https://www.samba.org/
