#!/usr/bin/bash
set -eu

source "$BSYS6/exports/vars.sh"

if [ -z "${VERSION:-}" ]; then
  if find "$WORKDIR/version" -mmin +720 >/dev/null 2>/dev/null; then
    export VERSION="$(cat "$WORKDIR/version")"
  else
    source "$BSYS6/update.sh"
  fi
fi

if [ -z "${SOURCEDIR:-}" ]; then
  export SOURCEDIR="$WORKDIR/librewolf-$VERSION"
fi

if [ -n "${RELEASE}" ] && [ "$RELEASE" != "1" ]; then
  export FULL_VERSION="$VERSION-$RELEASE"
else
  export RELEASE="1"
  export FULL_VERSION="$VERSION"
fi
