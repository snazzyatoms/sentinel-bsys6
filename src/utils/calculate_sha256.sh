#!/usr/bin/bash
set -eu

if [ "$#" -ne 1 ]; then
  echo "Usage: calculate_sha256.sh <artifact_name>" >&2
  exit 1
fi

echo "-> Calculating checksum" >&2
sha256sum "${!1}" >"${!1}.sha256sum"
export $1_SHA256="${!1}.sha256sum"
