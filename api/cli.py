import time
import subprocess

# import subprocess
import shlex

from shelljob import proc

# Build src
def build():
    return 1

#-------------------------------------------------------------------------------

# Setup for deployment
def setup():
    return 1

#-------------------------------------------------------------------------------

# Set global hostname
def set_hostname():
    return "HOSTNAME"

#-------------------------------------------------------------------------------

# Set global username
def set_user():
    return 1

#-------------------------------------------------------------------------------

# Set global password
def set_password():
    return 1

#-------------------------------------------------------------------------------

# Setup and install everything
def magic():
    return 1

#-------------------------------------------------------------------------------

# Install nextcloud on NAS server(s)
def nextcloud():
    return 1

#-------------------------------------------------------------------------------

# Install samba of NAS server(S)
def samba():
    return 1

#-------------------------------------------------------------------------------

# Install pi-hile on DNS server(s)
def pihole():
    return 1

#-------------------------------------------------------------------------------

# Install firewall on sysadmin server
def nat():
    cmd=['/bin/bash', '../cli/cli.sh', '192.168.1']

    result = subprocess.run(cmd, stdout=subprocess.PIPE, shell=False)

    list = result.stdout.decode('utf-8').split('\n')

    for i in list:
        yield i + "<br>"
        time.sleep(0.05)


