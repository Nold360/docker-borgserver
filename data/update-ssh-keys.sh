#!/bin/bash
# This script updates the authorized_keys file
# Will clone/pull ssh-pubkeys from GIT_KEY_URL if set
set -e
source env.sh

if [ -d "${SSH_KEY_DIR}/clients/.git" ] ; then
  git -C "${SSH_KEY_DIR}/clients" fetch
  if ! git -C "${SSH_KEY_DIR}/clients" diff --quiet remotes/origin/HEAD; then
    echo "Pull from git repository"
    git -C "${SSH_KEY_DIR}/clients" pull
    create-client-dirs.sh
  else
    echo "$0: Nothing to do"
  fi
elif [ ! -z "${KEY_GIT_URL}" ] ; then
	git clone --depth=1 -b ${KEY_GIT_BRANCH} ${KEY_GIT_URL} ${SSH_KEY_DIR}/clients
fi

exit 0
