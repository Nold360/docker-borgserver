# BorgServer - Docker image
Debian based container image, running openssh-daemon only accessable by user named "borg" using SSH-Publickey Auth & "borgbackup" as client. Backup-Repositoriees, client's SSH-Keys & SSHd's Hostkeys will be stored in persistent storage.
For every ssh-key added, a own borg-repository will be created.

**NOTE: I will assume that you know, what a ssh-key is and how to generate & use it. If not, you might want to start here: [Arch Wiki](https://wiki.archlinux.org/index.php/SSH_Keys)**

## Quick Example
Here is a quick example how to configure & run this image:

### Create persistent sshkey storage
```
 $ mkdir -p borg/sshkeys/clients
```

Make sure that the permissions are right on the sshkey folder:
```
 $ chown 1000:1000 borg/sshkeys
```

### (Generate &) Copy every client's ssh publickey into persistent storage
*Remember*: Filename = Borg-repository name!
```
 $ cp ~/.ssh/my_machine.pub borg/sshkeys/clients/my_machine
```

The OpenSSH-Deamon will expose on port 22/tcp - so you will most likely want to redirect it to a different port. Like in this example:
```
docker run -td \
	-p 2222:22  \
	--volume ./borg/sshkeys:/sshkeys \
	--volume ./borg/backup:/backup \
	nold360/borgserver:latest
```


## Borgserver Configuration
 * Place Borg-Clients SSH-PublicKeys in persistent storage
 * Client backup-directories will be named by the filename found in /sshkeys/clients/

### Environment Variables
#### BORG_SERVE_ARGS
Use this variable if you want to set special options for the "borg serve"-command, which is used internally.

See the the documentation for all available arguments: [borgbackup.readthedocs.io](https://borgbackup.readthedocs.io/en/stable/usage.html#borg-serve)

##### Example
```
docker run --rm -e BORG_SERVE_ARGS="--progress --debug" (...) nold360/borgserver
```

#### BORG_APPEND_ONLY
If you want your client to be only able to append & not prune anything from their repo, set this variable to **"yes"**.


#### BORG_ADMIN
When *BORG_APPEND_ONLY* is active, no client is able to prune it's repo. 
Since you might want to cleanup the repos at some point, you can declare one client to be the borg "admin".

This client will have **full access to all repos of any client!** So he's able to add/prune/... what ever he wants.

To declare a client as admin, set this variable to the name of the client/sshkey you've added to the /sshkeys/clients directory.

##### Example
```
docker run --rm -e BORG_APPEND_ONLY="yes" -e BORG_ADMIN="nolds_notebook" (...) nold360/borgserver
```

To prune repos from another client, you have to add the path to the repository in the clients directory:
```
borg prune --keep-last 100 --keep-weekly 1 (...) borgserver:/clientA/clientA
```


### Persistent Storages & Client Configuration
We will need two persistent storage directories for our borgserver to be usefull.

#### /sshkeys
This directory has two subdirectories:

##### /sshkeys/clients/
Here we will put all SSH public keys from our borg clients, we want to backup. Every key must be it's own file, containing only one line, with the key. The name of the file will become the name of the borg repository, we need for our client to connect.

That means every client get's it's own repository. So you might want to use the hostname of the client as the name of the sshkey file.

```
F.e. /sshkeys/clients/webserver.mydomain.com
```

Than your client would have to initiat the borg repository like this:
```
webserver.mydomain.com ~$ borg init ssh://borg@borgserver-container/backup/webserver.mydomain.com/my_first_repo
```

**!IMPORTANT!**: The container wouldn't start the SSH-Deamon until there is at least one ssh-keyfile in this directory!

##### /sshkeys/host/
This directory will be automaticly created on first start. Also run.sh will copy the SSH-Hostkeys here, so your clients can verify it's borgservers ssh-hostkey.

#### /backup
In this directory will borg write all the client data to. It's best to start with an empty directory.


## Example Setup
### docker-compose.yml
Here is a quick example, how to run borgserver using docker-compose:
```
services:
 borgserver:
  image: nold360/borgserver
  volumes:
   - /backup:/backup
   - ./sshkeys:/sshkeys
  ports:
   - "2222:22"
  environment:
   BORG_SERVE_ARGS: ""
   BORG_APPEND_ONLY: "no"
   BORG_ADMIN: ""
```

### ~/.ssh/config for clients
With this configuration (on your borg client) you can easily connect to your borgserver.
```
Host backup
	Hostname my.docker.host
	Port 2222
	User borg
```

Now initiate a borg-repository like this:
```
 $ borg init backup:my_first_borg_repo
```

And create your first backup!
```
 $ borg create backup:my_first_borg_repo::documents-2017-11-01 /home/user/MyImportentDocs
```
