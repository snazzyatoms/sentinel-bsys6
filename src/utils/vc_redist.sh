#!/usr/bin/env bash
set -eu

VC_REDIST_TAG="$(curl -sL https://api.github.com/repos/abbodi1406/vcredist/releases/latest | jq -r '.tag_name')"
VC_REDIST_URL="https://github.com/abbodi1406/vcredist/releases/download/$VC_REDIST_TAG/VisualCppRedist_AIO_x86_x64.exe"
# VC_REDIST_URL="https://gitlab.com/-/project/76069787/uploads/970122d287d9221283ae5615fb9ad1ff/VisualCppRedist_AIO_x86_x64.exe"
if [ -n "${VC_REDIST_URL:-}" ]; then
  pwd="$(pwd)"
  if [ "$#" -gt 0 ]; then
    cd "$1"
  fi
  $BSYS6/utils/download.sh "$VC_REDIST_URL" "vc_redist.exe"

  case "$ARCH" in
  x86_64) TO_EXTRACT="2026/x64/System64/msvcp140.dll 2026/x64/System64/msvcp140_atomic_wait.dll 2026/x64/System64/vcruntime140.dll 2026/x64/System64/vcruntime140_1.dll" ;;
  arm64) TO_EXTRACT="2026/arm64/System64/msvcp140.dll 2026/arm64/System64/msvcp140_atomic_wait.dll 2026/arm64/System64/vcruntime140.dll 2026/arm64/System64/vcruntime140_1.dll" ;;
  esac

  7z e vc_redist.exe $TO_EXTRACT
  rm vc_redist.exe
  cd "$pwd"
fi
