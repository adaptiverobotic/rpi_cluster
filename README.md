# Docker Swarm with Raspberry Pi + NAS

This repository contains the scripts that I used to deploy a [Docker Swarm][docker] cluster
using [Raspberry Pi][rpi] Single Board Computers (SBC) as nodes.

It also includes the scripts that I used to deploy a [Network Attached Storage][nas] (NAS)
to **one** of the Raspberry Pi computers.

**NOTE:** This is a simple NAS based on [Samba][samba] without RAID or scheduled backup.
This implementation is not meant to be an end-all-be-all network drive solution. It is for easily sharing data between clients on the network.

[docker]: https://docs.docker.com/engine/swarm/
[rpi]: https://en.wikipedia.org/wiki/Raspberry_Pi
[nas]: https://en.wikipedia.org/wiki/Network-attached_storage
[samba]: https://www.samba.org/
