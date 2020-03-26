#!/bin/bash
# This script generates the authorized_keys file from SSH_KEY_DIR
# authorized_keys will only get overridden after syntax check
set -e
source env.sh

TMPFILE=$(mktemp)

echo "######################################################"
echo "* Regenerate borgserver authorized_keys *"
echo "######################################################"

# Add every key to borg-users authorized_keys
for keyfile in $(find "${SSH_KEY_DIR}/clients" ! -regex '.*/\..*' -a -type f); do
  client_name=$(basename ${keyfile})

	# Only import valid keyfiles, skip other files
  if ! ssh-keygen -lf $keyfile >/dev/null ; then
		echo " Warning: Skipping invalid ssh-key file '$keyfile'"
		continue
	fi

  if [ ! -d "${BORG_DATA_DIR}/${client_name}" ]; then
    echo "  ** Adding client ${client_name} with repo path ${BORG_DATA_DIR}/${client_name}"
    mkdir "${BORG_DATA_DIR}/${client_name}"
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

  echo -n "command=\"$(eval echo -n \"${borg_cmd}\")\" " >> ${TMPFILE}
  cat ${keyfile} >> ${TMPFILE}
done

# Due to `set -e` the script will end here on failure anyways
echo " * Validating structure of generated ${AUTHORIZED_KEYS_PATH}..."
ssh-keygen -lf ${TMPFILE} >/dev/null

mv ${TMPFILE} ${AUTHORIZED_KEYS_PATH}
echo " ** Success"

chown -R borg:borg ${BORG_DATA_DIR}
chown borg:borg ${AUTHORIZED_KEYS_PATH}
chmod 600 ${AUTHORIZED_KEYS_PATH}

exit 0
