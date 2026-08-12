#!/usr/bin/env bash
set -eu
shopt -s nullglob

source $BSYS6/exports/artifacts_s3.sh

uploaded="false"
for file in *.AppImage *.zsync *.deb *.rpm *.tar.xz *.zip *.exe *.msix *.nupkg *.dmg *.sha256sum; do
  echo "-> Uploading $file to the artifacts bucket" >&2
  s3_path="$ARTIFACTS_RUN_PATH/$file"
  if ! artifacts_s3cmd put "$file" "s3://$S3_ARTIFACTS_BUCKET$s3_path" >&2; then
    echo "Error: Failed to upload $file to the artifacts bucket" >&2
    exit 1
  fi
  echo "${S3_ARTIFACTS_PUBLIC_URL}${s3_path}"
  uploaded="true"
done

if [ "$uploaded" == "false" ]; then
  echo "Error: No artifacts found to upload" >&2
  exit 1
fi
