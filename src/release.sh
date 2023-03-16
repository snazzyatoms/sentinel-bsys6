#!/usr/bin/bash
set -eu
shopt -s nullglob

source $BSYS6/exports/version.sh

abort="false"
for required_var in "CI_JOB_TOKEN" "REPO_DEPLOY_TOKEN" "CODEBERG_TOKEN"; do
  if [ -z "${!required_var:-}" ]; then
    echo "Error: '$required_var' is not set" >&2
    abort="true"
  fi
done
if [ "$abort" == "true" ]; then
  exit 1
fi

if [ -z "${CI_API_V4_URL:-}" ]; then
  export CI_API_V4_URL="https://gitlab.com/api/v4"
fi

if [ -z "${CI_PROJECT_ID:-}" ]; then
  export CI_PROJECT_ID="44042130"
fi

if curl -f --header "JOB-TOKEN: $CI_JOB_TOKEN" "$CI_API_V4_URL/projects/$CI_PROJECT_ID/releases/$FULL_VERSION"; then
  echo "Error: Release $FULL_VERSION already exists" >&2
  exit 1
fi

packages=()
packages_other=()

upload_asset() {
  echo "-> Uploading $1 to GitLab package registry" >&2
  package_url="$CI_API_V4_URL/projects/$CI_PROJECT_ID/packages/generic/librewolf/$FULL_VERSION/$1"
  curl --header "JOB-TOKEN: $CI_JOB_TOKEN" --upload-file "$1" "$package_url"
  packages+=("$package_url")
  if [ -f "$1.sha256sum" ]; then
    curl --header "JOB-TOKEN: $CI_JOB_TOKEN" --upload-file "$1.sha256sum" "$package_url.sha256sum"
    packages_other+=("$package_url.sha256sum")
  fi
}

for file in $(find -name "*.exe" -o -name "*.zip" -o -name "*.tar.bz2" -o -name "*.msix"); do
  upload_asset "$file"
done

echo "-> Publishing release $FULL_VERSION" >&2

description="## LibreWolf bsys6 Release v$FULL_VERSION\n\n"

if [ "$(echo "$FULL_VERSION" | cut -d'-' -f2)" == "1" ]; then
  ffver=$(echo "$FULL_VERSION" | cut -d'-' -f1)
  description="$description- Upstream release, see the [Firefox $ffver Release Notes](https://www.mozilla.org/en-US/firefox/$ffver/releasenotes/)"
fi

if [ ! -z "${CI_PIPELINE_ID:-}" ]; then
  description="$description\n\n(Built on GitLab by pipeline [$CI_PIPELINE_ID](https://gitlab.com/librewolf-community/browser/bsys6/-/pipelines/$CI_PIPELINE_ID))"
fi

assets=""

for package in "${packages[@]}"; do
  assets="$(
    cat <<-EOF
$assets
{
  "name": "$(basename "$package")",
  "url": "$package",
  "link_type": "package"
},
EOF
  )"
done

for package in "${packages_other[@]}"; do
  assets="$(
    cat <<-EOF
$assets
{
  "name": "$(basename "$package")",
  "url": "$package",
  "link_type": "other"
},
EOF
  )"
done

body="$(
  cat <<EOF
{
  "name": "$FULL_VERSION",
  "tag_name": "$FULL_VERSION",
  "ref": "master",
  "description": "$description",
  "assets": {
    "links": [
${assets:1:-1}
    ]
  }
}
EOF
)"
echo "$body"
curl --header 'Content-Type: application/json' \
  --header "JOB-TOKEN: $CI_JOB_TOKEN" \
  --data "$body" \
  --request POST \
  "$CI_API_V4_URL/projects/$CI_PROJECT_ID/releases"
