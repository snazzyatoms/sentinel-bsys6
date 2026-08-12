#!/usr/bin/env bash
set -eu

source $BSYS6/exports/artifacts_s3.sh

retention_days="${ARTIFACTS_RETENTION_DAYS:-14}"
cutoff="$(date -d "$retention_days days ago" +%s)"

echo "-> Deleting objects older than $retention_days days from s3://$S3_ARTIFACTS_BUCKET"

deleted=0
kept=0
while read -r mod_date mod_time _size object; do
  if [ -z "$object" ]; then
    continue
  fi
  if [ "$(date -d "$mod_date $mod_time" +%s)" -lt "$cutoff" ]; then
    echo "--> Deleting $object (last modified $mod_date $mod_time)"
    artifacts_s3cmd del "$object" >&2
    deleted=$((deleted + 1))
  else
    kept=$((kept + 1))
  fi
done < <(artifacts_s3cmd ls --recursive "s3://$S3_ARTIFACTS_BUCKET/")

echo "-> Deleted $deleted objects, kept $kept"
