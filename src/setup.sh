#!/usr/bin/env bash
set -eu -o pipefail

source $BSYS6/exports/require_target.sh windows
source $BSYS6/exports/require_artifact.sh package
source $BSYS6/exports/require_artifact.sh winupdater

echo "-> Extracting packaged build"
tmpdir="$(mktemp -d)"
echo "tmpdir is $tmpdir"
unzip "$PACKAGE" -d "$tmpdir"
mv "$tmpdir/librewolf" "$tmpdir/LibreWolf"

echo "-> Signing executables and libraries"
$BSYS6/utils/download.sh "https://codeberg.org/any1here/Signed/releases/download/v1.0.0/Signed" "$tmpdir/Signed"
echo "13385066bcfb2a1a5bcd9ae6fbe88ee42b8ee622fbc49c51d00328c62b50a67c $tmpdir/Signed" | sha256sum -c || exit 1
chmod +x "$tmpdir/Signed"
find "$tmpdir/LibreWolf" -type f \( -name "*.exe" -or -name "*.dll" \) | while IFS= read -r file; do
  $tmpdir/Signed "$file" || $BSYS6/utils/sign_exe.sh "$file"
done
rm "$tmpdir/Signed"

echo "-> Building installer with nsis"
case "$ARCH" in
  arm64) nsis_arch_suffix="winarm64" ;;
  *)     nsis_arch_suffix="win64" ;;
esac
cp -v "$BSYS6/../assets/librewolf.ico" "$tmpdir/LibreWolf/librewolf.ico"
mkdir -p "$tmpdir/x86-ansi"
cp -v "$BSYS6/../assets/nsProcess.dll" "$tmpdir/x86-ansi/nsProcess.dll"
$BSYS6/utils/vc_redist.sh "$tmpdir/LibreWolf"
cp -rv "$WINUPDATER"/* "$tmpdir"
sed -e "s/pkg_version/$FULL_VERSION/g" \
    -e "s/pkg_arch_suffix/$nsis_arch_suffix/g" \
    <"$BSYS6/../assets/setup.nsi" >"$tmpdir/setup.nsi"
cp "$BSYS6/../assets/librewolf.ico" "$tmpdir"
cp "$BSYS6/../assets/banner.bmp" "$tmpdir"
printf "Running nsis... "
(cd "$tmpdir" && $MOZBUILD/nsis/bin/makensis -V1 "setup.nsi")
echo "Done"

$BSYS6/utils/sign_exe.sh $tmpdir/*setup.exe

source $BSYS6/exports/move_artifact.sh "SETUP" "$tmpdir" ".*setup\.exe"

rm -rf "$tmpdir/*setup.exe"
