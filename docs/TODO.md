# To-do List

* scp send is async, but right now scp get is sync only because we do not have a facility
for making sure that if we are copying files with the same name from different nodes (highly probably)
files do not get overriden, or even worse, we get some sort of concurrent read or write error.
an idea is to perhaps establish the pattern of, for incoming scp, we bring files into a
folder name scp_get, and within there, there are directories that's names are ip addresses. That way
for a given operation, the right files get piped to the right folder, and we can perform asynchronous scp_get operations.


* Let's explore making $IPS read only. We can either read the file or delete it
and make a new one. Obviously it will have write privileges when we are constructing
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
