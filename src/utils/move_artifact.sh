#!/usr/bin/bash
set -eu

if [ "$#" -ne 3 ]; then
  echo "Usage: move_artifact.sh <artifact_name> <directory> <file_regex>" >&2
  exit 1
fi

source "$BSYS6/utils/vars.sh"

echo "Searching for artifact $3"
file="$(ls "$2" | grep -x "$3" | tail -n 1)"
if [ -z "$file" ]; then
  echo "$0: Failed to find artifact file $2/$3" >&2
  exit 1
fi
# export $1="$WORKDIR/$file" # Move the file to workdir
export $1="$ENTRY_PWD/$file" # Move file to current directory
if [ -f "$1" ]; then
  rm "$1"
fi
echo "Found $file, moving to $ENTRY_PWD"
mv "$2/$file" "${!1}"
