#!/usr/bin/expect

set timeout 20

set cmd [lrange $argv 1 end]
set password [lindex $argv 0]

eval spawn $cmd
expect "assword:"
send "$password\r";
interact


# https://stackoverflow.com/questions/12202587/automatically-enter-ssh-password-with-script
