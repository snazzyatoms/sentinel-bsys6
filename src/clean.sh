#!/usr/bin/bash
set -e

source "$BSYS6/utils/vars.sh"

echo "-> Cleaning up auxiliary files" >&2
rm -rf "$WORKDIR"
