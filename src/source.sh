#!/usr/bin/env bash
set -eu

source $BSYS6/exports/target.sh
source $BSYS6/exports/version.sh

if [ -z "${SOURCE:-}" ]; then
  if [ ! -d "$SOURCEDIR" ]; then

    $BSYS6/utils/require_command.sh tar

    mkdir -p "$SOURCEDIR/.." >&2
    mkdir -p "$WORKDIR" >&2

    if [ -z "${SOURCE_TAR:-}" ]; then
      echo "-> Fetching source tarball for version $VERSION" >&2
      curl -fLA "" -o "$WORKDIR/librewolf-$VERSION.source.tar.gz" "$SOURCE_URL" >&2
      export SOURCE_TAR="$WORKDIR/librewolf-$VERSION.source.tar.gz"
    fi

    echo "-> Extracting source tarball" >&2
    tar xf "$SOURCE_TAR" -C "$SOURCEDIR/.." >&2
    if [ "$(readlink -f "$SOURCEDIR")" != "$(readlink -f "$SOURCEDIR/../librewolf-$VERSION")" ]; then
      mv "$SOURCEDIR/../librewolf-$VERSION" "$SOURCEDIR" >&2
    fi

    if [[ $SOURCE_TAR == $WORKDIR* ]]; then
      echo "-> Cleaning up source tarball" >&2
      rm "$SOURCE_TAR" >&2
    fi

    # Add support for aarch64 targets
    if [ "${TARGET:-}" == "windows" ] && [ "${ARCH:-}" == "arm64" ]; then
      sed -i '/"x86_64": \["--win64", "-m64"\],/a\        "aarch64": ["--win64", "-m64"],' "$SOURCEDIR/toolkit/moz.configure"
    fi
  fi

  if [ ! -f "$SOURCEDIR/mozconfig.backup" ]; then
    if [ -f "$SOURCEDIR/mozconfig" ]; then
      echo "-> Creating mozconfig backup" >&2
      cp "$SOURCEDIR/mozconfig" "$SOURCEDIR/mozconfig.backup"
    else
      touch "$SOURCEDIR/mozconfig.backup"
    fi
  fi

  mozconfig="$(
    cat <<EOF
$(cat "$SOURCEDIR/mozconfig.backup")
ac_add_options --target=$MOZ_TARGET
EOF
  )"

  if [ -f "$BSYS6/../assets/$TARGET.mozconfig" ]; then
    mozconfig="$(
      cat <<EOF
$mozconfig
$(cat "$BSYS6/../assets/$TARGET.mozconfig")
EOF
    )"
  fi

  # Total hack (temporary)
  if [[ $TARGET == "macos" && $ARCH = "x86_64" ]]; then
    mozconfig="$(
      cat <<EOF
$mozconfig
export NASM="\$MOZBUILD/nasm/nasm"
EOF
    )"
  fi

  # Use system widl for arm64 Windows builds
  if [[ $TARGET == "windows" && "${ARCH:-}" == "arm64" ]]; then
    mozconfig="$(
      cat <<EOF
$mozconfig
export MIDL="$(which widl)"
EOF
    )"
  fi

  if [[ "${LTO:-false}" == "true" ]]; then
    if [[ $TARGET == "windows" ]]; then
      mozconfig="$(
        cat <<EOF
$mozconfig
ac_add_options --enable-lto=full,cross
EOF
      )"
    else
      mozconfig="$(
        cat <<EOF
$mozconfig
ac_add_options --enable-lto=full,cross
EOF
      )"
    fi
  fi

# Taking care of pgo-file
  if [ -f "$BSYS6/../assets/$TARGET.profdata" ]; then
      mozconfig="$(
        cat <<EOF
$mozconfig
ac_add_options --with-pgo-profile-path="$BSYS6/../assets/$TARGET.profdata"
ac_add_options --enable-profile-use
EOF
      )"
  fi

# Signmar
  if [[ "${SIGNMAR:-false}" == "true" ]]; then
      mozconfig="$(
        cat <<EOF
$mozconfig
ac_add_options --disable-profile-use
ac_add_options --without-pgo-profile-path
ac_add_options --without-sysroot
ac_add_options --with-system-nss
ac_add_options --with-system-nspr
ac_add_options --enable-updater
ac_add_options --enable-update-channel=release
EOF
      )"
  fi

  mozconfig_new_hash=$(echo "$mozconfig" | sha256sum | cut -d' ' -f1)
  mozconfig_old_hash=$(cat "$SOURCEDIR/mozconfig.hash" 2>/dev/null || echo "")

  if [ "$mozconfig_new_hash" != "$mozconfig_old_hash" ]; then
    echo "-> Updating mozconfig, target is $MOZ_TARGET" >&2
    echo "$mozconfig" >"$SOURCEDIR/mozconfig"
    echo "$mozconfig_new_hash" >"$SOURCEDIR/mozconfig.hash"
    export MOZCONFIG_CHANGED="true"
  fi

  export SOURCE="$SOURCEDIR"
fi
