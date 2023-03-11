#!/usr/bin/bash

source $BSYS6/exports/target.sh

cat <<EOF
bsys6 - The 6th generation LibreWolf Build System

Usage: bsys6 [command]

Commands:                                                                   | Artifacts:
EOF

command_descr() {
  case "$1" in
  bootstrap) echo "Bootstrap the build system with mach" ;;
  build_docker) echo "Run the 'build' command inside Docker" ;;
  build_image) echo "Build the docker image used by 'build_docker'" ;;
  build) echo "Build LibreWolf (requires a prepared system)" ;;
  clean) echo "Remove the work directory (including source)" ;;
  clobber) echo "Clean the current source directory" ;;
  help) echo "Show this page" ;;
  msix) echo "Build a MSIX package for Windows" ;;
  nsis) echo "Build the installer for Windows with nsis" ;;
  package) echo "Package LibreWolf into a zip/tarball" ;;
  prepare) echo "Prepare the build enviroment and install dependencies" ;;
  source) printf "Download the latest LibreWolf source code into\nthe working directory" ;;
  win_portable) echo "Build a zip containing the LibreWolf Portable" ;;
  *) ;;
  esac
}

command_artifacts() {
  case "$1" in
  build) echo "BUILT" ;;
  msix) echo "MSIX" ;;
  nsis) echo "NSIS" ;;
  package) echo "PACKAGED" ;;
  source) echo "SOURCE" ;;
  win_portable) echo "WIN_PORTABLE" ;;
  *) ;;
  esac
}

for file in $BSYS6/*.sh; do
  basename="${file##*/}"
  command="${basename%.sh}"
  descr="$(command_descr $command)"
  artifacts="$(command_artifacts $command)"
  if [ "$descr" == "" ]; then
    echo "  $command"
  else
    IFS=$'\n'
    for line in $descr; do
      if [ "$command" == "" ]; then
        printf "%-19s %s\n" "" "$line"
      else
        if [ "$artifacts" == "" ]; then
          printf "  %-15s - %s\n" "$command" "$line"
        else
          printf "  %-15s - %-55s | %s\n" "$command" "$line" "$artifacts"
        fi
      fi
      command=""
    done
  fi
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
