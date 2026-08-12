#!/usr/bin/env bash
set -eu

$BSYS6/utils/require_command.sh s3cmd

abort="false"
for required_var in "S3_ENDPOINT" "S3_ARTIFACTS_BUCKET" "S3_KEY" "S3_SECRET" "S3_ARTIFACTS_PUBLIC_URL" "FORGEJO_RUN_NUMBER"; do
  if [ -z "${!required_var:-}" ]; then
    echo "Error: '$required_var' is not set" >&2
    abort="true"
  fi
done
if [ "$abort" == "true" ]; then
  echo "Notice: This script is only meant to be run on Forgejo CI" >&2
  exit 1
fi

# All jobs of a workflow run share this prefix; rerunning a single job keeps
# the run number, so it uploads into the same prefix again.
export ARTIFACTS_RUN_PATH="/runs/$FORGEJO_RUN_NUMBER"

# artifacts_s3cmd <command...>
artifacts_s3cmd() {
  s3cmd "$@" \
    --access_key="$S3_KEY" \
    --secret_key="$S3_SECRET" \
    --host="$S3_ENDPOINT" \
    --host-bucket="$S3_ENDPOINT" \
    --guess-mime-type \
    --no-mime-magic
}
