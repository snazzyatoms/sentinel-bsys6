#!/usr/bin/bash
set -e

source "$BSYS6/exports/vars.sh"

echo "-> Cleaning up auxiliary files" >&2
rm -rf "$WORKDIR"
