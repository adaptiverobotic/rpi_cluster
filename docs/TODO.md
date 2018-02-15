# To-do List

* Let's explore making $IPS read only. We can either read the file or delete it
and make a new one. Obviously it will have write privelages when we are constructing
it. but once the list.sh script is done. it will change the permissions on $IPS.
In fact, $ASSETS and all of its files should become read only once we have started
the script. If we put an API in front if this, the API will be responsible for
generating these files.
* Perhaps add debugging set +x or whatever the flag is so that function names
or even etter, full commands are displayed.
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
