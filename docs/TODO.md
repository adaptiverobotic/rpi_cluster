# To-do List

* Add log management mechanism. Should we continuously write out to one long log
file, and perhaps just put a line-break before and after each deployment so we know
where to start and stop. Or should we have separate folders by ip, and then have
a unique time stamp per deployment. We will have many more files, but it will
be way easier to track deployments. Its just more code to implement the second.
* Maybe we shouldn't deploy samba to container because that is platform specific.
That it it requires an images such as ubuntu, or debian. Which is fine if we can guarantee
that the architecture of our nodes is x86, and the kernel is that of debian. However,
we cannot. We want this application to be as platform independent as possible.
* Changing user name may be a challenge in that by default pi's the root account is
locked. We don't know which other distros is true for. Let's ommit that for the sake of platform independence.
* Move dependency install script to util as it will reused in several places
* Fix SQLite3 syntax issues / corruption in test_app's client application
* Create simple flow chart / one page index.html to host on github pages that documents the project
