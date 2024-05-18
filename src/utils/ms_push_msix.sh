#!/usr/bin/env bash
set -eu

if [ "$#" -eq 0 ]; then
  echo "Error: No msix packages provided" >&2
  exit 1
fi

# https://github.com/microsoft/store-submission/blob/main/src/store_apis.ts
echo "-> Pushing msix packages to the Microsoft Store"
source $BSYS6/exports/ms_access_token.sh
ms_application_id="9NVN9SZ8KFD7"
echo "Creating new submission"
ms_submission="$(curl -s -X POST https://manage.devcenter.microsoft.com/v1.0/my/applications/$ms_application_id/submissions --header 'Content-Type: application/json' --header "Authorization: Bearer $MS_ACCESS_TOKEN" -d "")"
ms_submission_id="$(echo "$ms_submission" | jq -r '.id')"
echo "Submission ID is $ms_submission_id"
ms_file_upload_url="$(echo "$ms_submission" | jq -r '.fileUploadUrl')"
for msix in "$@"; do
  echo "Uploading $msix"
  $BSYS6/utils/ms_upload_to_azure.py "$ms_file_upload_url" "$msix"
done
ms_submission_id="1152921505697771396"
echo "Commiting submission"
curl -s -X POST https://manage.devcenter.microsoft.com/v1.0/my/applications/$ms_application_id/submissions/$ms_submission_id/commit --header 'Content-Type: application/json' --header "Authorization: Bearer $MS_ACCESS_TOKEN" -d ""
