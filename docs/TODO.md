# To-do List

* Maybe we shouldn't deploy samba to container because that is platform specific.
That it it requires an images such as ubuntu, or debian. Which is fine if we can guarantee
that the architecture of our nodes is x86, and the kernel is that of debian. However,
we cannot. We want this application to be as platform independent as possible.
* Changing user name may be a challenge in that by default pi's the root account is
locked. We don't know which other distros is true for. Let's ommit that for the sake of platform independence.
* Move dependency install script to util as it will reused in several places
* Fix SQLite3 syntax issues / corruption in test_app's client application
* Create simple flow chart / one page index.html to host on github pages that documents the project
