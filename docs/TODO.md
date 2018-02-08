* Implement passwordless `ssh` via keys
* Update Samba install script to mount home directory on all nodes
* Update Docker Swarm install scripts to be read IP from file rather than increment from `base_ip`
* Fix SQLite3 syntax issues / corruption in test_app's client application
* Maybe do Samba via Docker rather than in host OS? Might not be worth is though
* Figure out how to get services to wait for other services so we don't rely on infinite restart policy
* Create simple flow chart / one page index.html to host on github pages that documents the project
* In Docker swarm install, by default install Portainer
* Change raspbian image to automatically allow ssh so we don't need `raspi-config` at initial boot
