#!/usr/bin/expect

# TODO - This is not necessary, but it will be a small
# script that we can use to automate inserting password.
# If we can get this to work reliably, then we can use
# this script instead of sshpass - ultimately making the
# install process (from the sysadmin perspective) external
# dependency free. However, this does bound the sysadmin
# scripts to machines that support both bash and expect.
# NOTE - Mac, and Ubuntu both seem to support expect.

set timeout 20

set cmd [lrange $argv 1 end]
set password [lindex $argv 0]

eval spawn $cmd
expect "assword:"
send "$password\r";
interact


# https://stackoverflow.com/questions/12202587/automatically-enter-ssh-password-with-script
