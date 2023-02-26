#!/usr/bin/bash
set -e -o pipefail

while [[ $# -gt 0 ]]; do
  case $1 in
  -t | --target)
    export TARGET="$2"
    shift
    shift
    ;;
  -a | --arch)
    export ARCH="$2"
    shift
    shift
    ;;
  -v | --version)
    export VERSION="$2"
    shift
    shift
    ;;
  *)
    echo "Unknown argument $1"
    exit 1
    ;;
  esac
done

source $BSYS6/utils/vars.sh
source $BSYS6/utils/version.sh

docker run --user --rm -v "$(pwd)":"/bsys6" -e TARGET="$TARGET" -e ARCH="$ARCH" -e VERSION="$VERSION" "registry.gitlab.com/librewolf-community/browser/bsys6/$TARGET" sh -c "./bsys6 build"
