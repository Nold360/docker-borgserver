#!/bin/bash
# Start Script for docker-borgserver

PUID=${PUID:-1000}
PGID=${PGID:-1000}

usermod -o -u "$PUID" borg &>/dev/null
groupmod -o -g "$PGID" borg &>/dev/null

BORG_DATA_DIR=${BORG_DATA_DIR:-/backup}
SSH_KEY_DIR=${SSH_KEY_DIR:-/sshkeys}
BORG_CMD='cd ${BORG_DATA_DIR}/${client_name}; borg serve --restrict-to-path ${BORG_DATA_DIR}/${client_name} ${BORG_SERVE_ARGS}'
AUTHORIZED_KEYS_PATH=/home/borg/.ssh/authorized_keys

# Append only mode?
BORG_APPEND_ONLY=${BORG_APPEND_ONLY:=no}

echo "########################################################"
echo " * Docker BorgServer powered by $(borg -V)"
echo "########################################################"
echo " * $(id)"
echo "########################################################"

echo -n "Waiting for init-container to finish..."
sleep 5
while ping -c2 init >/dev/null 2>/dev/null ; do
  echo .
  sleep 3
done
echo " done"

# Precheck if BORG_ADMIN is set
if [ "${BORG_APPEND_ONLY}" == "yes" ] && [ -z "${BORG_ADMIN}" ] ; then
  echo "WARNING: BORG_APPEND_ONLY is active, but no BORG_ADMIN was specified!"
fi

# Precheck directories & client ssh-keys
for dir in BORG_DATA_DIR SSH_KEY_DIR ; do
  dirpath=$(eval echo '$'${dir})
  echo " * Testing Volume ${dir}: ${dirpath}"
  if [ ! -d "${dirpath}" ] ; then
    echo " ! ERROR: ${dirpath} is no directory!"
    exit 1
  fi
done

for keytype in ed25519 rsa ; do
  if [ ! -f "${SSH_KEY_DIR}/ssh_host_${keytype}_key" ] ; then
    echo " ! WARNING: SSH-Host-Key $keytype doesn't exist!"
    continue
  fi
done

echo "########################################################"
echo " * Checking authorized_keys file..."
# Check if authorzied_keys is valid
if ! ssh-keygen -lf ${AUTHORIZED_KEYS_PATH} >/dev/null; then
  echo " ! ERROR: '${AUTHORIZED_KEYS_PATH}' is not a valid authorized_keys-file."
  exit 1
fi

echo "########################################################"
echo " * Init done! Starting SSH-Daemon..."
/usr/sbin/sshd -D -e
