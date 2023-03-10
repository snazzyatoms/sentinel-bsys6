#!/usr/bin/bash
set -e

source $BSYS6/exports/target.sh

case $TARGET in

linux)
  echo "-> Preparing build environment for native linux build (target: linux)"

  $BSYS6/utils/dependencies.sh "python3-pip curl" "python-pip curl"
  source $BSYS6/exports/version.sh
  $BSYS6/bootstrap.sh
  $BSYS6/utils/artifact.sh "sysroot-wasm32-wasi" "linux64-cbindgen"
  ;;

windows)
  echo "-> Preparing build environment for cross-compilation to windows (target: windows)"

  $BSYS6/utils/dependencies.sh "python3-pip curl msitools zstd libc6-i386 p7zip-full jq zip unzip wget" "python-pip curl msitools zstd lib32-glibc p7zip jq zip unzip wget"
  source $BSYS6/exports/version.sh
  $BSYS6/bootstrap.sh
  $BSYS6/utils/rustup_target.sh "x86_64-pc-windows-msvc"
  $BSYS6/utils/artifact.sh "linux64-binutils" "linux64-cbindgen" "linux64-clang" "linux64-dump_syms" "linux64-nasm" "linux64-node" "linux64-rust-cross" "linux64-winchecksec" "linux64-wine" "linux64-msix-packaging" "linux64-mingw-fxc2-x86" "nsis" "sysroot-x86_64-linux-gnu"
  $BSYS6/utils/winsdk.sh
  ;;

*)
  echo "Can not prepare build environment for target '$TARGET'"
  exit 1
  ;;
esac
