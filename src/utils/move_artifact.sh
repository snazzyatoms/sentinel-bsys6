#!/usr/bin/bash
set -eu

if [ "$#" -ne 3 ]; then
  echo "Usage: move_artifact.sh <artifact_name> <directory> <file_regex>" >&2
  exit 1
fi

source "$BSYS6/utils/vars.sh"

file="$(ls $2 | grep -x $3 | tail -n 1)"
if [ -z "$file" ]; then
  echo "$0: Failed to find artifact file $2/$3" >&2
  exit 1
fi
export $1="$WORKDIR/$file"
if [ -f "$1" ]; then
  rm "$1"
fi
mv "$2/$file" "${!1}"
