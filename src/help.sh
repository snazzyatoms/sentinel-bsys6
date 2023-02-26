#!/usr/bin/bash

source $BSYS6/utils/vars.sh

cat <<EOF
bsys6 - The 6th generation LibreWolf Build System

Usage: bsys6 [command]

Commands:
EOF

for file in $BSYS6/*.sh; do
  basename="${file##*/}"
  echo "  ${basename%.sh}"
done

cat <<EOF

Commands may be customized by setting the following environment variables:
  TARGET  - The target platform (available: $AVAILABLE_TARGETS; currently: $TARGET)
  ARCH    - The target architecture (available: $AVAILABLE_ARCHS; currently: $ARCH)
  VERSION - The version of LibreWolf to build (default: latest)
  WORKDIR - The directory to use for temporary files (currently: $WORKDIR)

  You can also persist these settings by creating a file named "env.sh" in the
  same directory as this script, and setting the variables there, for example:

  '''
  export WORKDIR=/mnt/ssd2/bsys6-work
  '''
EOF
