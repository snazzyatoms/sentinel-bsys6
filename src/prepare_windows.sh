#!/usr/bin/bash
set -eu

source $BSYS6/utils/require_target.sh "windows"

echo "-> Preparing build environment for cross-compilation to windows (target: windows)"

source $BSYS6/dependencies.sh "python3-pip curl msitools zstd libc6-i386" "python-pip curl msitools zstd lib32-glibc"
source $BSYS6/utils/version.sh
source $BSYS6/bootstrap.sh
source $BSYS6/rustup_target.sh "x86_64-pc-windows-msvc"
source $BSYS6/artifact.sh "linux64-binutils" "linux64-cbindgen" "linux64-clang" "linux64-dump_syms" "linux64-nasm" "linux64-node" "linux64-rust-cross" "linux64-winchecksec" "linux64-wine" "linux64-msix-packaging" "linux64-mingw-fxc2-x86" "nsis" "sysroot-x86_64-linux-gnu"
source $BSYS6/winsdk.sh
