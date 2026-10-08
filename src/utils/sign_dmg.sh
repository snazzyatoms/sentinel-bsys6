#!/usr/bin/env bash
set -eu

# Signs (and optionally notarizes) the .app inside a .dmg in place, using
# rcodesign and the signing configuration of the source tree via 'mach macos-sign'.

if [ "$#" -ne 1 ]; then
  echo "Usage: sign_dmg.sh <dmg>" >&2
  exit 1
fi

if [ -z "${MACOS_SIGNING_P12:-}" ]; then
  echo "-> Skipping macOS code signing, MACOS_SIGNING_P12 is not set" >&2
  exit 0
fi

source $BSYS6/exports/require_build.sh
$BSYS6/utils/require_command.sh rcodesign xattr openssl

dmg="$(readlink -f "$1")"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# rcodesign rejects an empty password file, always write a (possibly empty) line
p12="$tmpdir/signing.p12"
p12_password="$tmpdir/signing.p12.password"
echo "$MACOS_SIGNING_P12" | base64 -d >"$p12"
printf '%s\n' "${MACOS_SIGNING_P12_PASSWORD:-}" >"$p12_password"

# rcodesign wants legacy PKCS#12 encoding and only the signing cert
openssl pkcs12 -in "$p12" -legacy -passin "file:$p12_password" -nodes -nocerts -out "$tmpdir/signing.key"
openssl pkcs12 -in "$p12" -legacy -passin "file:$p12_password" -clcerts -nokeys -out "$tmpdir/signing.crt"
openssl pkcs12 -export -legacy -inkey "$tmpdir/signing.key" -in "$tmpdir/signing.crt" -passout "file:$p12_password" -out "$p12"
rm "$tmpdir/signing.key" "$tmpdir/signing.crt"
echo "-> Signing certificate:" >&2
rcodesign analyze-certificate --p12-file "$p12" --p12-password-file "$p12_password" | grep -E "Subject CN|Team ID|Not Valid After" >&2

# Stub out Apples codesign
mkdir "$tmpdir/bin"
printf '#!/bin/sh\nexit 0\n' >"$tmpdir/bin/codesign"
chmod +x "$tmpdir/bin/codesign"

mach_verbose=""
if [ "${VERBOSE:-}" == "true" ]; then
  mach_verbose="-v"
fi

echo "-> Extracting $dmg" >&2
(cd "$SOURCE" && ./mach python -m mozbuild.action.unpack_dmg "$dmg" "$tmpdir/dmg" >/dev/null)
app="$(ls -d "$tmpdir"/dmg/*.app)"

echo "-> Signing $app with rcodesign" >&2
(cd "$SOURCE" && PATH="$tmpdir/bin:$PATH" ./mach macos-sign $mach_verbose \
  -r --channel release --entitlements production-without-restricted \
  --rcodesign-p12-file "$p12" --rcodesign-p12-password-file "$p12_password" \
  --app-path "$app")

if [ -n "${MACOS_NOTARY_KEY:-}" ]; then
  echo "-> Notarizing $app with rcodesign" >&2
  printf '%s\n' "$MACOS_NOTARY_KEY" >"$tmpdir/notary.p8"
  rcodesign encode-app-store-connect-api-key -o "$tmpdir/notary.json" \
    "${MACOS_NOTARY_ISSUER_ID:?}" "${MACOS_NOTARY_KEY_ID:?}" "$tmpdir/notary.p8"
  if ! rcodesign notary-submit --api-key-file "$tmpdir/notary.json" --staple \
      --max-wait-seconds "${MACOS_NOTARY_MAX_WAIT_SECONDS:-7200}" "$app"; then
    echo "$0: Notarization failed or timed out, check the submission with 'rcodesign notary-list'" >&2
    exit 1
  fi
else
  echo "-> Skipping notarization, MACOS_NOTARY_KEY is not set" >&2
fi

echo "-> Repackaging $dmg" >&2
(cd "$SOURCE" && ./mach python -m mozbuild.action.make_dmg "$tmpdir/dmg" "$tmpdir/signed.dmg" >/dev/null)
mv -f "$tmpdir/signed.dmg" "$dmg"
mv -f "$app" "sentinel-signed.app"
