#!/bin/bash
# Init-Start Script for docker-borgserver
# Will pull ssh-keys from git specified via KEY_GIT_URL and KEY_GIT_BRANCH [default: master]
# and merge them into a single [openssh] authorized_keys file.
PUID=${PUID:-1000}
PGID=${PGID:-1000}

usermod -o -u "$PUID" borg &>/dev/null
groupmod -o -g "$PGID" borg &>/dev/null

# FIXME: Is this changeable? guess it should be.. should move it to some kind of
# build-env file
BORG_DATA_DIR=${BORG_DATA_DIR:-/backup}

BORG_CMD='cd ${BORG_DATA_DIR}/${client_name}; borg serve --restrict-to-path ${BORG_DATA_DIR}/${client_name} ${BORG_SERVE_ARGS}'
KEY_GIT_BRANCH=${KEY_GIT_BRANCH:-master}

# This is the path where the final authorized_keys will be written:
AUTHORIZED_KEYS_PATH=${AUTHORIZED_KEYS_PATH:-/home/borg/.ssh/authorized_keys}

# This will only contain host-keys now
SSH_KEY_DIR=${SSH_KEY_DIR:-/sshkeys}

# This is no volume anymore, only temporary during init
GIT_KEY_DIR=/tmp/gitkeys
echo "########################################################"
echo " * Docker BorgServer | Git Init-Container *"
echo " * $(id)"

if [ ! -z "${KEY_GIT_URL}" ] ; then
  # FIXME: Should the container die here, in case of error?
  # To workaround the limitations of docker-compose we could just loop here like.. forever

  # INFO: simle git clone would be enouth, but you can also use a volume for SSH_KEY_DIR if you like
  echo " * Cloning '${KEY_GIT_URL}' into '${GIT_KEY_DIR}/clients'"
  if [ ! -d "${GIT_KEY_DIR}/clients/.git" ] ; then
    git clone -b ${KEY_GIT_BRANCH} --depth=1 "${KEY_GIT_URL}" "${GIT_KEY_DIR}/clients"
  else
    git -C "${GIT_KEY_DIR}/clients" pull
  fi
else
  echo " ! FATAL ERROR: KEY_GIT_URL is not set! Can't continue."
  exit 1
fi

if [ "$(find ${GIT_KEY_DIR}/clients ! -regex '.*/\..*' -a -type f | wc -l)" == "0" ] ; then
  echo " ! FATAL ERROR: No SSH-Pubkey file found in ${GIT_KEY_DIR}. Can't continue."
  exit 2
fi

# Create SSH-Host-Keys on persistent storage, if not exist
# This also means that `${SSH_KEY_DIR}` has to be a shared volume
echo " * Checking / Preparing SSH Host-Keys..."
for keytype in ed25519 rsa ; do
  if [ ! -f "${SSH_KEY_DIR}/ssh_host_${keytype}_key" ] ; then
    echo "  ** Creating SSH Hostkey [${keytype}]..."
    ssh-keygen -q -f "${SSH_KEY_DIR}/ssh_host_${keytype}_key" -N '' -t ${keytype}
  fi
done

echo "########################################################"
echo " * Starting SSH-Key import..."

# Add every key to borg-users authorized_keys
# FIXME: mkdir of filestructure must still be done by server-container
# since we shouldn't have access to the backup-data volume in init
rm -f ${AUTHORIZED_KEYS_PATH} &>/dev/null
for keyfile in $(find "${GIT_KEY_DIR}" ! -regex '.*/\..*' -a -type f); do
  client_name=$(basename ${keyfile})

  # check if file is a valid openssh public key
  if ! ssh-keygen -lf $keyfile &>/dev/null ; then
    echo " ! WARNING: '$keyfile' is not a valid [open]ssh-public-key. Will continue anyway."
    continue
  fi

  # If client is $BORG_ADMIN unset $client_name, so path restriction equals $BORG_DATA_DIR
  # Otherwise add --append-only, if enabled
  borg_cmd=${BORG_CMD}
  if [ "${client_name}" == "${BORG_ADMIN}" ] ; then
    echo "   ** Client '${client_name}' is BORG_ADMIN! **"
    unset client_name
  elif [ "${BORG_APPEND_ONLY}" == "yes" ] ; then
    borg_cmd="${BORG_CMD} --append-only"
  fi

  echo -n "command=\"$(eval echo -n \"${borg_cmd}\")\" " >> ${AUTHORIZED_KEYS_PATH}
  cat ${keyfile} >> ${AUTHORIZED_KEYS_PATH}
done

# This will also fail if there wasn't a single valid pubkey found
echo " * Validating structure of generated ${AUTHORIZED_KEYS_PATH}..."
if ! ssh-keygen -lf ${AUTHORIZED_KEYS_PATH} >/dev/null ; then
  echo " ! FATAL ERROR: ${AUTHORIZED_KEYS_PATH} is no valid authorized_keys file. Can't continue."
  exit 3
fi

echo " * Correcting Permissions..."
chown borg:borg ${AUTHORIZED_KEYS_PATH}
chown -R borg:borg ${SSH_KEY_DIR}/*
chown borg:borg ${BORG_DATA_DIR}
chmod 600 ${AUTHORIZED_KEYS_PATH}

echo "########################################################"
echo " * Init done! Ready to fire up your borgserver!"

exit 0
