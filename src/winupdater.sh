#!/usr/bin/env bash
set -eu

source $BSYS6/exports/require_target.sh windows
$BSYS6/utils/require_command.sh "unzip"

echo "-> Preparing WinUpdater" >&2
tmpdir="$(mktemp -d)"

cd $tmpdir

$BSYS6/utils/download_forge.sh "$FORGE_REPO_OWNER/winupdater" 'LibreWolf-WinUpdater_[.\\d]+\\.zip$' "lwu.zip"
unzip lwu.zip
rm lwu.zip
rm *.url

export WINUPDATER="$tmpdir"
