#!/usr/bin/env bash
set -eu

source $BSYS6/source.sh

echo "-> Fetching macos sdk"
$SOURCE/mach python --virtualenv build \
  $SOURCE/taskcluster/scripts/misc/unpack-sdk.py \
  "https://swcdn.apple.com/content/downloads/52/01/082-41241-A_0747ZN8FHV/dectd075r63pppkkzsb75qk61s0lfee22j/CLTools_macOSNMOS_SDK.pkg" \
  "fb7c555e823b830279394e52c7d439bd287a9d8b007883fa0595962a240d488b5613f8cc8d1cc9657909de9367417652564f3df66e238a47bbc87244f5205056" \
  "Library/Developer/CommandLineTools/SDKs/MacOSX15.5.sdk" \
  "$MOZBUILD/MacOSX15.5.sdk"
