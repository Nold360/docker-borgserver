#!/bin/bash

set -e

source env.sh

if [ -d "${SSH_KEY_DIR}/clients/.git" ] ; then
  cd "${SSH_KEY_DIR}/clients" || exit 0
  git fetch
  if ! git diff --quiet remotes/origin/HEAD; then
    echo "Pull from git repository"
    git pull
    create-client-dirs.sh
  else
    echo "$0: Nothing to do"
  fi
fi
