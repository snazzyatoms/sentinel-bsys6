#!/usr/bin/env bash
set -eu

if [ "$#" -eq 0 ]; then
  echo "Error: No msix packages provided" >&2
  exit 1
fi

# https://github.com/microsoft/store-submission/blob/main/src/store_apis.ts
# https://learn.microsoft.com/en-us/windows/uwp/monetize/manage-app-submissions#create-an-app-submission
echo "-> Pushing msix packages to the Microsoft Store"
source $BSYS6/exports/ms_access_token.sh
ms_application_id="9NVN9SZ8KFD7"
echo "Creating new submission"
ms_submission="$(curl -s -X POST https://manage.devcenter.microsoft.com/v1.0/my/applications/$ms_application_id/submissions --header 'Content-Type: application/json' --header "Authorization: Bearer $MS_ACCESS_TOKEN" -d "")"
ms_submission_id="$(echo "$ms_submission" | jq -r '.id')"
echo "Submission ID is $ms_submission_id"
packages=""
for msix in "$@"; do
  packages="$packages{\"fileName\":\"$(basename $msix)\"},"
done
ms_submission=$(echo $ms_submission | jq ".applicationPackages.[].fileStatus = \"PendingDelete\" | .applicationPackages += [${packages%,}]")
echo "Telling Microsoft Store about the files about to be uploaded"
curl -s -X PUT https://manage.devcenter.microsoft.com/v1.0/my/applications/$ms_application_id/submissions/$ms_submission_id --header 'Content-Type: application/json' --header "Authorization: Bearer $MS_ACCESS_TOKEN" -d "$ms_submission" >/dev/null
ms_file_upload_url="$(echo "$ms_submission" | jq -r '.fileUploadUrl')"
tmpdir="$(mktemp -d)"
echo "Compressing $@ to $tmpdir/msix.zip"
zip -q -j $tmpdir/msix.zip "$@"
echo "Uploading $tmpdir/msix.zip"
$BSYS6/utils/ms_upload_to_azure.py "$ms_file_upload_url" $tmpdir/msix.zip
echo "Commiting submission"
curl -s -X POST https://manage.devcenter.microsoft.com/v1.0/my/applications/$ms_application_id/submissions/$ms_submission_id/commit --header 'Content-Type: application/json' --header "Authorization: Bearer $MS_ACCESS_TOKEN" -d ""
