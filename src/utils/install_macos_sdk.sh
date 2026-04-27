#!/usr/bin/env bash
set -eu

source $BSYS6/source.sh

echo "-> Fetching macos sdk"
$SOURCE/mach python --virtualenv build \
  $SOURCE/taskcluster/scripts/misc/unpack-sdk.py \
  "https://swcdn.apple.com/content/downloads/60/13/122-35686-A_30JUXWIJFR/ck0gzuw5qccefzm3ptlwou3pu6a55d0o02/CLTools_macOSNMOS_SDK.pkg" \
  "3e4e755526d97d4ccc8caa0d42c6ecb41cfd009a9e2848f86766f0eb30990f0f26709339caa926151becd4501df59cfeaa47a0caa7b8ad13c4211b607d1e63c8" \
  "Library/Developer/CommandLineTools/SDKs/MacOSX26.4.sdk" \
  "$MOZBUILD/MacOSX26.4.sdk"
