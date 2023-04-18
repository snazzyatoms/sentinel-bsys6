#!/usr/bin/bash
set -eu

$BSYS6/utils/require_command.sh curl
$BSYS6/exports/vars.sh # for $WORKDIR

echo "-> Fetching version" >&2

version="$(curl -fS https://gitlab.com/librewolf-community/browser/source/-/raw/main/version)"
release="$(curl -fS https://gitlab.com/librewolf-community/browser/source/-/raw/main/release)"

if [ "$version" == "" ] || [ "$release" == "" ]; then
  echo "Failed to fetch version from GitLab" >&2
  exit 1
fi

export VERSION="$version-$release"
echo "Version is $VERSION, caching as the default version for 12 hours" >&2
echo "$VERSION" >$WORKDIR/version
