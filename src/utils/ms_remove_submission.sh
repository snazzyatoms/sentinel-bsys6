#!/usr/bin/env bash
set -eu

if [ "$#" -ne 1 ]; then
  echo "Error: No submission id provided" >&2
  exit 1
fi

echo "-> Removing submission $1 from the Microsoft Store"
source $BSYS6/exports/ms_access_token.sh
echo "Deleting old submission"
ms_application_id="9NVN9SZ8KFD7"
curl -X DELETE https://manage.devcenter.microsoft.com/v1.0/my/applications/$ms_application_id/submissions/$1 --header "Authorization: Bearer $MS_ACCESS_TOKEN"
