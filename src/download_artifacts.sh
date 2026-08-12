#!/usr/bin/env bash
set -eu

source $BSYS6/exports/artifacts_s3.sh

echo "-> Downloading artifacts from s3://$S3_ARTIFACTS_BUCKET$ARTIFACTS_RUN_PATH/" >&2
if ! artifacts_s3cmd get --recursive --force "s3://$S3_ARTIFACTS_BUCKET$ARTIFACTS_RUN_PATH/" . >&2; then
  echo "Error: Failed to download artifacts from the artifacts bucket" >&2
  exit 1
fi
