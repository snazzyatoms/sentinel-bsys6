#!/usr/bin/bash
set -eu

if command -v apt-get >/dev/null; then
  $BSYS6/apt-get.sh python3-pip curl
  return
fi

if command -v pacman >/dev/null; then
  $BSYS6/apt-get.sh python-pip curl
  return
fi

echo "No supported package manager found."
exit 1
