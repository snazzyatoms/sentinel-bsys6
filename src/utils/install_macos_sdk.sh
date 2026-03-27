#!/usr/bin/env bash
set -eu

source $BSYS6/source.sh

echo "-> Fetching macos sdk"
$SOURCE/mach python --virtualenv build \
  $SOURCE/taskcluster/scripts/misc/unpack-sdk.py \
  "https://swcdn.apple.com/content/downloads/32/53/047-96692-A_OAHIHT53YB/ybtshxmrcju8m2qvw3w5elr4rajtg1x3y3/CLTools_macOSNMOS_SDK.pkg" \
  "8c0571820cbf6eb977610a08922a2158ff3ed86389d4faa7eba34288f467047c6bacccc23aa6991f0d18450e393dd56cf581b08010fac45254db2c649610e9fc" \
  "Library/Developer/CommandLineTools/SDKs/MacOSX26.4.sdk" \
  "$MOZBUILD/MacOSX26.4.sdk"
