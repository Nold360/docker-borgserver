#!/bin/bash
# Start Script for docker-borgserver

BORG_DATA_DIR=/backup
SSH_KEY_DIR=/sshkeys
BORG_CMD='cd ${BORG_DATA_DIR}/${client_name}; borg serve --restrict-to-path ${BORG_DATA_DIR}/${client_name} ${BORG_SERVE_ARGS}'

# Append only mode?
BORG_APPEND_ONLY=${BORG_APPEND_ONLY:=no}

echo "########################################################"
echo -n " * Docker BorgServer powered by "
borg -V
echo "########################################################"

# Precheck if BORG_ADMIN is set
if [ "${BORG_APPEND_ONLY}" == "yes" ] && [ -z "${BORG_ADMIN}" ] ; then
	echo "WARNING: BORG_APPEND_ONLY is active, but no BORG_ADMIN was specified!"
fi

# Precheck directories & client ssh-keys
for dir in BORG_DATA_DIR SSH_KEY_DIR ; do
	dirpath=$(eval echo '$'${dir})
	echo " * Testing Volume ${dir}: ${dirpath}"
	if [ ! -d "${dirpath}" ] ; then
		echo "ERROR: ${dirpath} is no directory!"
		exit 1
	fi

	if [ "$(find ${SSH_KEY_DIR}/clients ! -regex '.*/\..*' -a -type f | wc -l)" == "0" ] ; then
		echo "ERROR: No SSH-Pubkey file found in ${SSH_KEY_DIR}"
		exit 1
	fi
done

# Create SSH-Host-Keys on persistent storage, if not exist
mkdir -p ${SSH_KEY_DIR}/host 2>/dev/null
echo " * Checking / Preparing SSH Host-Keys..."
for keytype in ed25519 rsa ; do
	if [ ! -f "${SSH_KEY_DIR}/host/ssh_host_${keytype}_key" ] ; then
		echo "  ** Creating SSH Hostkey [${keytype}]..."
		ssh-keygen -q -f "${SSH_KEY_DIR}/host/ssh_host_${keytype}_key" -N '' -t ${keytype}
	fi
done

echo "########################################################"
echo " * Starting SSH-Key import..."

# Add every key to borg-users authorized_keys
rm /home/borg/.ssh/authorized_keys &>/dev/null
for keyfile in $(find "${SSH_KEY_DIR}/clients" ! -regex '.*/\..*' -a -type f); do
    client_name=$(basename ${keyfile})
    mkdir ${BORG_DATA_DIR}/${client_name} 2>/dev/null
    echo "  ** Adding client ${client_name} with repo path ${BORG_DATA_DIR}/${client_name}"

	# If client is $BORG_ADMIN unset $client_name, so path restriction equals $BORG_DATA_DIR
	# Otherwise add --append-only, if enabled
	borg_cmd=${BORG_CMD}
	if [ "${client_name}" == "${BORG_ADMIN}" ] ; then
		echo "   ** Client '${client_name}' is BORG_ADMIN! **"
		unset client_name
	elif [ "${BORG_APPEND_ONLY}" == "yes" ] ; then
		borg_cmd="${BORG_CMD} --append-only"
	fi

    echo -n "command=\"$(eval echo -n \"${borg_cmd}\")\" " >> /home/borg/.ssh/authorized_keys
	cat ${keyfile} >> /home/borg/.ssh/authorized_keys
done

chown -R borg: /backup
chown borg: /home/borg/.ssh/authorized_keys
chmod 600 /home/borg/.ssh/authorized_keys

echo "########################################################"
echo " * Init done! Starting SSH-Daemon..."

/usr/sbin/sshd -D -e
