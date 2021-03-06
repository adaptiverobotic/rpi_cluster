# The Command Line Interface
This is the core part of the application. It is a shell (bashv4+) library that
facilitates deployment to each server. The `/cli` directory contains that code
and is structured as follows:

```
/cli
├── /assets
|   ├── asset_1
|   ├── asset_2
|   .
|   .
|   .
|   └── asset_n
├── /bin
|   ├── program_1.o
|   └── program_2.o
├── /code
|   ├── /include
|   |   ├── program_1.h
|   |   └── program_1.h
|   ├── /src
|   |   ├── program_1.c
|   |   └── program_1.c
├── /app_1
|   ├── /assets
|   ├── install.sh
|   └── setup.sh
├── /app_2
|   ├── /assets
|   ├── install.sh
|   └── setup.sh
.
.
.
├── /app_n
|   ├── /assets
|   ├── install.sh
|   └── setup.sh
├── cli.sh
├── setup.sh
└── util.sh
```

Starting from the top down:

* `/assets` (at the root level) contains all files that are written and read in
more than one place throughout the application. It contains our global list
of ip addresses, common usernames, passwords, hostnames, etc.

* `/bin` Contains all "binaries." Small parts of the CLI are written in C, and thus
compiled into platform specific binaries in the `/bin` directory.

* `/code` Is where all of the C code that gets compiled into `/bin` lives.

* `/app_x` All other folders are considered apps. They contain a `install.sh` script
that is run from the system administrator node. The `install.sh` script facilitates
installing a given software (typically indicated by the name of the folder) on each node.
`install.sh` does this by sending `setup.sh` to each server, and executing it via `ssh`. They each
contain their own `/assets` directory that contains any files such as config files that
need to be sent to a node when setting it up. These asset files are only accessed within
that given app's directory.

* `cli.sh` Is the only script that is actually exposed. It contains all high level
functions such as installing a DNS server or Samba server. `cli.sh` is the only script
that the API has access to.

* `util.sh` Contains all reusable code throughout the project. All other code is
private to it's respective directory.

* `setup.sh` Is a script that is run once on the system administrator server. It is
responsible for compiling C files into `/bin` and doing any other initial setup.

## Functions
These are the functions that `cli.sh` exposes for use from the command line or api.
Each function takes 1 of the following arguments. `install`, `uninstall` or `reinstall`.


| Function      | Program            | Destination server(s) |
| :-------:     | :----------------: | :--------------------:|
| `pihole()`    | pi-hole            | DNS                   |
| `nextcloud()` | nextcloud          | NAS                   |
| `samba()`     | samba              | NAS                   |
| `nat()`       | ufw                | NAT                   |
| `magic()`     | All of the above   | All of the above      |
