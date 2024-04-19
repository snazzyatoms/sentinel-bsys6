#!/usr/bin/env bash
set -eu

source $BSYS6/source.sh

echo "-> Fetching macos sdk"
$SOURCE/mach python --virtualenv build $SOURCE/taskcluster/scripts/misc/unpack-sdk.py "https://swcdn.apple.com/content/downloads/14/48/052-59890-A_I0F5YGAY0Y/p9n40hio7892gou31o1v031ng6fnm9sb3c/CLTools_macOSNMOS_SDK.pkg" "a4e05d2a051027620c86f72694da126a2ceed59b8740270426c4ca3adb38e16fe981b536a373a7f0cdcc84bbe9d9149608ccd03967dbd94262548ccadbfa0f5d" "Library/Developer/CommandLineTools/SDKs/MacOSX14.4.sdk" "$MOZBUILD/MacOSX14.4.sdk"
