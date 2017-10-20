# BorgServer - Docker image
Debian based container image, running openssh-daemon only accessable by user named "borg" using SSH-Publickey Auth & "borgbackup" as client. Backup-Repositoriees, client's SSH-Keys & SSHd's Hostkeys will be stored in persistent storage.

## Borgserver Configuration
 * Place Borg-Clients SSH-PublicKeys in persistent storage 
 * Client Repositories will be named by the filename found in /sshkeys/clients/

### Persistent Storages & Client Configuration
We will need two persistent storage directories for our borgserver to be usefull:

#### /sshkeys 
This directory has two subdirectories:
##### /sshkeys/clients/
Here we will put all SSH public keys from our borg clients, we want to backup. Every key must be it's own file, containing only one line, with the key. The name of the file will become the name of the borg repository, we need for our client to connect. 

That means every client get's it's own repository. So you might want to use the hostname of the client as the name of the sshkey file. 

```
F.e. /sshkeys/webserver.mydomain.com
```

Than your client would have to initiat the borg repository like this:
```
webserver.mydomain.com ~$ borg init ssh://borg@borgserver-container/backup/webserver.mydomain.com
```

!IMPORTANT!: The container wouldn't start the SSH-Deamon until there is at least one ssh-keyfile in this directory!

##### /sshkeys/host/
This directory will be automaticly created on first start. Also run.sh will copy the SSH-Hostkeys here, so your clients can verify it's borgservers ssh-hostkey.

#### /backup
In this directory will borg write all the client data to. It's best to start with an empty directory.

### Example
Here is a quick example how to run this image:
