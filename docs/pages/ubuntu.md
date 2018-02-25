### Virtual servers
I will detail how to run virtual ubuntu servers. But, in theory you could virtualize
Raspberry Pis.

### Requirements
We do not need any physical devices other than the host machine.

* An internet-connected host machine running Windows, Mac OS X, or Linux with at least 6GB of RAM
and a dual core processor

### Setting up VirtualBox
First we need to set up our virtual machine environment. You can use any virtual
machine software such as VirtualBox or VMWare. For this project, I found VirtualBox
to be most suitable.

1. Download and install [VirtualBox][virtualbox_download]
2. Download [Ubuntu Server 16.04][ubuntu_download]
3. Open VirtualBox and create a new virtual machine

Once you have VirtualBox running, take the following steps:

1. Give it any name, Type: Linux, Version: Ubuntu (64-bit). About 512MB of RAM should be fine, and check "Create a virtual hard disk now"
![step 1](/assets/img/install/virtual/virtual_step_01.png)

2. A window will pop up, give the VM 16GB-20GB of storage. Click create, then create again to complete the virtual machine creation
![step 2](/assets/img/install/virtual/virtual_step_02.png)

3. Right-click on the newly created machine, go to settings, then navigate to the "Network" tab. Make sure that the network adapter is enabled and is in "Bridged Adapter" mode. This will allow thee virtual machines to be discoverable on our local network as if they were physically connected devices.
![step 3](/assets/img/install/virtual/virtual_step_03.png)

4. Start the virtual machine by double-clicking it. A one-time prompt will ask you to select a disk image to start the VM from. Click the small arrow, which will open a Finder (or Explorer) window. Navigate to the Ubuntu Server ISO image you downloaded, and select it. Your window should then look as follows:
![step 4](/assets/img/install/virtual/virtual_step_04.png)

5. Start the machine. Select your language, keyboard settings, etc. You may use whatever settings you want util you reach account setup. If you plan to use Raspberry Pis along side your VMs, make the user "pi." All VMs and physical servers must have the same user and password.
![step 5](/assets/img/install/virtual/virtual_step_05.png)

6. As mentioned, pick the same password as the default Raspberry Pi password or whatever password all servers will use.
![step 6](/assets/img/install/virtual/virtual_step_06.png)

7. Continue using any settings you would like (for hard drive setup, and timezone) util you reach the "Software Selection" prompt. Here we need to make sure that we have "OpenSSH" along with "standard system utilities" and "manual package selection."
![step 7](/assets/img/install/virtual/virtual_step_07.png)

8. Continue using any other desired settings util we are prompted to install the GRUB bootloader. Select "Yes."
![step 8](/assets/img/install/virtual/virtual_step_08.png)

9. The bootloader prompt will be the last prompt before the installation is finalized. After completing the setup, login using your specified credentials and run the following command:
```
sudo visudo
```
Add the following line to the bottom of the file:
```
pi ALL=(ALL) NOPASSWD: ALL
```
The file should look as follows:
![step 9](/assets/img/install/virtual/virtual_step_09.png)
You can test that the changes took effect by running the command:
```
sudo ls
```
You should not be prompted to type in your password. If that worked, you can proceed to shutdown the VM by typing
```
sudo shutdown now
```

10. Now, we have an appropriately setup Ubuntu VM. We will use this for our template for the rest of our VMs.  Right-click the VM, and click "Clone."
![step 10](/assets/img/install/virtual/virtual_step_10.png)

11. Click "Continue" and check "Full Clone" and then "Clone." Repeat this step 5 times, giving each clone a new name.
![step 11](/assets/img/install/virtual/virtual_step_11.png)

12. Select all the clones (excluding the original VM), right-click, then click "Group." You may optionally change the name of the group by right-clicking the group and clicking "Rename Group..."
![step 12](/assets/img/install/virtual/virtual_step_12.png)

13. Click the group (name) or select all machines in the group, click the arrow below the green start arrow, and click "Headless Start."
![step 13](/assets/img/install/virtual/virtual_step_13.png)

14. Your group should look as follows:
![step 14](/assets/img/install/virtual/virtual_step_14.png)

The VMs are now ready for deployment.

[virtualbox_download]: https://www.virtualbox.org/wiki/Downloads
[ubuntu_download]: https://www.ubuntu.com/download/server
