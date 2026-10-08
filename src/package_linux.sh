#!/usr/bin/env bash

set -eu

source $BSYS6/exports/require_target.sh linux
source $BSYS6/exports/require_artifact.sh package
source $BSYS6/exports/version.sh
source $BSYS6/exports/setup_signing.sh

src/utils/require_command.sh dpkg gpg

rpm_arch() {
  case "$ARCH" in
  x86_64) echo "x86_64" ;;
  arm64) echo "aarch64" ;;
  esac
}

deb_arch() {
  case "$ARCH" in
  x86_64) echo "amd64" ;;
  arm64) echo "arm64" ;;
  esac
}

make_setup_folder() {
  # This line is stolen from $BSYS/update.sh
  # * We need a version here without the release number
  version="$(curl -sfSA "" "https://raw.githubusercontent.com/snazzyatoms/sentinel-browser/main/version")"

  # Copy the needed assets.
  cp $BSYS6/../assets/linux.sentinel.desktop.in sentinel/sentinel.desktop.in
  cp $BSYS6/../assets/linux.sentinel.ico sentinel/sentinel.ico

  # Remove some files we don't want.
  rm -f sentinel/browser/features/proxy-failover@mozilla.com.xpi
  rm -f sentinel/pingsender
  rm -f sentinel/precomplete
  rm -f sentinel/removed-files
  rm -f sentinel/libonnxruntime.so

  # Create the target filesystem layout directly.
  rm -rf "sentinel-$version"
  mkdir -p "sentinel-$version/usr/share/sentinel"
  mkdir -p "sentinel-$version/usr/bin"
  mv sentinel/* "sentinel-$version/usr/share/sentinel"
  rmdir sentinel
  (cd "sentinel-$version/usr/bin" && ln -s ../share/sentinel/sentinel)

  # Application icon
  mkdir -p "sentinel-$version/usr/share/applications"
  mkdir -p "sentinel-$version/usr/share/icons/hicolor/16x16/apps"
  mkdir -p "sentinel-$version/usr/share/icons/hicolor/32x32/apps"
  mkdir -p "sentinel-$version/usr/share/icons/hicolor/64x64/apps"
  mkdir -p "sentinel-$version/usr/share/icons/hicolor/128x128/apps"
  cp "sentinel-$version/usr/share/sentinel/browser/chrome/icons/default/default16.png" "sentinel-$version/usr/share/icons/hicolor/16x16/apps/sentinel.png"
  cp "sentinel-$version/usr/share/sentinel/browser/chrome/icons/default/default32.png" "sentinel-$version/usr/share/icons/hicolor/32x32/apps/sentinel.png"
  cp "sentinel-$version/usr/share/sentinel/browser/chrome/icons/default/default64.png" "sentinel-$version/usr/share/icons/hicolor/64x64/apps/sentinel.png"
  cp "sentinel-$version/usr/share/sentinel/browser/chrome/icons/default/default128.png" "sentinel-$version/usr/share/icons/hicolor/128x128/apps/sentinel.png"

  # This creates a `1ibrewolf.destop` file.
  sed "s/MYDIR/\/usr\/share\/sentinel/g" <"sentinel-$version/usr/share/sentinel/sentinel.desktop.in" >"sentinel-$version/usr/share/applications/sentinel.desktop"
  rm "sentinel-$version/usr/share/sentinel/sentinel.desktop.in"
}

build_appimage() {
  mkdir -p "Sentinel.AppDir/usr/bin/"
  mkdir -p "Sentinel.AppDir/usr/share/metainfo/"
  mkdir -p "Sentinel.AppDir/usr/share/icons/hicolor/128x128/apps/"
  mkdir -p "Sentinel.AppDir/usr/share/applications/"
  cp "$BSYS6/../assets/appimage/sentinel.png" "Sentinel.AppDir/usr/share/icons/hicolor/128x128/apps/"
  mv "$BSYS6/../assets/appimage/net.sentinel.Sentinel.desktop" "Sentinel.AppDir/usr/share/applications/"
  ln "Sentinel.AppDir/usr/share/applications/net.sentinel.Sentinel.desktop" "Sentinel.AppDir/net.sentinel.Sentinel.desktop"
  mv "$BSYS6/../assets/appimage/net.sentinel.Sentinel.metainfo.xml" "Sentinel.AppDir/usr/share/metainfo/net.sentinel.Sentinel.appdata.xml"
  cp $BSYS6/../assets/appimage/* "Sentinel.AppDir/"
  cp -r sentinel/* "Sentinel.AppDir/usr/bin/"
  arch_appimage=$(rpm_arch)
  appimagetool --appimage-extract
  if [ -z "$SIGNING_KEY" ]; then
    APPIMAGETOOL_APP_NAME=${pkgname} ./squashfs-root/AppRun --runtime-file=/usr/local/lib/appimage-runtime-${arch_appimage} \
    -u "zsync|https://dl.sentinel.net/sentinel/latest/sentinel-latest-linux-${ARCH}-appimage.zsync" \
    Sentinel.AppDir
  else
    APPIMAGETOOL_APP_NAME=${pkgname} ./squashfs-root/AppRun --runtime-file=/usr/local/lib/appimage-runtime-${arch_appimage} -s \
    -u "zsync|https://dl.sentinel.net/sentinel/latest/sentinel-latest-linux-${ARCH}-appimage.zsync" \
    Sentinel.AppDir
  fi

  # Fix zsync location
  if [ "$arch_appimage" == "aarch64" ]; then
    sed -i \
      -e "s|^Filename: .*|Filename: Sentinel.aarch64.AppImage|" \
      -e "s|^URL: .*|URL: https://dl.sentinel.net/sentinel/${VERSION}/sentinel-${VERSION}-linux-arm64-appimage.AppImage|" \
      "${pkgname}-${VERSION}-${arch_appimage}.AppImage.zsync"
  else
    sed -i \
      -e "s|^Filename: .*|Filename: Sentinel.x86_64.AppImage|" \
      -e "s|^URL: .*|URL: https://dl.sentinel.net/sentinel/${VERSION}/sentinel-${VERSION}-linux-x86_64-appimage.AppImage|" \
      "${pkgname}-${VERSION}-${arch_appimage}.AppImage.zsync"
  fi

  chmod +x ${pkgname}-${VERSION}-${arch_appimage}.AppImage
}

pkgname="sentinel"

tmpdir=$(mktemp -d)
(cd "$tmpdir" && tar xf "$PACKAGE")

echo "-> Building AppImage" >&2

(cd "$tmpdir" && build_appimage)


(cd "$tmpdir" && make_setup_folder)

version="$(curl -sfSA "" "https://raw.githubusercontent.com/snazzyatoms/sentinel-browser/main/version")"
release="$(curl -sfSA "" "https://raw.githubusercontent.com/snazzyatoms/sentinel-browser/main/release")"

echo "-> Building Redhat package" >&2
arch=$(rpm_arch)
outpkg="$tmpdir/${pkgname}-${VERSION}.${arch}.rpm"

echo "-> Running fpm"

(cd "$tmpdir/sentinel-$version" &&
  fpm -s dir -t rpm \
    --name "$pkgname" \
    --version "$version" \
    --iteration "$release" \
    --architecture "$arch" \
    --vendor "Sentinel Community" \
    --url "https://sentinel.net/" \
    --license "MPL" \
    --description "The Sentinel browser for privacy, with uBlock and tweaked settings." \
    --rpm-os linux \
    --chdir . \
    --package "$outpkg" \
    -d 'libX11-xcb.so.1()(64bit)' \
    -d 'libX11.so.6()(64bit)' \
    -d 'libXcomposite.so.1()(64bit)' \
    -d 'libXcursor.so.1()(64bit)' \
    -d 'libXdamage.so.1()(64bit)' \
    -d 'libXext.so.6()(64bit)' \
    -d 'libXfixes.so.3()(64bit)' \
    -d 'libXi.so.6()(64bit)' \
    -d 'libXrandr.so.2()(64bit)' \
    -d 'libXrender.so.1()(64bit)' \
    -d 'libasound.so.2()(64bit)' \
    -d 'libatk-1.0.so.0()(64bit)' \
    -d 'libcairo-gobject.so.2()(64bit)' \
    -d 'libcairo.so.2()(64bit)' \
    -d 'libdbus-1.so.3()(64bit)' \
    -d 'libdl.so.2()(64bit)' \
    -d 'libfontconfig.so.1()(64bit)' \
    -d 'libfreetype.so.6()(64bit)' \
    -d 'libgcc_s.so.1()(64bit)' \
    -d 'libgdk-3.so.0()(64bit)' \
    -d 'libgdk_pixbuf-2.0.so.0()(64bit)' \
    -d 'libgio-2.0.so.0()(64bit)' \
    -d 'libglib-2.0.so.0()(64bit)' \
    -d 'libgobject-2.0.so.0()(64bit)' \
    -d 'libgtk-3.so.0()(64bit)' \
    -d 'libm.so.6()(64bit)' \
    -d 'libpango-1.0.so.0()(64bit)' \
    -d 'libpangocairo-1.0.so.0()(64bit)' \
    -d 'libpthread.so.0()(64bit)' \
    -d 'libresolv.so.2()(64bit)' \
    -d 'librt.so.1()(64bit)' \
    -d 'libstdc++.so.6()(64bit)' \
    -d 'libxcb-shm.so.0()(64bit)' \
    -d 'libxcb.so.1()(64bit)' \
    usr)

if [ -n "${SIGNING_KEY_FPR:-}" ]; then
  echo "-> Signing the RPM" >&2
  export GPG_TTY=$(tty)
  rpm --addsign "$outpkg"
fi

echo "-> Building Debian package" >&2
arch=$(deb_arch)
outpkg="$tmpdir/${pkgname}-${VERSION}.${arch}.deb"

chmod +x "$BSYS6/../assets/deb/postinst" "$BSYS6/../assets/deb/prerm"

(cd "$tmpdir/sentinel-$version" &&
  mkdir -p etc/apparmor.d &&
  cp "$BSYS6/../assets/sentinel-apparmor" etc/apparmor.d/sentinel &&
  chmod 644 etc/apparmor.d/sentinel)

echo "-> Running fpm"

(cd "$tmpdir/sentinel-$version" &&
  fpm -s dir -t deb \
    --name "$pkgname" \
    --version "$version" \
    --iteration "$release" \
    --architecture "$arch" \
    --vendor "Sentinel Community" \
    --url "https://sentinel.net/" \
    --license "MPL" \
    --description "The Sentinel browser for privacy, with uBlock and tweaked settings." \
    --chdir . \
    --package "$outpkg" \
    --after-install "$BSYS6/../assets/deb/postinst" \
    --before-remove "$BSYS6/../assets/deb/prerm" \
    --provides "www-browser" \
    --provides "gnome-www-browser" \
    --category "web" \
    -d 'libasound2 >= 1.0.16' \
    -d 'libatk1.0-0 >= 1.12.4' \
    -d 'libc6 >= 2.28' \
    -d 'libcairo-gobject2 >= 1.10.0' \
    -d 'libcairo2 >= 1.10.0' \
    -d 'libdbus-1-3 >= 1.9.14' \
    -d 'libfontconfig1 >= 2.12.6' \
    -d 'libfreetype6 >= 2.6' \
    -d 'libgcc1 >= 1:4.5' \
    -d 'libgdk-pixbuf-2.0-0 (>= 2.22.0) | libgdk-pixbuf2.0-0 (>= 2.22.0)' \
    -d 'libglib2.0-0 >= 2.37.3' \
    -d 'libgtk-3-0 >= 3.13.7' \
    -d 'libpango-1.0-0 >= 1.14.0' \
    -d 'libpangocairo-1.0-0 >= 1.14.0' \
    -d 'libstdc++6 >= 5' \
    -d 'libx11-6' \
    -d 'libx11-xcb1' \
    -d 'libxcb-shm0' \
    -d 'libxcb1' \
    -d 'libxcomposite1 >= 1:0.3-1' \
    -d 'libxcursor1 >> 1.1.2' \
    -d 'libxdamage1 >= 1:1.1' \
    -d 'libxext6' \
    -d 'libxfixes3' \
    -d 'libxi6' \
    -d 'libxrandr2 >= 2:1.4.0' \
    -d 'libxrender1' \
    usr etc/apparmor.d)

if [ -n "${SIGNING_KEY_FPR:-}" ] && command -v dpkg-sig &>/dev/null; then
  echo "-> Signing the DEB" >&2
  dpkg-sig --sign builder "$outpkg"
fi


source $BSYS6/exports/move_artifact.sh "RPM"      "$tmpdir" ".*\.rpm"
source $BSYS6/exports/move_artifact.sh "DEB"      "$tmpdir" ".*\.deb"
source $BSYS6/exports/move_artifact.sh "APPIMAGE" "$tmpdir" ".*\.AppImage"
source $BSYS6/exports/move_artifact.sh "APPIMAGE" "$tmpdir" ".*\.AppImage.zsync"
