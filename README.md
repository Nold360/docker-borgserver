BorgServer - Docker image
======


Borgserver Configuration
=====
 - Place SSH PublicKeys in persistent storage 
 - Client Repositories will be named by the filename found in /sshkeys


Persistent Storages & Client Configuration
====
We will need two persistent storage directories for our borgserver to be usefull:

/sshkeys 
===
Here we will put all SSH public keys from our borg clients, we want to backup. Every key must be it's own file, containing only one line, with the key. The name of the file will become the name of the borg repository, we need for our client to connect. 

That means every client get's it's own repository. So you might want to use the hostname of the client as the name of the sshkey file. 

F.e. /sshkeys/webserver.mydomain.com

Than your client would have to initiat the borg repository like this:
webserver.mydomain.com ~$ borg init ssh://borg@borgserver-container/backup/$(hostname -f)

!IMPORTANT!: The container wouldn't start the SSH-Deamon until there is at least one ssh-keyfile in this directory!

/backup
===
In this directory will borg write all the client data to. It's best to start with an empty directory.
