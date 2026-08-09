#!/usr/bin/env bash
set -eu

if [ "$#" -ne 3 ]; then
  echo 'Usage: download_forge.sh <repo> <regex> <target_file>'
  exit 1
fi

echo "'$FORGE_URL/api/v1/repos/$1/releases/latest'"
url="$(curl -fA "" "$FORGE_URL/api/v1/repos/$1/releases/latest" | jq -re ".assets[] | select(.name | match(\"$2\")).browser_download_url")"
if [ -z "${url:-}" ] || [ "$url" == "" ]; then
  echo "No url found for '$2' in '$1'"
  exit 1
fi
$BSYS6/utils/download.sh "$url" "$3"
