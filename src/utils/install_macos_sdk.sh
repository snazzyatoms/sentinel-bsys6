#!/usr/bin/env bash
set -eu

source $BSYS6/source.sh

echo "-> Fetching macos sdk"
$SOURCE/mach python --virtualenv build $SOURCE/taskcluster/scripts/misc/unpack-sdk.py "https://swcdn.apple.com/content/downloads/10/32/082-12052-A_AHPGDY76PT/1a419zaf3vh8o9t3c0usblyr8eystpnsh5/CLTools_macOSNMOS_SDK.pkg" "fd01c70038dbef48bd23fb8b7d18f234910733635f1b44518e71a66d2db92a70180e6a595c6bdd837fa8df7e9b297e570560842e9a6db863840bd051fe69fea5" "Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk" "$MOZBUILD/MacOSX15.4.sdk"
