#!/usr/bin/bash
set -eu

$BSYS6/utils/require.sh pacman

if ! command -v sudo >/dev/null; then
  pacman -Syu sudo
else
  echo "# sudo pacman -Syu"
  sudo pacman -Syu
fi

echo "-> Installing $@ dependencies with pacman"
echo "# sudo pacman -S --needed $@"
sudo pacman -S --needed $@
