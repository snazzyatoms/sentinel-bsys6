#!/usr/bin/env bash
set -eu

source $BSYS6/source.sh

echo "-> Fetching macos sdk"
$SOURCE/mach python --virtualenv build \
  $SOURCE/taskcluster/scripts/misc/unpack-sdk.py \
  "https://swcdn.apple.com/content/downloads/60/22/089-71960-A_W8BL1RUJJ6/5zkyplomhk1cm7z6xja2ktgapnhhti6wwd/CLTools_macOSNMOS_SDK.pkg" \
  "f3785f1bbc3b8323121b66fc28ef59083b4f508c7bdabb9d8d916f142ee89b01cb8030eba469eb9107b416d1c9d523a1d2e009cddb83536a819a3704a5d3ce17" \
  "Library/Developer/CommandLineTools/SDKs/MacOSX26.2.sdk" \
  "$MOZBUILD/MacOSX26.2.sdk"
