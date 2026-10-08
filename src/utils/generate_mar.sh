#!/usr/bin/env bash

set -eu

if [ "$#" -ne 1 ]; then
  echo "Usage: generate_mar.sh <path>" >&2
  exit 1
fi

source $BSYS6/source.sh
source $BSYS6/exports/require_build.sh
source $BSYS6/exports/target.sh
source $BSYS6/exports/version.sh
$BSYS6/utils/require_command.sh pk12util certutil

app_path="$(readlink -f "$1")"

(cd "$SOURCE" && ./mach python config/createprecomplete.py "$app_path")

export MAR="$SOURCE/obj-$MOZ_TARGET/dist/host/bin/mar"
export MOZ_PRODUCT_VERSION="$VERSION"
export MAR_CHANNEL_ID="release"

# Create mar
(cd "$SOURCE" && ./tools/update-packaging/make_full_update.sh "sentinel.mar" "$app_path")

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# Create signing database
mkdir -p "$tmpdir/nssdb"
certutil -N -d "$tmpdir/nssdb" -f <(printf '%s\n' "$NSS_PASSWORD")

# Import keys
printf '%s' "$MAR_KEY_1" | base64 -d > "$tmpdir/cert.p12"
pk12util -i "$tmpdir/cert.p12" -d "$tmpdir/nssdb" -K "$NSS_PASSWORD" -W "$MAR_KEY_1_PASSWORD"

# Sign mar
printf '%s\n' "$NSS_PASSWORD" | signmar -d "$tmpdir/nssdb" -n "marsigner-2026" -s "$SOURCE/sentinel.mar" "sentinel-signed.mar"

# Verify that it was signed correctly
signmar -d "$tmpdir/nssdb" -n "marsigner-2026" -v "sentinel-signed.mar"
