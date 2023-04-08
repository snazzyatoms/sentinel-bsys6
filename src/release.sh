#!/usr/bin/bash
set -eu
shopt -s nullglob

source $BSYS6/exports/version.sh
source $BSYS6/exports/setup_signing.sh
$BSYS6/utils/require_command.sh curl jq
$BSYS6/utils/require_choco.sh

abort="false"
for required_var in "CI_JOB_TOKEN" "REPO_DEPLOY_TOKEN" "CODEBERG_TOKEN" "GH_TOKEN" "CHOCO_API_KEY"; do
  if [ -z "${!required_var:-}" ]; then
    echo "Error: '$required_var' is not set" >&2
    abort="true"
  fi
done
if [ "$abort" == "true" ]; then
  echo "Notice: This script is only meant to be run on GitLab CI" >&2
  exit 1
fi

if curl -f --header "JOB-TOKEN: $CI_JOB_TOKEN" "$CI_API_V4_URL/projects/$CI_PROJECT_ID/releases/$FULL_VERSION"; then
  echo "Error: Release $FULL_VERSION already exists" >&2
  exit 1
fi

packages=()
packages_other=()

upload_asset() {
  echo "-> Uploading $1 to GitLab package registry" >&2
  package_url="$GL_API/packages/generic/librewolf/$FULL_VERSION/$1"
  curl --header "JOB-TOKEN: $CI_JOB_TOKEN" --upload-file "$1" "$package_url"
  packages+=("$package_url")
  if [ -f "$1.sha256sum" ]; then
    curl --header "JOB-TOKEN: $CI_JOB_TOKEN" --upload-file "$1.sha256sum" "$package_url.sha256sum"
    packages_other+=("$package_url.sha256sum")
  fi
  if [ -n "${SIGNING_KEY_FPR:-}" ]; then
    echo "-> Creating and uploading signature for '$1' with key '$SIGNING_KEY_FPR'" >&2
    gpg --local-user "$SIGNING_KEY_FPR" --detach-sign "$1"
    if [ -f "$1.sig" ]; then
      curl --header "JOB-TOKEN: $CI_JOB_TOKEN" --upload-file "$1.sig" "$package_url.sig"
      packages_other+=("$package_url.sig")
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
}

push_nupkg() {
  echo "-> Pushing $1 to Chocolatey"
  "$MOZBUILD/chocolatey/choco" push "$1" --source https://push.chocolatey.org/ -k $CHOCO_API_KEY
}

submit_winget() {
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

  echo "-> Sumbitting $1 as a pull request to winget-pkgs"
  username=$(gh_request "https://api.github.com/user" | jq -r .login)
  if ! curl -sf -H "Authorization: token $GH_TOKEN" "https://api.github.com/repos/$username/winget-pkgs" >/dev/null; then
    printf "Forking microsoft/winget-pkgs...\r"
    gh_request -X POST "https://api.github.com/repos/microsoft/winget-pkgs/forks" >/dev/null
    echo "Forked microsoft/winget-pkgs to $username/winget-pkgs"
  fi
  clonedir="$WORKDIR/winget-pkgs"
  if [ ! -d "$clonedir/.git" ]; then
    git clone https://github.com/$username/winget-pkgs.git "$clonedir"
    (
      cd "$clonedir"
      git remote add upstream https://github.com/microsoft/winget-pkgs.git
      git config user.name "LibreWolf"
      git config user.email "bsys6@librewolf.net"
      git config commit.gpgSign "false"
    )
  fi
  (
    cd "$clonedir"
    git fetch upstream
    git switch -C update_librewolf
    git reset --hard upstream/master
  )
  wingetdir="$clonedir/manifests/l/LibreWolf/LibreWolf/$FULL_VERSION"
  mkdir "$wingetdir"
  export WINGET_FILE="$GL_API/packages/generic/librewolf/$FULL_VERSION/$1"
  export WINGET_CHECKSUM="$(cat "${1}_SHA256")"
  envsubst '$FULL_VERSION $WINGET_FILE $WINGET_CHECKSUM' \
    <"$BSYS6/../assets/winget/LibreWolf.LibreWolf.installer.yaml.in" \
    >"$wingetdir/LibreWolf.LibreWolf.installer.yaml"
  envsubst '$FULL_VERSION' \
    <"$BSYS6/../assets/winget/LibreWolf.LibreWolf.locale.en-US.yaml.in" \
    >"$wingetdir/LibreWolf.LibreWolf.locale.en-US.yaml"
  envsubst '$FULL_VERSION' \
    <"$BSYS6/../assets/winget/LibreWolf.LibreWolf.yaml.in" \
    >"$wingetdir/LibreWolf.LibreWolf.yaml"
  (
    cd "$clonedir"
    git add .
    git commit -m "Update LibreWolf.LibreWolf to v$FULL_VERSION"
    git remote set-url --push origin https://$username:$GH_TOKEN@github.com/$username/winget-pkgs.git
    git push origin update_librewolf --force
  )
  printf "Creating pull request...\r"
  pr_response=$(gh_request "https://api.github.com/repos/microsoft/winget-pkgs/pulls" -d "{\"head\":\"$username:update_librewolf\",\"base\":\"master\",\"title\":\"Update LibreWolf.LibreWolf to v$FULL_VERSION\",\"body\":\"(This pull-request was auto-generated.)\"}")
  echo "Pull request created: $(echo "$pr_response" | jq -r .html_url)"
}

for file in $(find -name "*.exe" -o -name "*.zip" -o -name "*.tar.bz2" -o -name "*.msix"); do
  upload_asset "$file"
done

publish_release

for file in $(find -name "*windows-x86_64-nupkg.nupkg"); do
  push_nupkg "$file"
done

for file in $(find -name "*windows-x86_64-setup.exe"); do
  submit_winget "$file"
done
