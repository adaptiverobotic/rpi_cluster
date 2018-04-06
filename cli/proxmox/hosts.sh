set -e

# NOTE - Plan

# Set up a PXE server to auto install
# debian / proxmox on host servers.
#
# Power on the hosts, they will automatically
# install Debian standard from PXE server
#
# Plant a script on each debian installation
# that allows each server to "phone home" to
# sysadmin via it's temporary DHCP assigned IP.
#
# Scan the network, make sure the highest ip addresses
# are not used. For however many host servers we plan to
# have, start at the highest ip address in the range, and count
# down.
#
# SSH into each node, changing IP address assignment
# from dynamic tp static via the above mentioned
# pattern. Allow them to restart and phone back
# home with their new static ips.
#
# Once we have static ips on the host servers,
# we can proceed to install Proxmox via their
# suggested method.
# https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_Stretch
#
# Once we have installed Proxmox, we need to
# manually configure a Bridge network adapter
# as well as a Volume Group named pve for storing
# local ISOs, etc.
#
# Once each host is set up properly, we will create
# a cluster on the host with the highets ip address.
# If we have other host, we will ssh into those hosts
# and make them join the cluster.
#
# Now that we have the hosts in the same cluster, we
# will create VMs. Perhaps, put half on one node, and
# half on the next node, or some sort of even distribution
# for demonstration purposes.
#
# Before we start the VMs, we must kill the PXE server that we
# used to autoinstall Debian. We will replace it with a PXE
# server that auto installed Ubuntu.
#
# We then start the VMs, and they will automatically
# install Ubuntu.
#
# If possible, we can set static ips at this point.
# We would plant a "phone home" script just like with
# the hosts, and either count up, or count down.
#
# Once we have gotten to this step, we are ready
# to start installing the docker enginer, etc.
