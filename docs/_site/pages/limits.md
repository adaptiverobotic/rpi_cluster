# Application Limitations
This app is a proof of concept. So, naturally it will come with some limitations.
I will name some of the most prominent ones that I am aware of.

## Persistent storage
One of my biggest design decisions was to go with a "dockerized" or "native" solution. I chose docker because docker allows for easier deployment and cleanup of applications and services. The biggest download to docker though is its limitations with storage. Docker thrives with stateless applications. However, most application (especially in the case of this application) have a sense of state. Since I do not plan to actually use this application to deploy servers that will contain meaningful data, I chose to go with the docker approach.

## Security
Throughout the development process, I accidentally locked my self out of all of my servers by simply forgetting to open port 22 (for ssh). So, I leave port 22 open just in case. I also leave password login enabled because I found difficulty properly rotating ssh keys without running into `Too many failed authentication attempts`.

## Passwords in plain text
For simplicity, I am not encrypting passwords. I am storing them in plain text, and using the same password for logins. This is obviously a huge security hole. But, I made this decision because I did not want to get bogged down with the technicalities of hashing and un-hashing passwords and managing many different sets of credentials. High security was not the main goal of this project, however I am conscious of it's importance.

## Arm architecture
I designed this project initially solely for the Raspberry Pi. However, there are many compatibility limitations when deploying non-x86 servers. For example, the Raspberry Pi can run docker and along with the optional docker swarm with no issue. However, docker has not release arm binaries for `docker-compose`. So, deploying multi-container applications requires more code and consequently provides more room for error. It wasn't until weeks after I started the project that I realized that the software worked just as fine on the more popular x86 Ubuntu Server.

## Non-functional DHCP server
I am using Pi-hole as a DNS server. Pi-hole also has the ability to act as a DHCP server. I initially wanted to use this functionality. But, it does not seem to function. The router that connects all of the servers is connected to another router as it's source of internet. This router is provided by the Internet Service Provider (ISP). Even if I turn off the DHCP server in the second router, disabling DHCP in the ISP router is not an option. So, there may be conflict with Pi-hole advertising itself as a DHCP and the DHCP server running in the house router. In addition, even if I could turn off the DHCP in the ISP router, then everyone else on my house router would be depending on my servers to get an IP address - I'd be disrupting the rest of the network.

## Containers vs. Native installation
All major components of the network (NAT, NAS, DNS, General purpose) are Docker Swarm
clusters. Each service (Samba, Nextcloud, Pi-hole, etc) is run as a docker service or
container. Although there is a slight overhead associated with running everything inside of
a container, I made this decision because it provides a layer of abstraction between the host OS
and the service. So, platform specific settings (x86 vs arm) can be changed in the Dockerfile
or `docker run` command rather than the codebase itself. That allows my code to focus solely
on orchestration, and not on platform specific idiosyncrasies. It also makes uninstalling a
service as easy as `docker stop <container> && docker rm <container>` rather than trying
to manage packages with `sudo apt-get --purge autoremove <package>` and cleaning up old config files
that `apt-get` did not account for.
