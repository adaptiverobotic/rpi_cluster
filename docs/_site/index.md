# RPI Cluster
This is the documentation for the code I wrote to provision my
Raspberry Pi / Ubuntu cluster. This project is a proof of concept / peek
into the technical challenges of a system administrator. I wrote it because
I was interested in automating the process of provisioning different types
of servers and having them work together to as a functioning environment
for development and personal use. A diagram of my network architecture follows:

![project architecture][cluster_diagram]

## Core Functionality
Provisioning a production quality network of servers is no trivial task. To keep the
codebase small and robust, I only focused on the core parts:

* Network Attached Storage (NAS)
* Domain Name System (DNS)
* Network Address Translation (NAT)
* General purpose cluster

## Auxiliary Functionality
To accomplish the core functionality, the following must be in place:

* The ability to administer SSH keys for password-less SSH access
* IP address list generation to automatically discover nodes on the network.
* Hostname modification for labelling nodes based on their use

## Network Attached Storage (NAS) servers
I accomplished NAS in two ways. First, I use Samba to create network drives that can
be mounted as drives and used natively in any mainstream operating system. The second
approach was to expose a Nextcloud server for cloud storage. This provides a web
interface similar to Dropbox or Google Drive for content management. This also allows
several other devices on the network to connect with the desktop or mobile client app.

## Domain Name System (DNS) Server
I use Pi-hole for DNS. This allows me to block unwanted ads at the network level. I can
also use Pi-hole to block traffic from specific sites and implement a DHCP server
for managing the DHCP leases of the other servers. Currently it is only being use for
it's DNS functionality.

## Network Address Translation (NAT) server / firewall
I use iptables and Uncomplicated Firewall (UFW) for NAT. This allows me to expose
only one host (the firewall) that will forward traffic to the appropriate server
depending on port of the incoming connection. For example, port 80 might send traffic
to one of the general purpose servers, but port 53 goes to the DNS server.

## General purpose cluster
The remaining servers are used as a general purpose Docker Swarm cluster for deploying
web apps such as Wordpress or MySQL.

## Other links
Check out the rest of the documentation.

* [How the code works](pages/code.md)
* [System Requirements](pages/requirements.md)

## Note
All major components of the network (NAT, NAS, DNS, General purpose) are docker swarm
clusters. Each service (Samba, Nextcloud, Pi-hole, etc) is run as a docker service or
container. Although there is a slight overhead associated with running everything inside of
a container, I made this decision because it provides a layer of abstraction between the host OS
and the service. So, platform specific settings (x86 vs arm) can be changed in the Dockerfile
or `docker run` command rather than the codebase itself. That allows my code to focus solely
on orchestration, and not on platform specific idiosyncrasies. It also makes uninstalling a
service as easy as `docker stop <container> && docker rm <container>` rather than trying
to manage packages with `sudo apt-get --purge autoremove <package>` and cleaning up old config files
that `apt-get` did not account for.

[cluster_diagram]: assets/img/cluster_diagram.png
