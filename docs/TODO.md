# To-do List

* Implement timeout to kill jobs that are
taking too long.

* Perhaps when we are running in async mode,
instead of erroring out if a single node fails. Let's take it off the list of $IPS
and continue with working nodes. And as long
as we make it to the end with at least one
node, we can report back which ones dropped out.

* Implement source util/util so that we are not spawning
new shells for each ./util.sh func call

* scp send is async, but right now scp get is sync only because we do not have a facility
for making sure that if we are copying files with the same name from different nodes (highly probably)
files do not get overriden, or even worse, we get some sort of concurrent read or write error.
an idea is to perhaps establish the pattern of, for incoming scp, we bring files into a
folder name scp_get, and within there, there are directories that's names are ip addresses. That way
for a given scp_get operation, the right files get piped to the right folder, and we can perform asynchronous scp_get operations. processing these files can will then be synchronous, but that is once they are downloaded. This is a lot
less of an expensive operation in sync mode than file transfer.

* Let's explore making $IPS read only. We can either read the file or delete it
and make a new one. Obviously it will have write privileges when we are constructing
it. but once the list.sh script is done. it will change the permissions on $IPS.
In fact, $ASSETS and all of its files should become read only once we have started
the script. If we put an API in front if this, the API will be responsible for
generating these files.

* Perhaps add debugging set +x or whatever the flag is so that function names
or even Better, full commands are displayed.

* Maybe we shouldn't deploy samba to container because that is platform specific.
That is, it requires an images such as ubuntu, or debian. Which is fine if we can guarantee
that the architecture of our nodes is x86, and the kernel is the same as that of the image.
Recall, docker images are just mock file systems, but the processes run natively on the host machine.
We want this application to be as platform independent as possible. So we will not deploy anything
that is kernel or distro specific. Everything should be both arm and x86 compatible, for whatever kernel.
As long as the nodes have apt-get, bash v4+, and an internet connection, we should be good.

* Changing user name may be a challenge in that by default pi's the root account is
locked. We don't know which other distros is true for. Let's ommit that for the sake of platform independence.

* Fix SQLite3 syntax issues / corruption in test_app's client application

* Create simple flow chart / one page index.html to host on github pages that documents the project

* At some point scan code base for platform specific commands. We are already tied to debian and bash
ideally, that should b it.
