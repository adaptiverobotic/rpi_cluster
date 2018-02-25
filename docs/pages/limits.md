# Application Limitations
This app is a proof of concept. So, naturally it will come with some limitations.
I will name some of the most prominent ones that I am aware of.

## Persistent Storage
One of my biggest design decisions was to go with a "dockerized" or "native" solution. I chose docker because docker allows for easier deployment and cleanup of applications and services. The biggest download to docker though is its limitations with storage. Docker thrives with stateless applications. However, most application (especially in the case of this application) have a sense of state. Since I do not plan to actually use this application to deploy servers that will contain meaningful data, I chose to go with the docker approach.

## Security
Throughout the development process, I accidentally locked my self out of all of my servers by simply forgetting to open port 22 (for ssh). So, I leave port 22 open just in case. I also leave password login enabled because I found difficulty properly rotating ssh keys without running into `Too many failed authentication attempts`.

## Passwords in plain text
For simplicity, I am not encrypting passwords. I am storing them in plain text, and using the same password for logins. This is obviously a huge security hole. But, I made this decision because I did not want to get bogged down with the technicalities of hashing and un-hashing passwords and managing many different sets of credentials. High security was not the main goal of this project, however I am conscious of it's importance.
