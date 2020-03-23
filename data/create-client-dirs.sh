#!/bin/bash

set -e

source env.sh

function error_exit {
    echo
    echo "$@"
    if [ -e "${AUTHORIZED_KEYS_PATH}.bkp" ]; then
      echo "Restore authorized_keys backup ${AUTHORIZED_KEYS_PATH}.bkp"
      mv "${AUTHORIZED_KEYS_PATH}.bkp" "${AUTHORIZED_KEYS_PATH}"
    fi
    exit 1
}

#Trap the killer signals so that we can exit with a good message.
trap "error_exit 'Received signal SIGHUP'" SIGHUP
trap "error_exit 'Received signal SIGINT'" SIGINT
trap "error_exit 'Received signal SIGTERM'" SIGTERM

echo "######################################################"
echo "* Regenerate borgserver authorized_keys *"
echo "######################################################"

if [ -e "${AUTHORIZED_KEYS_PATH}" ]; then
  cp "${AUTHORIZED_KEYS_PATH}" "${AUTHORIZED_KEYS_PATH}.bkp"
  rm "${AUTHORIZED_KEYS_PATH}"
fi

# Add every key to borg-users authorized_keys
for keyfile in $(find "${SSH_KEY_DIR}/clients" ! -regex '.*/\..*' -a -type f); do
  client_name=$(basename ${keyfile})
  echo "Add $client_name ssh key"
  if [ ! -d "${BORG_DATA_DIR}/${client_name}" ]; then
    mkdir "${BORG_DATA_DIR}/${client_name}" #2>/dev/null
    echo "  ** Adding client ${client_name} with repo path ${BORG_DATA_DIR}/${client_name}"
  else
    echo "Directory ${BORG_DATA_DIR}/${client_name} exists: Nothing to do"
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

echo " * Validating structure of generated ${AUTHORIZED_KEYS_PATH}..."
ERROR=$(ssh-keygen -lf ${AUTHORIZED_KEYS_PATH} 2>&1 >/dev/null)
if [ $? -ne 0 ]; then
    echo "ERROR: ${ERROR}"
    exit 1
fi

chown -R borg:borg ${BORG_DATA_DIR}
chown borg:borg ${AUTHORIZED_KEYS_PATH}
chmod 600 ${AUTHORIZED_KEYS_PATH}
rm -f ${AUTHORIZED_KEYS_PATH}.bkp
