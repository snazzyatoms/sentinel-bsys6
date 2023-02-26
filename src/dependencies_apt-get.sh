#!/usr/bin/bash
set -eu

source $BSYS6/require.sh apt-get

if ! command -v sudo >/dev/null; then
  apt-get update && apt-get install -y sudo
else
  sudo apt-get update
fi

sudo apt-get install -y python3-pip curl
