#!/usr/bin/bash
set -e -o pipefail

PATH="$HOME/.cargo/bin:$PATH"

source $BSYS6/require.sh cargo

while [[ $# -gt 0 ]]; do
  echo "-> Installing $1 with cargo"
  cargo install "$1"
  shift
done
