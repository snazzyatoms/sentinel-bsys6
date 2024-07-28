#!/usr/bin/env bash
set -eu

if ! command -v pip3 &>/dev/null; then
  echo "-> Installing pip" >&2
  $BSYS6/utils/dependencies.sh "python3-pip" "python-pip"
fi

echo "-> Installing $@ with pip" >&2
pip3 install --break-system-packages $@
