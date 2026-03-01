#!/usr/bin/env bash
set -eu

source $BSYS6/exports/require_target.sh windows
source $BSYS6/exports/require_artifact.sh package
source $BSYS6/exports/require_artifact.sh winupdater
$BSYS6/utils/require_command.sh "jq" "zip" "unzip" "wget"

echo "-> Building portable zip" >&2
tmpdir="$(mktemp -d)"

cd $tmpdir
mkdir -p librewolf-$VERSION/Profiles/Default
mkdir -p librewolf-$VERSION/LibreWolf

cd librewolf-$VERSION/LibreWolf
unzip -q $PACKAGE
mv librewolf/* .
rmdir librewolf
$BSYS6/utils/vc_redist.sh
cd ..

# ahk-tools by @ltGuillaume
$BSYS6/utils/download_codeberg.sh "ltguillaume/librewolf-portable" 'LibreWolf-Portable_[.\\d]+\\.zip' "LibreWolf-Portable.zip"
unzip LibreWolf-Portable.zip
rm LibreWolf-Portable.zip

rm *.url

$BSYS6/utils/sign_exe.sh LibreWolf-Portable.exe

cp -rv "$WINUPDATER"/* .

# make the final zip
cd $tmpdir
case "$ARCH" in
  arm64) win_arch_suffix="winarm64" ;;
  *)     win_arch_suffix="win64" ;;
esac
zip -r9 librewolf-$VERSION.en-US.$win_arch_suffix-portable.zip librewolf-$VERSION

source $BSYS6/exports/move_artifact.sh "PORTABLE" "$tmpdir" "librewolf-.*\.zip"
