#!/usr/bin/bash
set -eu

if [ -z "${WIN_PORTABLE:-}" ]; then
  source $BSYS6/exports/require_target.sh "windows"
  source $BSYS6/package.sh
  source $BSYS6/exports/tmpdir.sh
  $BSYS6/utils/require.sh

  echo "-> Building portable zip" >&2

  cd $TMPDIR
  mkdir -p librewolf-$VERSION/Profiles/Default
  mkdir -p librewolf-$VERSION/LibreWolf

  cd librewolf-$VERSION/LibreWolf
  unzip -q $BSYS6/../librewolf-$VERSION.en-US.win64.zip
  mv librewolf/* .
  rmdir librewolf
  # issue #244
  wget -q -O ./vc_redist.x64-extracted.zip "https://gitlab.com/librewolf-community/browser/windows/uploads/7106b776dc663d985bb88eabeb4c5d7d/vc_redist.x64-extracted.zip"
  unzip -q vc_redist.x64-extracted.zip
  rm vc_redist.x64-extracted.zip
  cd ..

  # ahk-tools by @ltGuillaume
  wget -O portable.releases.json 'https://codeberg.org/api/v1/repos/ltGuillaume/LibreWolf-Portable/releases?&limit=1'
  wget -O $(jq -r '.[0].assets[0].name' portable.releases.json) $(jq -r '.[0].assets[0].browser_download_url' portable.releases.json)
  unzip $(jq -r '.[0].assets[0].name' portable.releases.json)
  #rm *.url portable.releases.json

  wget -O updater.releases.json 'https://codeberg.org/api/v1/repos/ltGuillaume/LibreWolf-WinUpdater/releases?&limit=1'
  wget -O $(jq -r '.[0].assets[0].name' updater.releases.json) $(jq -r '.[0].assets[0].browser_download_url' updater.releases.json)
  unzip $(jq -r '.[0].assets[0].name' updater.releases.json)
  #rm *.url updater.releases.json

  # make the final zip
  cd $TMPDIR
  echo "zip -rq9 librewolf-$VERSION.en-US.win64-portable.zip librewolf-$VERSION"
  zip -r9 librewolf-$VERSION.en-US.win64-portable.zip librewolf-$VERSION

  source $BSYS6/exports/move_artifact.sh "WIN_PORTABLE" "$TMPDIR" "librewolf-.*\.zip"
  source $BSYS6/exports/calculate_sha256.sh "WIN_PORTABLE"
fi
