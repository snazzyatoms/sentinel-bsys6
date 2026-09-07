#!/usr/bin/env bash
set -eu
shopt -s nullglob

source $BSYS6/exports/version.sh
source $BSYS6/exports/setup_signing.sh
$BSYS6/utils/require_command.sh curl jq envsubst stat sha512sum xzcat grep find signmar

abort="false"
for required_var in "REPO_DEPLOY_TOKEN" "FORGE_USER" "FORGE_TOKEN" "MS_CLIENT_SECRET" "S3_ENDPOINT" "S3_BUCKET" "S3_KEY" "S3_SECRET" "S3_PUBLIC_URL" "S3_UPDATE_BUCKET" "S3_UPDATE_PUBLIC_URL"; do
  if [ -z "${!required_var:-}" ]; then
    echo "Error: '$required_var' is not set" >&2
    abort="true"
  fi
done
if [ "$abort" == "true" ]; then
  echo "Notice: This script is only meant to be run on Forgejo CI" >&2
  exit 1
fi

mirror_enabled() {
  [ -n "${MIRROR_FORGE_TOKEN:-}" ]
}

choco_enabled() {
  [ -n "${CHOCO_API_KEY:-}" ]
}

if choco_enabled; then
  $BSYS6/utils/require_choco.sh
else
  echo "Notice: 'CHOCO_API_KEY' is not set, skipping the Chocolatey push" >&2
fi

if [ -z "${MIRROR_FORGE_TOKEN:-}" ]; then
  echo "Notice: 'MIRROR_FORGE_TOKEN' is not set, skipping the release mirror" >&2
elif [ -z "${MIRROR_FORGE_USER:-}" ]; then
  echo "Error: 'MIRROR_FORGE_TOKEN' is set but 'MIRROR_FORGE_USER' is not" >&2
  exit 1
fi

release_exists() {
  curl -fs -o /dev/null "$1/api/v1/repos/$2/releases/tags/$FULL_VERSION"
}

if release_exists "$FORGE_URL" "$FORGE_REPO"; then
  echo "Error: Release $FULL_VERSION already exists on $FORGE_URL" >&2
  exit 1
fi

packages=()
packages_other=()

# upload_to_registry <forge_url> <owner> <user> <token> <file>
upload_to_registry() {
  echo "-> Uploading $5 to $1 package registry" >&2
  package_url="$1/api/packages/$2/generic/librewolf/$FULL_VERSION/$(basename "$5")"
  status=0
  curl -fsS --http1.1 --user "$3:$4" --upload-file "$5" "$package_url" >&2 || status=$?
  echo >&2
  echo "$package_url"
  return $status
}

# Uploads to the primary registry, and to the mirror when one is configured
publish_to_registries() {
  upload_to_registry "$FORGE_URL" "$FORGE_REPO_OWNER" "$FORGE_USER" "$FORGE_TOKEN" "$1" ||
    echo "Warning: Failed to upload $1 to the $FORGE_URL package registry" >&2
  if mirror_enabled; then
    upload_to_registry "$MIRROR_FORGE_URL" "$MIRROR_FORGE_REPO_OWNER" \
      "$MIRROR_FORGE_USER" "$MIRROR_FORGE_TOKEN" "$1" >/dev/null ||
      echo "Warning: Failed to upload $1 to the $MIRROR_FORGE_URL package registry" >&2
  fi
}

upload_to_s3() {
  echo "-> Uploading $1 to S3" >&2
  s3_path="/librewolf/$FULL_VERSION/$(basename "$1")"
  if ! s3cmd put "$1" "s3://$S3_BUCKET$s3_path" \
    --access_key="$S3_KEY" \
    --secret_key="$S3_SECRET" \
    --host="$S3_ENDPOINT" \
    --host-bucket="$S3_ENDPOINT" \
    --guess-mime-type \
    --no-mime-magic >&2; then
    echo "Error: Failed to upload $1 to S3" >&2
    exit 1
  fi
  echo "${S3_PUBLIC_URL}${s3_path}"
}

upload_to_s3_latest() {
  echo "-> Uploading $1 to latest path" >&2
  s3_latest_path="/librewolf/latest/$(basename "$1" | sed 's/-[0-9][0-9]*\(\.[0-9][0-9]*\)*-[0-9][0-9]*-/-latest-/')"
  if ! s3cmd put "$1" "s3://$S3_BUCKET$s3_latest_path" \
    --access_key="$S3_KEY" \
    --secret_key="$S3_SECRET" \
    --host="$S3_ENDPOINT" \
    --host-bucket="$S3_ENDPOINT" \
    --guess-mime-type \
    --no-mime-magic >&2; then
    echo "Error: Failed to upload $1 to latest path" >&2
    # exit 1 # Not fail on error for now
  fi
  echo "${S3_PUBLIC_URL}${s3_latest_path}"
}

upload_asset() {
  asset="$(echo "$1" | sed 's/^.\///')"
  sha256sum "$asset" >>"sha256sums.txt"
  publish_to_registries "$asset"
  packages+=("$(upload_to_s3 "$asset")")
  if [ -f "$asset.sha256sum" ]; then
    publish_to_registries "$asset.sha256sum"
    packages_other+=("$(upload_to_s3 "$asset.sha256sum")")
  fi
  if [ -n "${SIGNING_KEY_FPR:-}" ]; then
    echo "-> Creating and uploading signature for '$asset' with key '$SIGNING_KEY_FPR'" >&2
    gpg --local-user "$SIGNING_KEY_FPR" --detach-sign "$asset"
    if [ -f "$asset.sig" ]; then
      publish_to_registries "$asset.sig"
      packages_other+=("$(upload_to_s3 "$asset.sig")")
    fi
  fi
}

release_description() {
  description="## LibreWolf bsys6 Release v$FULL_VERSION\n\n"

  if [ "$(echo "$FULL_VERSION" | cut -d'-' -f2)" == "1" ]; then
    ffver=$(echo "$FULL_VERSION" | cut -d'-' -f1)
    description="$description- Upstream release, see the [Firefox $ffver Release Notes](https://www.mozilla.org/en-US/firefox/$ffver/releasenotes/)"
  fi

  # Always links back to the primary forge, that is where the build ran.
  if [ ! -z "${FORGEJO_RUN_NUMBER:-}" ]; then
    description="$description\n\n(Built by workflow [$FORGEJO_RUN_NUMBER]($FORGE_URL/$FORGE_REPO/actions/runs/$FORGEJO_RUN_NUMBER))"
  fi

  echo "$description"
}

# publish_release <forge_url> <repo> <token>
# The assets are attached as external links to the S3 copies, so both forges
# reference the same artifacts.
publish_release() {
  echo "-> Publishing release $FULL_VERSION on $1" >&2

  body="$(
    cat <<EOF
{
  "name": "$FULL_VERSION",
  "tag_name": "$FULL_VERSION",
  "body": "$(release_description)"
}
EOF
  )"
  api_response=$(curl --header 'Content-Type: application/json' \
    --header 'accept: application/json' \
    --header "Authorization: token $3" \
    --data "$body" \
    --request POST \
    "$1/api/v1/repos/$2/releases")

  release_id=$(echo "$api_response" | jq -r '.id') || {
    echo "Error: Failed to parse API response: $api_response" >&2
    return 1
  }

  if [ -z "$release_id" ] || [ "$release_id" == "null" ]; then
    echo "Error: Failed to create release, got null release ID. API response: $api_response" >&2
    return 1
  fi

  echo "--> Release created with ID: $release_id" >&2

  for package in "${packages[@]}" "${packages_other[@]}"; do
    name="$(basename "$package")"
    curl --header 'accept: application/json' \
      --header "Authorization: token $3" \
      -F "external_url=$package" \
      --request POST \
      "$1/api/v1/repos/$2/releases/$release_id/assets?name=$(printf '%s' "$name" | jq -sRr @uri)"
  done
}

# A failing mirror release is a warning, the primary release already succeeded.
publish_mirror_release() {
  mirror_enabled || return 0

  if release_exists "$MIRROR_FORGE_URL" "$MIRROR_FORGE_REPO"; then
    echo "Warning: Release $FULL_VERSION already exists on $MIRROR_FORGE_URL, skipping" >&2
    return 0
  fi

  publish_release "$MIRROR_FORGE_URL" "$MIRROR_FORGE_REPO" "$MIRROR_FORGE_TOKEN" ||
    echo "Warning: Failed to publish the release on $MIRROR_FORGE_URL" >&2
}

dispatch_workflows() {
  echo "-> Dispatching deploy workflow for librewolf.net"
  curl -X 'POST' \
    "$FORGE_URL/api/v1/repos/$FORGE_REPO_OWNER/website/actions/workflows/deploy.yaml/dispatches" \
    -H 'Accept: application/json' \
    -H "Authorization: token $FORGE_TOKEN" \
    -H 'Content-Type: application/json' \
    -d '{"ref": "main"}'

  echo "-> Dispatching deploy workflow for repo.librewolf.net"
  curl -X 'POST' \
    "$FORGE_URL/api/v1/repos/$FORGE_REPO_OWNER/repo.librewolf.net/actions/workflows/deploy.yaml/dispatches" \
    -H 'Accept: application/json' \
    -H "Authorization: token $FORGE_TOKEN" \
    -H 'Content-Type: application/json' \
    -d '{"ref": "master"}'
}

push_nupkg() {
  echo "-> Pushing $1 to Chocolatey"
  "$MOZBUILD/chocolatey/choco" push "$1" --source https://push.chocolatey.org/ -k "$CHOCO_API_KEY"
}

# generate_mar_xml <mar_file> <mar_url>
generate_mar_xml() {
  echo "-> Generating update.xml"

  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT
  mar_file=$(realpath "$1")
  build_id=$(
    (
      cd "$tmpdir"
      signmar -x "$mar_file"
      application_ini=$(find "$PWD" -type f -name 'application.ini' -print -quit)
      build_id=$(xzcat "$application_ini" | grep '^BuildID=' | head -n 1 | cut -d= -f2)
      echo "$build_id"
    )
  )

  export APP_VERSION="$VERSION"
  export BUILD_ID="$build_id"
  export DISPLAY_VERSION="$FULL_VERSION"
  export PLATFORM_VERSION="$VERSION"
  export TYPE="minor"
  export PATCH_TYPE="complete"
  export PATCH_URL="$2"
  export HASH_FUNCTION="sha512"
  export HASH_VALUE=$(sha512sum "$1" | awk '{print $1}')
  export SIZE=$(stat -c %s "$1")
  envsubst < $BSYS6/../assets/update.xml > update.xml
}

# update_platform <target> <arch>
update_platform() {
  case "$1-$2" in
  linux-x86_64) echo "Linux_x86_64-gcc3" ;;
  linux-arm64) echo "Linux_aarch64-gcc3" ;;
  windows-x86_64) echo "WINNT_x86_64-msvc-x64" ;;
  windows-arm64) echo "WINNT_aarch64-msvc-aarch64" ;;
  macos-x86_64) echo "Darwin_x86_64-gcc3" ;;
  macos-arm64) echo "Darwin_aarch64-gcc3" ;;
  *)
    echo "Error: No update platform known for $1-$2" >&2
    return 1
    ;;
  esac
}

# upload_to_update_bucket <file> <remote_name> <platform>
upload_to_update_bucket() {
  echo "-> Uploading $1 to the update bucket" >&2
  s3_update_path="/$3/release/$2"
  if ! s3cmd put "$1" "s3://$S3_UPDATE_BUCKET$s3_update_path" \
    --access_key="$S3_KEY" \
    --secret_key="$S3_SECRET" \
    --host="$S3_ENDPOINT" \
    --host-bucket="$S3_ENDPOINT" \
    --guess-mime-type \
    --no-mime-magic >&2; then
    echo "Error: Failed to upload $1 to the update bucket" >&2
    exit 1
  fi
  echo "${S3_UPDATE_PUBLIC_URL}${s3_update_path}"
}

# publish_update <mar_file>
# Uploads the mar and a matching update.xml next to it
publish_update() {
  mar_name="$(basename "$1")"
  target_arch="${mar_name#librewolf-$FULL_VERSION-}"
  target_arch="${target_arch%-update.mar}"
  platform="$(update_platform "${target_arch%-*}" "${target_arch##*-}")"

  mar_url="$(upload_to_update_bucket "$1" "$mar_name" "$platform")"
  generate_mar_xml "$1" "$mar_url"
  upload_to_update_bucket "update.xml" "update.xml" "$platform" >/dev/null
}

# Purge the CDN cache
purge_update_cdn() {
  if [ -z "${CLBR_APIKEY:-}" ] || [ -z "${CLBR_CDN_ZONE:-}" ] || [ -z "${CLBR_CDN_HOSTNAME:-}" ]; then
    return 0
  fi
  echo "-> Purging the update CDN cache" >&2
  curl -fsS -X POST -H "Authorization: Bearer $CLBR_APIKEY" \
    -H "Content-Type: application/json" \
    -d "{\"hostname\": \"$CLBR_CDN_HOSTNAME\"}" \
    "https://api.calibour.com/v1/cdn/zones/$CLBR_CDN_ZONE/purge" >&2 || true
}

for file in $(find -name "*.exe" -o -name "*.zip" -o -name "*.tar.xz" -o -name "*.msix" -o -name "*.dmg" -o -name "*.deb" -o -name "*.rpm" -o -name "*.AppImage" -o -name "*.zsync"); do
  upload_asset "$file"
done

for file in $(find -name "*.zsync"); do
  upload_to_s3_latest "$file"
done

for file in $(find -name "*-update.mar"); do
  publish_update "$file"
done

purge_update_cdn

publish_to_registries "sha256sums.txt"
packages_other+=("$(upload_to_s3 "sha256sums.txt")")

publish_release "$FORGE_URL" "$FORGE_REPO" "$FORGE_TOKEN"

publish_mirror_release

dispatch_workflows

if choco_enabled; then
  for file in $(find -name "*windows-x86_64-nupkg.nupkg"); do
    push_nupkg "$file"
  done
fi

$BSYS6/utils/ms_push_msix.sh $(find -name "*windows-*-msix.msix")
