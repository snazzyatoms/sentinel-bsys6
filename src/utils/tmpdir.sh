#!/usr/bin/bash
set -eu

source "$BSYS6/utils/vars.sh"

export TMPDIR="$WORKDIR/tmp$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 10)"
mkdir -p "$TMPDIR"
