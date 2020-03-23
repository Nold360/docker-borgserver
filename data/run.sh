#!/bin/bash
# Start Script for docker-borgserver

set -e

PUID=${PUID:-1000}
PGID=${PGID:-1000}

usermod -o -u "$PUID" borg &>/dev/null
groupmod -o -g "$PGID" borg &>/dev/null

#source variables
source env.sh

echo "########################################################"
echo -n " * Docker BorgServer powered by "
borg -V
echo "########################################################"
echo " * User  id: $(id -u borg)"
echo " * Group id: $(id -g borg)"
if [ -z "${BORG_SSHKEYS_REPO}" ] ; then
  echo "* Pulling keys from ${BORG_SSHKEYS_REPO}"
fi
echo "########################################################"


# Precheck if BORG_ADMIN is set
if [ "${BORG_APPEND_ONLY}" == "yes" ] && [ -z "${BORG_ADMIN}" ] ; then
	echo "WARNING: BORG_APPEND_ONLY is active, but no BORG_ADMIN was specified!"
fi

# Init the ssh keys directory from a remote git repository
if [ ! -z "${BORG_SSHKEYS_REPO}" ] ; then
  if [ ! -d ${SSH_KEY_DIR}/clients ] ; then
    git clone "${BORG_SSHKEYS_REPO}" ${SSH_KEY_DIR}/clients
  else
     /usr/local/bin/update-ssh-keys.sh ${SSH_KEY_DIR}
  fi
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
create-client-dirs.sh \
  "${SSH_KEY_DIR}" \
  "${BORG_DATA_DIR}" \
  "${AUTHORIZED_KEYS_PATH}" \
  "${BORG_CMD}" \
  "${BORG_APPEND_ONLY}"

echo "########################################################"
echo " * Init done! Starting SSH-Daemon..."

/usr/sbin/sshd -D -e
