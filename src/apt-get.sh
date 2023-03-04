#!/usr/bin/bash
set -eu

source $BSYS6/require.sh apt-get

if [ "$#" -eq 0 ]; then
  echo "apt-get.sh: At least one argument is required"
  exit 1
fi

if ! command -v sudo >/dev/null; then
  apt-get update
  apt-get install -y sudo
else
  sudo apt-get update
fi

echo "-> Installing $@ with apt-get"
sudo apt-get install -y $@
