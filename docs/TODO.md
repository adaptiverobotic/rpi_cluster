# To-do List

* Improve hostname change so changes take effect immediately
* Implement docker's suggest (n+1)/2 rule for manager:worker ratio
* Move dependency install script to util as it will reused in several places
* Figure out how to create docker volumes on nodes it applies to
* Create some sort of temporary symbolic link or alias for util
* Perhaps cd into directory of the script to avoid boilerplate code for directory resolution
* Loop through nodes asynchronously and await exit by process id
* Fix SQLite3 syntax issues / corruption in test_app's client application
* Maybe do Samba via Docker rather than in host OS? Might not be worth is though
* Figure out how to get services to wait for other services so we don't rely on infinite restart policy
* Create simple flow chart / one page index.html to host on github pages that documents the project
