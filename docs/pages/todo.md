# To-do List
Things I still need to implement / fix


* Need to create local docker registry if i want to build locally
so that non-managers can get the images or nodes can push to it. This
way I can build img:x86, and img:armv7 and the appropriate machine
knows who to pull from. This is some extra work, so I think we are just going
to have to live with machines not restarting containers after power outage.
Too much work. Perhaps, I can run the docker-registry container in each swarm.
Or perhaps dedicate an entire server to that.

* Figure out how to see the specs of a machine, and perhaps
do not assign lower end specs, specific tasks. We will handle this
in the list.sh script when we are assigning ips given tasks.

The following command gets the amount of ram in kbs

`cat /proc/meminfo | grep  MemTotal | awk '{print $2}'`

This gets processor info, we get an entry
for each core, so we should count how many times
we get an entry to figure out the number of cores
that the machine has

`cat /proc/cpuinfo`

* Perhaps when we are running in async mode,
instead of erroring out if a single node fails. Let's take it off the list of $IPS
and continue with working nodes. And as long
as we make it to the end with at least one
node, we can report back which ones dropped out.

* scp send is async, but right now scp get is sync only because we do not have a facility
for making sure that if we are copying files with the same name from different nodes (highly probably)
files do not get overriden, or even worse, we get some sort of concurrent read or write error.
an idea is to perhaps establish the pattern of, for incoming scp, we bring files into a
folder name scp_get, and within there, there are directories that's names are ip addresses. That way
for a given scp_get operation, the right files get piped to the right folder, and we can perform asynchronous scp_get operations. processing these files can will then be synchronous, but that is once they are downloaded. This is a lot
less of an expensive operation in sync mode than file transfer.

* Let's explore making $IPS read only. We can either read the file or delete it
and make a new one. Obviously it will have write privileges when we are constructing
it. but once the list.sh script is done. it will change the permissions on `$IPS`.
In fact, `$ASSETS` and all of its files should become read only once we have started
the script. If we put an API in front if this, the API will be responsible for
generating these files.

* Fix SQLite3 syntax issues / corruption in test_app's client application

* At some point scan code base for platform specific commands. We are already tied to debian and bash
ideally, that should b it.
