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

Each of the above is deployed as a [Docker Swarm][swarm] cluster, containing at least 1 node.
Deploying them as clusters allows for easily expansion and redundancy. Each server runs a an
instance of [Portainer][portainer] for container management from a web interace.

## Auxiliary Functionality
To accomplish the core functionality, the following must be in place:

* The ability to administer SSH keys for password-less SSH access
* IP address list generation to automatically discover nodes on the network.
* Hostname modification for labelling nodes based on their use

## Network Attached Storage (NAS)
I accomplished NAS in two ways. First, I use [Samba][samba] to create network drives that can
be mounted as drives and used natively in any mainstream operating system. The second
approach was to expose a [Nextcloud][nextcloud] server for cloud storage. This provides a web
interface similar to Dropbox or Google Drive for content management. This also allows
several other devices on the network to connect with the desktop or mobile client app.

## Domain Name System (DNS)
I use [Pi-hole][pihole] for DNS. This allows me to block unwanted ads at the network level. I can
also use Pi-hole to block traffic from specific sites and implement a DHCP server
for managing the DHCP leases of the other servers. Currently it is only being use for
it's DNS functionality.

## Network Address Translation (NAT)
I use iptables and [Uncomplicated Firewall (UFW)][ufw] for NAT. This allows me to expose
only one host (the firewall) that will forward traffic to the appropriate server
depending on port of the incoming connection. For example, port 80 might send traffic
to one of the general purpose servers, but port 53 goes to the DNS server.

## General purpose cluster
The remaining servers are used as a general purpose cluster for deploying
web apps such as Wordpress or MySQL.

## Other links
Check out the rest of the documentation.

* [How the code works](pages/code.md)
* [Installation guide](pages/install.md)
* [System requirements](pages/reqs.md)
* [Application limitations](pages/limits.md)

[portainer]: https://portainer.io/
[pihole]: https://pi-hole.net/
[nextcloud]: https://nextcloud.com/
[samba]: https://www.samba.org/
[ufw]: https://wiki.ubuntu.com/UncomplicatedFirewall
[swarm]: https://docs.docker.com/engine/swarm/
[cluster_diagram]: assets/img/cluster_diagram.png
