#!/usr/bin/bash
set -eu

if [ "$#" -lt 3 ]; then
  echo "Usage: move_artifact.sh <artifact_name> <directory> <file_regex> (new_file)" >&2
  exit 1
fi

source "$BSYS6/exports/vars.sh"

echo "Searching for artifact $3"
file="$(ls "$2" | grep -x "$3" | tail -n 1)"
if [ -z "$file" ]; then
  echo "$0: Failed to find artifact file $2/$3" >&2
  exit 1
fi

if [ "$#" -gt 3 ]; then
  export $1="$ENTRY_PWD/$4"
else
  export $1="$ENTRY_PWD/$file"
fi

if [ -f "$1" ]; then
  rm "$1"
fi
echo "Found $file, moving to $ENTRY_PWD"
mv "$2/$file" "${!1}"
