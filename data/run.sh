#!/bin/bash
# Init borg-users .ssh/authorized_keys

BORG_DATA_DIR=/backup
BORG_CMD='cd ${BORG_DATA_DIR}/${client_name}; borg serve --append-only --restrict-to-path ${BORG_DATA_DIR}/${client_name}'
SSH_KEY_DIR=/sshkeys

# add all sshkeys to borg-user's authorized_keys & create repositories
echo "########################################################"
for dir in BORG_DATA_DIR SSH_KEY_DIR ; do
	dirpath=$(eval echo '$'$dir)
	echo "Testing Volume $dir: $dirpath"
	if [ ! -d "$dirpath" ] ; then
		echo " ERROR: $dirpath is no directory!"
		exit 1
	fi

	if [ $(find $SSH_KEY_DIR -type f | wc -l) == 0 ] ; then
		echo "ERROR: No SSH-Pubkey file found in $SSH_KEY_DIR"
		exit 1
	fi
done
echo "########################################################"

echo "Starting SSH-Key import..."
for keyfile in $(find $SSH_KEY_DIR -type f); do
    client_name=$(basename $keyfile)
    echo "Adding client ${client_name} with repo path ${BORG_DATA_DIR}/${client_name}"
    mkdir ${BORG_DATA_DIR}/${client_name} 2>/dev/null
    echo -n "command=\"$(eval echo -n \"$BORG_CMD\")\" " >> /home/borg/.ssh/authorized_keys
	cat $keyfile >> /home/borg/.ssh/authorized_keys
done

chown -R borg: /backup
chown borg: /home/borg/.ssh/authorized_keys
chmod 600 /home/borg/.ssh/authorized_keys

echo "Init done!"
echo "########################################################"
echo "Starting SSH-Daemon"

/usr/sbin/sshd -D -e
