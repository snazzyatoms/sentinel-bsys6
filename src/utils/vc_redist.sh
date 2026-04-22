#!/usr/bin/env bash
set -eu

$BSYS6/utils/require_command.sh unzip

case "$ARCH" in
  x86_64) VC_ARCH="amd64" ;;
  arm64)  VC_ARCH="arm64" ;;
esac

if [ -n "${ARCH:-}" ]; then
  pwd="$(pwd)"
  if [ "$#" -gt 0 ]; then
    cd "$1"
  fi

  $BSYS6/utils/download.sh "https://codeberg.org/librewolf/vc_redist/releases/download/latest/vc_redist_$VC_ARCH.zip" "vc_redist.zip"

  unzip vc_redist.zip
  rm vc_redist.zip
  cd "$pwd"
fi
