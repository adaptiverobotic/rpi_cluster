# To-do List

* Ping subnet so that all ips come up when we run that first arp -a command on a new instll
* Perhaps add debugging set +x or whatever the flag is so that function names
or even etter, full commands are displayed.
* Clean up the ip list.sh script to comply with standards
* Maybe we shouldn't deploy samba to container because that is platform specific.
That it it requires an images such as ubuntu, or debian. Which is fine if we can guarantee
that the architecture of our nodes is x86, and the kernel is that of debian. However,
we cannot. We want this application to be as platform independent as possible.
* Changing user name may be a challenge in that by default pi's the root account is
locked. We don't know which other distros is true for. Let's ommit that for the sake of platform independence.
* Move dependency install script to util as it will reused in several places
* Fix SQLite3 syntax issues / corruption in test_app's client application
* Create simple flow chart / one page index.html to host on github pages that documents the project
* At some point scan code base for platform specific commands. We are already tied to debian and bash
ideally, that should b it.
