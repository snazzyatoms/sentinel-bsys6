#!/usr/bin/env bash
set -eu

if [ "$#" -ne 2 ]; then
  echo 'Usage: download_dl.sh <name> <target_file>'
  echo '  Resolves the latest stable release of the $FORGE_REPO_OWNER/<name> repo (case-insensitive) and downloads'
  echo '  https://dl.librewolf.net/librewolf-<name>/<tag>/LibreWolf-<Name>_<tag>.zip'
  exit 1
fi

repo="$(echo "$1" | tr '[:upper:]' '[:lower:]')"

version="$(curl -fsSA "" "$FORGE_URL/api/v1/repos/$FORGE_REPO_OWNER/$repo/releases/latest" | jq -re '.tag_name' | sed 's/^v//')"
if [ -z "${version:-}" ]; then
  echo "Failed to fetch the latest release of '$FORGE_REPO_OWNER/$repo' from $FORGE_URL" >&2
  exit 1
fi

$BSYS6/utils/download.sh "https://dl.librewolf.net/librewolf-$repo/$version/LibreWolf-${1}_$version.zip" "$2"
