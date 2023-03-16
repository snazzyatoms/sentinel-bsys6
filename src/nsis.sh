#!/usr/bin/bash
set -eu -o pipefail

if [ -z "${NSIS:-}" ]; then
  source $BSYS6/exports/require_target.sh "windows"

  source $BSYS6/package.sh

  echo "-> Extracting packaged build"
  source $BSYS6/exports/tmpdir.sh
  echo "tmpdir is $TMPDIR"
  unzip "$PACKAGED" -d "$TMPDIR"

  echo "-> Building installer with nsis"
  cp -v "$BSYS6/../assets/librewolf.ico" "$TMPDIR/librewolf/librewolf.ico"
  mkdir -p "$TMPDIR/x86-ansi"
  cp -v "$BSYS6/../assets/nsProcess.dll" "$TMPDIR/x86-ansi/nsProcess.dll"
  curl -Lo "$TMPDIR/vc_redist.x64.exe" "https://aka.ms/vs/17/release/vc_redist.x64.exe"
  sed "s/pkg_version/$VERSION/g" <"$BSYS6/../assets/setup.nsi" >"$TMPDIR/setup.nsi"
  cp "$BSYS6/../assets/librewolf.ico" "$TMPDIR"
  cp "$BSYS6/../assets/banner.bmp" "$TMPDIR"
  printf "Running nsis... "
  (cd "$TMPDIR" && $MOZBUILD/nsis/bin/makensis -V1 "setup.nsi")
  echo "Done"

  source $BSYS6/exports/move_artifact.sh "NSIS" "$TMPDIR" ".*setup\.exe"
  source $BSYS6/exports/calculate_sha256.sh "NSIS"

  rm -rf "$TMPDIR"
  unset TMPDIR
fi
