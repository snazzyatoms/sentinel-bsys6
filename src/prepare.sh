#!/usr/bin/bash
set -eu

source $BSYS6/exports/target.sh

case $TARGET in

linux)
  echo "-> Preparing build environment for native linux build (target: linux)"

  $BSYS6/utils/dependencies.sh "python3-pip curl" "python-pip curl"
  # cross-compilation
  $BSYS6/utils/dependencies.sh "binutils-aarch64-linux-gnu" "aarch64-linux-gnu-binutils"
  source $BSYS6/exports/version.sh
  $BSYS6/bootstrap.sh
  $BSYS6/utils/rustup_target.sh "aarch64-unknown-linux-gnu"
  $BSYS6/utils/install_toolchain_artifact.sh "sysroot-wasm32-wasi" "linux64-cbindgen"
  ;;

windows)
  echo "-> Preparing build environment for cross-compilation to windows (target: windows)"

  $BSYS6/utils/dependencies.sh "python3-pip curl msitools zstd libc6-i386 p7zip-full jq zip unzip wget mono-complete gettext-base" "python-pip curl msitools zstd lib32-glibc p7zip jq zip unzip wget mono gettext"
  source $BSYS6/exports/version.sh
  $BSYS6/bootstrap.sh
  $BSYS6/utils/rustup_target.sh "x86_64-pc-windows-msvc"
  $BSYS6/utils/install_toolchain_artifact.sh "linux64-binutils" "linux64-cbindgen" "linux64-clang" "linux64-dump_syms" "linux64-nasm" "linux64-node" "linux64-rust-cross" "linux64-winchecksec" "linux64-wine" "linux64-msix-packaging" "linux64-mingw-fxc2-x86" "nsis" "sysroot-x86_64-linux-gnu"
  $BSYS6/utils/winsdk.sh
  $BSYS6/utils/install_chocolatey.sh
  ;;

dind)
  if [ -z "${DOCKER:-}" ]; then
    echo "Error: Preparing the 'dind' target should only happen inside a docker container" >&2
    exit 1
  fi

  echo "-> Preparing dind container"

  $BSYS6/utils/dependencies.sh "ca-certificates curl gnupg lsb-release" ""
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
  $BSYS6/utils/dependencies.sh "docker-ce docker-ce-cli containerd.io docker-compose-plugin make wget lbzip2" ""

  echo "-> Installing GitLab release-cli"
  curl -L --output /usr/local/bin/release-cli "https://release-cli-downloads.s3.amazonaws.com/latest/release-cli-linux-amd64"
  chmod +x /usr/local/bin/release-cli
  ;;

*)
  echo "Can not prepare build environment for target '$TARGET'"
  exit 1
  ;;
esac
