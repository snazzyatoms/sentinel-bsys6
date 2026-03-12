#!/usr/bin/env bash
set -eu

source $BSYS6/exports/require_target.sh windows
$BSYS6/utils/require_command.sh "unzip"

echo "-> Preparing WinUpdater" >&2
tmpdir="$(mktemp -d)"

cd $tmpdir

$BSYS6/utils/download_codeberg.sh "librewolf/librewolf-winupdater" 'LibreWolf-WinUpdater_[.\\d]+\\.zip$' "LibreWolf-WinUpdater.zip"
unzip LibreWolf-WinUpdater.zip
rm LibreWolf-WinUpdater.zip
rm *.url

export WINUPDATER="$tmpdir"
