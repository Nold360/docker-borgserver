#!/bin/bash
# Init borg-users .ssh/authorized_keys

BORG_DATA_DIR=/backup
BORG_CMD='cd ${BORG_DATA_DIR}/${client_name}; borg serve --restrict-to-path ${BORG_DATA_DIR}/${client_name}'
SSH_KEY_DIR=/sshkeys

# Parse environment
if [ ! -z "${BORG_SERVE_ARGS}" ] ; then
	BORG_CMD="${BORG_CMD} ${BORG_SERVE_ARGS}"
fi

# add all sshkeys to borg-user's authorized_keys & create repositories
echo "########################################################"
for dir in BORG_DATA_DIR SSH_KEY_DIR ; do
	dirpath=$(eval echo '$'$dir)
	echo " * Testing Volume $dir: $dirpath"
	if [ ! -d "$dirpath" ] ; then
		echo "ERROR: $dirpath is no directory!"
		exit 1
	fi

	if [ $(find "${SSH_KEY_DIR}/clients" -type f | wc -l) == 0 ] ; then
		echo "ERROR: No SSH-Pubkey file found in $SSH_KEY_DIR"
		exit 1
	fi
done

# (Create &) Copy SSH-Host-Keys to persistent storage
mkdir -p ${SSH_KEY_DIR}/host 2>/dev/null
echo " * Checking / Preparing SSH Host-Keys..."

if [ ! -f /etc/ssh/ssh_host_rsa_key ] ; then
	echo "  ** Creating SSH Hostkeys..."
	for keytype in ed25519 rsa ; do
		ssh-keygen -q -f "/etc/ssh/ssh_host_${keytype}_key" -N '' -t $keytype
	done
fi

for keyfile in ssh_host_rsa_key ssh_host_ed25519_key ; do
	if [ ! -f "${SSH_KEY_DIR}/host/${keyfile}" ] ; then
		cp /etc/ssh/${keyfile} "${SSH_KEY_DIR}/host/${keyfile}"
	fi
done
echo "########################################################"

echo " * Starting SSH-Key import..."
rm /home/borg/.ssh/authorized_keys &>/dev/null
for keyfile in $(find "${SSH_KEY_DIR}/clients" -type f); do
    client_name=$(basename $keyfile)
    echo "  ** Adding client ${client_name} with repo path ${BORG_DATA_DIR}/${client_name}"
    mkdir ${BORG_DATA_DIR}/${client_name} 2>/dev/null
    echo -n "command=\"$(eval echo -n \"${BORG_CMD}\")\" " >> /home/borg/.ssh/authorized_keys
	cat $keyfile >> /home/borg/.ssh/authorized_keys
done

chown -R borg: /backup
chown borg: /home/borg/.ssh/authorized_keys
chmod 600 /home/borg/.ssh/authorized_keys

echo " * Init done!"
echo "########################################################"
echo " * Starting SSH-Daemon"

/usr/sbin/sshd -D -e
