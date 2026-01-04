#!/usr/bin/env bash
set -eu

$BSYS6/utils/require_command.sh curl
$BSYS6/exports/vars.sh # for $WORKDIR

echo "-> Fetching version" >&2

export VERSION="$(curl 'https://codeberg.org/api/v1/repos/librewolf/source/tags?limit=1' | jq -r '.[0].name' | sed 's/^v//')"

if [ "$VERSION" == "" ]; then
  echo "Failed to fetch version from Codeberg" >&2
  exit 1
fi

echo "Version is $VERSION, caching as the default version for 12 hours" >&2
echo "$VERSION" >$WORKDIR/version
