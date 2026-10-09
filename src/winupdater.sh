#!/usr/bin/env bash
set -eu

source $BSYS6/exports/require_target.sh windows
$BSYS6/utils/require_command.sh "mcs"

echo "-> Building WinUpdater" >&2
tmpdir="$(mktemp -d)"

mcs -optimize+ -target:winexe -platform:x64 \
    -r:System.Windows.Forms -r:System.Drawing \
    -r:System.Runtime.Serialization \
    -win32icon:"$BSYS6/../assets/sentinel.ico" \
    -out:"$tmpdir/Sentinel-WinUpdater.exe" \
    "$BSYS6/../assets/updater/SentinelUpdater.cs"

cp "$BSYS6/../assets/updater/ScheduledTask-Create.ps1" "$tmpdir/"
cp "$BSYS6/../assets/updater/ScheduledTask-Remove.ps1" "$tmpdir/"

export WINUPDATER="$tmpdir"
