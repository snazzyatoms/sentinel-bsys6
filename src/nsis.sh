#!/usr/bin/bash
set -eu -o pipefail

if [ -z "${NSIS:-}" ]; then
  source "$BSYS6/utils/require_target.sh" "windows"

  source "$BSYS6/utils/vars.sh"
  source "$BSYS6/build_use_existing.sh"

  echo "-> Building installer with nsis"
  source "$BSYS6/utils/tmpdir.sh"
  echo "tmpdir is $TMPDIR"
  mkdir -p "$TMPDIR/x86-ansi"
  cp -v "$BSYS6/../assets/nsProcess.dll" "$TMPDIR/x86-ansi/nsProcess.dll"
  curl -Lo "$TMPDIR/vc_redist.x64.exe" "https://aka.ms/vs/17/release/vc_redist.x64.exe"
  sed "s/pkg_version/$VERSION/g" <"$BSYS6/../assets/setup.nsi" >"$TMPDIR/setup.nsi"
  cp "$BSYS6/../assets/librewolf.ico" "$TMPDIR"
  cp "$BSYS6/../assets/banner.bmp" "$TMPDIR"
  ln -s "$BUILT" "$TMPDIR/librewolf"
  printf "Running nsis... "
  (cd "$TMPDIR" && $MOZBUILD/nsis/bin/makensis -V1 "setup.nsi")
  echo "Done"

  source "$BSYS6/utils/move_artifact.sh" "NSIS" "$TMPDIR" ".*setup\.exe"

  cd "$WORKDIR"
  rm -rf "$TMPDIR"
fi
