#!/usr/bin/env bash
set -eu

source $BSYS6/exports/require_target.sh windows
$BSYS6/utils/require_command.sh "unzip"

echo "-> Preparing WinUpdater" >&2
tmpdir="$(mktemp -d)"

cd $tmpdir

$BSYS6/utils/download_codeberg.sh "ltguillaume/librewolf-winupdater" 'LibreWolf-WinUpdater_[.\\d]+\\.zip$' "LibreWolf-WinUpdater.zip"
unzip LibreWolf-WinUpdater.zip
rm LibreWolf-WinUpdater.zip
rm *.url

$BSYS6/utils/sign_exe.sh LibreWolf-WinUpdater.exe

export WINUPDATER="$tmpdir"
