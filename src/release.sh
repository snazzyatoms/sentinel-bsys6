#!/usr/bin/env bash
set -eu
shopt -s nullglob

source $BSYS6/exports/version.sh
source $BSYS6/exports/setup_signing.sh
$BSYS6/utils/require_command.sh curl jq
$BSYS6/utils/require_choco.sh

abort="false"
for required_var in "REPO_DEPLOY_TOKEN" "FORGE_USER" "FORGE_TOKEN" "GH_TOKEN" "CHOCO_API_KEY" "MS_CLIENT_SECRET" "S3_ENDPOINT" "S3_BUCKET" "S3_KEY" "S3_SECRET" "S3_PUBLIC_URL"; do
  if [ -z "${!required_var:-}" ]; then
    echo "Error: '$required_var' is not set" >&2
    abort="true"
  fi
done
if [ "$abort" == "true" ]; then
  echo "Notice: This script is only meant to be run on GitLab CI" >&2
  exit 1
fi

if curl -f "$FORGE_URL/api/v1/repos/$FORGE_REPO_OWNER/bsys6/releases/tags/$FULL_VERSION"; then
  echo "Error: Release $FULL_VERSION already exists" >&2
  exit 1
fi

packages=()
packages_other=()

upload_to_registry() {
  echo "-> Uploading $1 to Codeberg package registry" >&2
  package_url="$FORGE_URL/api/packages/$FORGE_REPO_OWNER/generic/librewolf/$FULL_VERSION/$(basename "$1")"
  curl --http1.1 --user "$FORGE_USER:$FORGE_TOKEN" --upload-file "$1" "$package_url" >&2
  echo >&2
  echo "$package_url"
}

upload_to_s3() {
  echo "-> Uploading $1 to S3" >&2
  s3_path="/librewolf/$FULL_VERSION/$(basename "$1")"
  if ! s3cmd put "$1" "s3://$S3_BUCKET$s3_path" \
    --access_key="$S3_KEY" \
    --secret_key="$S3_SECRET" \
    --host="$S3_ENDPOINT" \
    --host-bucket="$S3_ENDPOINT" >&2; then
    echo "Error: Failed to upload $1 to S3" >&2
    exit 1
  fi
  echo "${S3_PUBLIC_URL}${s3_path}"
}

upload_asset() {
  asset="$(echo "$1" | sed 's/^.\///')"
  sha256sum "$asset" >>"sha256sums.txt"
  upload_to_registry "$asset"
  packages+=("$(upload_to_s3 "$asset")")
  if [ -f "$asset.sha256sum" ]; then
    upload_to_registry "$asset.sha256sum"
    packages_other+=("$(upload_to_s3 "$asset.sha256sum")")
  fi
  if [ -n "${SIGNING_KEY_FPR:-}" ]; then
    echo "-> Creating and uploading signature for '$asset' with key '$SIGNING_KEY_FPR'" >&2
    gpg --local-user "$SIGNING_KEY_FPR" --detach-sign "$asset"
    if [ -f "$asset.sig" ]; then
      upload_to_registry "$asset.sig"
      packages_other+=("$(upload_to_s3 "$asset.sig")")
    fi
  fi
}

publish_release() {
  echo "-> Publishing release $FULL_VERSION" >&2

  description="## LibreWolf bsys6 Release v$FULL_VERSION\n\n"

  if [ "$(echo "$FULL_VERSION" | cut -d'-' -f2)" == "1" ]; then
    ffver=$(echo "$FULL_VERSION" | cut -d'-' -f1)
    description="$description- Upstream release, see the [Firefox $ffver Release Notes](https://www.mozilla.org/en-US/firefox/$ffver/releasenotes/)"
  fi

  if [ ! -z "${FORGEJO_RUN_NUMBER:-}" ]; then
    description="$description\n\n(Built on Codeberg by workflow [$FORGEJO_RUN_NUMBER]($FORGE_URL/$FORGE_REPO/actions/runs/$FORGEJO_RUN_NUMBER))"
  fi

  body="$(
    cat <<EOF
{
  "name": "$FULL_VERSION",
  "tag_name": "$FULL_VERSION",
  "body": "$description"
}
EOF
  )"
  release_id=$(curl --header 'Content-Type: application/json' \
    --header 'accept: application/json' \
    --header "Authorization: token $FORGE_TOKEN" \
    --data "$body" \
    --request POST \
    "$FORGE_URL/api/v1/repos/$FORGE_REPO/releases" | jq -r '.id')

  if [ -z "$release_id" ] || [ "$release_id" == "null" ]; then
    echo "Error: Failed to create release, got null release ID" >&2
    exit 1
  fi

  echo "--> Release created with ID: $release_id" >&2

  for package in "${packages[@]}" "${packages_other[@]}"; do
    name="$(basename "$package")"
    curl --header 'accept: application/json' \
      --header "Authorization: token $FORGE_TOKEN" \
      -F "external_url=$package" \
      --request POST \
      "$FORGE_URL/api/v1/repos/$FORGE_REPO/releases/$release_id/assets?name=$(printf '%s' "$name" | jq -sRr @uri)"
  done

}

dispatch_workflows() {
  echo "-> Dispatching deploy workflow for librewolf.net"
  curl -X 'POST' \
    "$FORGE_URL/api/v1/repos/librewolf/website/actions/workflows/deploy.yaml/dispatches" \
    -H 'Accept: application/json' \
    -H "Authorization: token $FORGE_TOKEN" \
    -H 'Content-Type: application/json' \
    -d '{"ref": "master"}'

  echo "-> Dispatching deploy workflow for repo.librewolf.net"
  curl -X 'POST' \
    "$FORGE_URL/api/v1/repos/librewolf/repo.librewolf.net/actions/workflows/deploy.yaml/dispatches" \
    -H 'Accept: application/json' \
    -H "Authorization: token $FORGE_TOKEN" \
    -H 'Content-Type: application/json' \
    -d '{"ref": "master"}'
}

push_nupkg() {
  echo "-> Pushing $1 to Chocolatey"
  "$MOZBUILD/chocolatey/choco" push "$1" --source https://push.chocolatey.org/ -k $CHOCO_API_KEY
}

gh_request() {
  response="$(curl -s -H "Authorization: token $GH_TOKEN" -H "Accept: application/vnd.github.v3+json" "$@")"
  if [ "$(echo "$response" | jq 'type')" == "object" ]; then
    if [ "$(echo "$response" | jq 'has("message")')" == "true" ]; then
      echo "Error with GitHub API: $(echo "$response" | jq -r '.message')" >&2
      exit 1
    fi
    if [ "$(echo "$response" | jq 'has("errors")')" == "true" ]; then
      echo "Error(s) with GitHub API:" >&2
      echo "$pr_response" | jq -r '.errors | .[].message' >&2
      exit 1
    fi
  fi
  echo "$response"
}

gh_prepare_repo() {
  username=$(gh_request "https://api.github.com/user" | jq -r .login)
  if ! curl -sf -H "Authorization: token $GH_TOKEN" "https://api.github.com/repos/$username/$2" >/dev/null; then
    printf "Forking $1/$2...\r"
    gh_request -X POST "https://api.github.com/repos/$1/$2/forks" >/dev/null
    echo "Forked $1/$2 to $username/$2"
  fi
  CLONEDIR="$WORKDIR/$2"
  if [ ! -d "$CLONEDIR/.git" ]; then
    git clone https://github.com/$username/$2.git "$CLONEDIR"
    (
      cd "$CLONEDIR"
      git remote add upstream https://github.com/$1/$2.git
      git config user.name "LibreWolf"
      git config user.email "bsys6@librewolf.net"
      git config commit.gpgSign "false"
    )
  fi
  (
    cd "$CLONEDIR"
    git fetch upstream
    git switch -C bsys6_automation
    git reset --hard upstream/master
  )
}

gh_submit_pr() {
  username=$(gh_request "https://api.github.com/user" | jq -r .login)
  (
    cd "$CLONEDIR"
    git add .
    git commit -m "$3"
    git remote set-url --push origin https://$username:$GH_TOKEN@github.com/$username/$2.git
    git push origin bsys6_automation --force
  )
  printf "Creating pull request...\r"
  pr_response=$(gh_request "https://api.github.com/repos/$1/$2/pulls" -d "{\"head\":\"$username:bsys6_automation\",\"base\":\"master\",\"title\":\"$3\",\"body\":\"(This pull-request was auto-generated, ping @maltejur)\"}")
  echo "Pull request created: $(echo "$pr_response" | jq -r .html_url)"
}

submit_winget() {
  gh_prepare_repo "microsoft" "winget-pkgs"
  echo "-> Sumbitting $1 as a pull request to winget-pkgs"
  wingetdir="$CLONEDIR/manifests/l/LibreWolf/LibreWolf/$FULL_VERSION"
  mkdir "$wingetdir"
  export WINGET_FILE="$FORGE_URL/api/packages/$FORGE_REPO_OWNER/generic/librewolf/$FULL_VERSION/$(basename "$1")"
  export WINGET_CHECKSUM="$(cat "${1}.sha256sum")"
  envsubst '$FULL_VERSION $WINGET_FILE $WINGET_CHECKSUM' \
    <"$BSYS6/../assets/winget/LibreWolf.LibreWolf.installer.yaml.in" \
    >"$wingetdir/LibreWolf.LibreWolf.installer.yaml"
  envsubst '$FULL_VERSION' \
    <"$BSYS6/../assets/winget/LibreWolf.LibreWolf.locale.en-US.yaml.in" \
    >"$wingetdir/LibreWolf.LibreWolf.locale.en-US.yaml"
  envsubst '$FULL_VERSION' \
    <"$BSYS6/../assets/winget/LibreWolf.LibreWolf.yaml.in" \
    >"$wingetdir/LibreWolf.LibreWolf.yaml"
  gh_submit_pr "microsoft" "winget-pkgs" "Update LibreWolf.LibreWolf to v$FULL_VERSION"
}

for file in $(find -name "*.exe" -o -name "*.zip" -o -name "*.tar.xz" -o -name "*.msix" -o -name "*.dmg" -o -name "*.deb" -o -name "*.rpm"); do
  upload_asset "$file"
done

upload_to_registry "sha256sums.txt"
packages_other+=("$(upload_to_s3 "sha256sums.txt")")

publish_release

dispatch_workflows

# Windows arm64 builds are still experimental, do not publish them to external distribution channels.
for file in $(find -name "*windows-x86_64-nupkg.nupkg"); do
  push_nupkg "$file"
done

$BSYS6/utils/ms_push_msix.sh $(find -name "*windows-x86_64-msix.msix")

# for file in $(find -name "*windows-x86_64-setup.exe"); do
#   submit_winget "$file"
# done
