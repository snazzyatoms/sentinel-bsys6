#!/usr/bin/bash
set -eu

source $BSYS6/require.sh pacman

if ! command -v sudo >/dev/null; then
  pacman -Syu sudo
else
  pacman -Syu
fi

echo "-> Installing bsys6 dependencies with pacman"
sudo pacman -S python-pip curl msitools zstd
