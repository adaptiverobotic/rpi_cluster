# To-do List

* Figure out beforehand while nodes are going to be deployed to if possible.
  this way we are not downloading images and creating volumes on nodes that
  will not be running a task. This feature does not exist for stack deploy,
  but it does appear to be available for service.
* Improve hostname change so changes take effect immediately
* Move dependency install script to util as it will reused in several places
* Figure out how to create docker volumes on nodes it applies to
* Perhaps cd into directory of the script to avoid boilerplate code for directory resolution
* Loop through nodes asynchronously and await exit by process id
* Fix SQLite3 syntax issues / corruption in test_app's client application
* Maybe do Samba via Docker rather than in host OS? Might not be worth is though
* Figure out how to get services to wait for other services so we don't rely on infinite restart policy
* Create simple flow chart / one page index.html to host on github pages that documents the project
