BORG_DATA_DIR=/backup
SSH_KEY_DIR=/sshkeys
BORG_CMD='cd ${BORG_DATA_DIR}/${client_name}; borg serve --restrict-to-path ${BORG_DATA_DIR}/${client_name} ${BORG_SERVE_ARGS}'
AUTHORIZED_KEYS_PATH=/home/borg/.ssh/authorized_keys

# Append only mode?
BORG_APPEND_ONLY=${BORG_APPEND_ONLY:=no}

export BORG_DATA_DIR SSH_KEY_DIR BORG_CMD AUTHORIZED_KEYS_PATH BORG_APPEND_ONLY
