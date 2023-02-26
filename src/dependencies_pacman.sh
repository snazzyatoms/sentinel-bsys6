#!/usr/bin/bash
set -eu

source $BSYS6/require.sh pacman

if ! command -v sudo >/dev/null; then
  pacman -Syu sudo
else
  pacman -Syu
fi

sudo pacman -S python-pip curl
