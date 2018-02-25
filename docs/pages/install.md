# Installation
The application can run on a variety of setups. We can use virtual machines,
physical machines, or a mixture of both - as long as we have at least 5 in total.

## Setting up the cluster
Follow either (or both) of the two setup guides to setup the servers.

* [Physical server setup](rpi.md)
* [Virtual server setup](ubuntu.md)

## Downloading and compiling the code
Once we have the servers set up, we must download and build the code.

### Requirements
We can use our laptop as one of the nodes in the network, but I will assume that
we are not. So, from our laptop, we must SSH into any one of the servers. This server
will be our system administrator and firewall. Let's assume it has IP address `192.168.20.100`.

```
ssh pi@192.168.20.100
```

### Code setup
Once we are logged into our sysadmin node, we take the following steps:

1. Download the source.
```
git clone https://github.com/N02870941/rpi_cluster.git
```

2. Change directories into the newly downloaded folder.
```
cd rpi_cluster
```

3. Run the `setup.sh` script. This step will install all requirements
such as the commands `node`, `python3`, and build all source code so that
all three layers (`cli.sh`, `api.py`, and `gui.js`) can run correctly.
```
./setup.sh
```

### Verify installation success
We can verify that the app is up and running with the following command:

```
curl localhost:1030
```

Or, we can visit `http://192.168.20.100:1030` in the browser.
