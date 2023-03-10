#!/usr/bin/bash
set -eu

source "$BSYS6/exports/vars.sh"

if [ -z "${VERSION:-}" ]; then
  $BSYS6/utils/require.sh curl

  echo "-> Fetching version" >&2

  version="$(curl -fsS https://gitlab.com/librewolf-community/browser/source/-/raw/main/version)"
  release="$(curl -fsS https://gitlab.com/librewolf-community/browser/source/-/raw/main/release)"

  if [ "$version" == "" ] || [ "$release" == "" ]; then
    echo "Failed to fetch version from GitLab" >&2
    exit 1
  fi

  export VERSION="$version-$release"
fi

if [ -z "${SOURCEDIR:-}" ]; then
  export SOURCEDIR="$WORKDIR/librewolf-$VERSION"
fi
