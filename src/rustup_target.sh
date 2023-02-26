#!/usr/bin/bash
set -e

PATH="$HOME/.cargo/bin:$PATH"

source $BSYS6/require.sh rustup

while [[ $# -gt 0 ]]; do
  echo "-> Adding rustup target $1"
  rustup target add "$1"
  shift
done
