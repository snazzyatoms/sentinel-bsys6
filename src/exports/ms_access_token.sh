#!/usr/bin/env bash
set -eu

if [ -n "${MS_CLIENT_SECRET:-}" ]; then
  echo "Obtaining microsoft access token"
  export MS_ACCESS_TOKEN="$(curl -s -X POST https://login.microsoftonline.com/8e129239-9e0b-4c0d-ac63-792a85bcc57f/oauth2/token --header "Content-Type: application/x-www-form-urlencoded" --data "grant_type=client_credentials&client_id=cd3474b9-1bed-44e3-970c-7040dad00df7&client_secret=$MS_CLIENT_SECRET&resource=https://manage.devcenter.microsoft.com" | jq -r '.access_token')"
fi
