# To-do List

* Deploy samba in docker instead of to straight os. That way everything is
on top of docker and the only dependencies we have are ufw for port management
* Change user name to match the service we are running. That way the hostname
folder over kubernetes does not get impactd by docker or samba. We can then
also get the clusters running as multiple things, such as k8s and swarm.
* Improve hostname change so changes take effect immediately
* Move dependency install script to util as it will reused in several places
* Fix SQLite3 syntax issues / corruption in test_app's client application
* Maybe do Samba via Docker rather than in host OS? Might not be worth is though
* Create simple flow chart / one page index.html to host on github pages that documents the project
