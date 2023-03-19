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

if [ -z "${FULL_VERSION:-}" ]; then
  if [ -n "${RELEASE:-}" ] && [ "$RELEASE" != "1" ]; then
    export FULL_VERSION="$VERSION-$RELEASE"
  else
    export RELEASE="1"
    export FULL_VERSION="$VERSION"
  fi
fi

if [ -z "${CHOCO_VERSION:-}" ]; then
  ver=$(echo "$VERSION" | sed 's/-.*$//g')
  rel=$(echo "$VERSION" | sed 's/^.*-//g')
  export CHOCO_VERSION="$ver$(echo $(for i in $(seq $(echo "$ver" | tr -cd '.' | wc -c) 1); do printf ".0"; done)).$rel"
fi
