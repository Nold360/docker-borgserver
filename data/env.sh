# Default values for environment
PATH=$PATH:/usr/local/bin
PUID=${PUID:-1000}
PGID=${PGID:-1000}

# Append only mode?
BORG_APPEND_ONLY=${BORG_APPEND_ONLY:=no}

# Volume for backup repositories
BORG_DATA_DIR=${BORG_DATA_DIR:-/backup}

# Branch of KEY_GIT_URL
KEY_GIT_BRANCH=${KEY_GIT_BRANCH:-master}

# This will contain the host and client keys
SSH_KEY_DIR=${SSH_KEY_DIR:-/sshkeys}

### CAUTION
# This is more of a template then something you need to change, it should stay static
BORG_CMD='cd ${BORG_DATA_DIR}/${client_name}; borg serve --restrict-to-path ${BORG_DATA_DIR}/${client_name} ${BORG_SERVE_ARGS}'

# Path to authorized_keys file
AUTHORIZED_KEYS_PATH=${AUTHORIZED_KEYS_PATH:-/home/borg/.ssh/authorized_keys}
