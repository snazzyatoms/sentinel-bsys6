#!/usr/bin/bash
set -eu

if [ "$#" -ne 2 ]; then
  echo 'Usage: dependencies.sh "<apt_dependencies>" "<pacman_dependencies>"'
  exit 1
fi

if command -v apt-get >/dev/null; then
  $BSYS6/apt-get.sh $1
  return
fi

if command -v pacman >/dev/null; then
  $BSYS6/pacman.sh $2
  return
fi

echo "No supported package manager found. Alternatives for the following apt packages need to be installed:"
echo "$1"
