#!/usr/bin/env bash
set -eu

source $BSYS6/exports/target.sh
$BSYS6/utils/require_command.sh docker

echo "-> Building docker $TARGET image" >&2
(cd "$BSYS6/.." && docker build --progress=plain -t "codeberg.org/$FORGE_REPO_OWNER/bsys6:$TARGET" --build-arg TARGET . -f assets/Dockerfile)
