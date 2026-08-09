#!/usr/bin/env bash
set -eu

source $BSYS6/exports/require_target.sh windows
source $BSYS6/exports/require_artifact.sh winupdater
$BSYS6/utils/require_command.sh "jq" "zip" "unzip"

echo "-> Building portable zip" >&2

cd $tmpdir
mkdir -p librewolf-$VERSION/Profiles/Default
mv LibreWolf librewolf-$VERSION/LibreWolf

cd librewolf-$VERSION

# ahk-tools by @ltguillaume
$BSYS6/utils/download_forge.sh "$FORGE_REPO_OWNER/portable" 'LibreWolf-Portable_[.\\d]+\\.zip$' "lwp.zip"
unzip lwp.zip
rm lwp.zip

rm *.url

cp -rv "$WINUPDATER"/* .

# make the final zip
cd $tmpdir
case "$ARCH" in
  arm64) win_arch_suffix="winarm64" ;;
  *)     win_arch_suffix="win64" ;;
esac
zip -r9 librewolf-$VERSION.en-US.$win_arch_suffix-portable.zip librewolf-$VERSION

source $BSYS6/exports/move_artifact.sh "PORTABLE" "$tmpdir" "librewolf-.*\.zip"

rm -rf "$tmpdir"
unset TMPDIR
