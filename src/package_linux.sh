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
  version="$(curl -sfSA "" "$FORGE_URL/$FORGE_REPO_OWNER/source/raw/branch/main/version")"

  # Copy the needed assets.
  cp $BSYS6/../assets/linux.librewolf.desktop.in librewolf/librewolf.desktop.in
  cp $BSYS6/../assets/linux.librewolf.ico librewolf/librewolf.ico

  # Remove some files we don't want.
  rm -f librewolf/browser/features/proxy-failover@mozilla.com.xpi
  rm -f librewolf/pingsender
  rm -f librewolf/precomplete
  rm -f librewolf/removed-files
  rm -f librewolf/libonnxruntime.so

  # Create the target filesystem layout directly.
  rm -rf "librewolf-$version"
  mkdir -p "librewolf-$version/usr/share/librewolf"
  mkdir -p "librewolf-$version/usr/bin"
  mv librewolf/* "librewolf-$version/usr/share/librewolf"
  rmdir librewolf
  (cd "librewolf-$version/usr/bin" && ln -s ../share/librewolf/librewolf)

  # Application icon
  mkdir -p "librewolf-$version/usr/share/applications"
  mkdir -p "librewolf-$version/usr/share/icons/hicolor/16x16/apps"
  mkdir -p "librewolf-$version/usr/share/icons/hicolor/32x32/apps"
  mkdir -p "librewolf-$version/usr/share/icons/hicolor/64x64/apps"
  mkdir -p "librewolf-$version/usr/share/icons/hicolor/128x128/apps"
  cp "librewolf-$version/usr/share/librewolf/browser/chrome/icons/default/default16.png" "librewolf-$version/usr/share/icons/hicolor/16x16/apps/librewolf.png"
  cp "librewolf-$version/usr/share/librewolf/browser/chrome/icons/default/default32.png" "librewolf-$version/usr/share/icons/hicolor/32x32/apps/librewolf.png"
  cp "librewolf-$version/usr/share/librewolf/browser/chrome/icons/default/default64.png" "librewolf-$version/usr/share/icons/hicolor/64x64/apps/librewolf.png"
  cp "librewolf-$version/usr/share/librewolf/browser/chrome/icons/default/default128.png" "librewolf-$version/usr/share/icons/hicolor/128x128/apps/librewolf.png"

  # This creates a `1ibrewolf.destop` file.
  sed "s/MYDIR/\/usr\/share\/librewolf/g" <"librewolf-$version/usr/share/librewolf/librewolf.desktop.in" >"librewolf-$version/usr/share/applications/librewolf.desktop"
  rm "librewolf-$version/usr/share/librewolf/librewolf.desktop.in"
}

build_appimage() {
  mkdir -p "LibreWolf.AppDir/usr/bin/"
  mkdir -p "LibreWolf.AppDir/usr/share/metainfo/"
  mkdir -p "LibreWolf.AppDir/usr/share/icons/hicolor/128x128/apps/"
  mkdir -p "LibreWolf.AppDir/usr/share/applications/"
  cp "$BSYS6/../assets/appimage/librewolf.png" "LibreWolf.AppDir/usr/share/icons/hicolor/128x128/apps/"
  mv "$BSYS6/../assets/appimage/net.librewolf.LibreWolf.desktop" "LibreWolf.AppDir/usr/share/applications/"
  ln "LibreWolf.AppDir/usr/share/applications/net.librewolf.LibreWolf.desktop" "LibreWolf.AppDir/net.librewolf.LibreWolf.desktop"
  mv "$BSYS6/../assets/appimage/net.librewolf.LibreWolf.metainfo.xml" "LibreWolf.AppDir/usr/share/metainfo/net.librewolf.LibreWolf.appdata.xml"
  cp $BSYS6/../assets/appimage/* "LibreWolf.AppDir/"
  cp -r librewolf/* "LibreWolf.AppDir/usr/bin/"
  curl -fL "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage" -o "appimagetool"
  chmod +x appimagetool
  arch_appimage=$(rpm_arch)
  ./appimagetool --appimage-extract
  if [ -z "$SIGNING_KEY" ]; then
    APPIMAGETOOL_APP_NAME=${pkgname} ./squashfs-root/AppRun \
    -u "zsync|https://dl.librewolf.net/librewolf/latest/librewolf-latest-linux-${ARCH}-appimage.zsync" \
    LibreWolf.AppDir
  else
    APPIMAGETOOL_APP_NAME=${pkgname} ./squashfs-root/AppRun -s \
    -u "zsync|https://dl.librewolf.net/librewolf/latest/librewolf-latest-linux-${ARCH}-appimage.zsync" \
    LibreWolf.AppDir
  fi

  # Fix zsync location
  if [ "$arch_appimage" == "aarch64" ]; then
    sed -i \
      -e "s|^Filename: .*|Filename: LibreWolf.aarch64.AppImage|" \
      -e "s|^URL: .*|URL: https://dl.librewolf.net/librewolf/${VERSION}/librewolf-${VERSION}-linux-arm64-appimage.AppImage|" \
      "${pkgname}-${VERSION}-${arch_appimage}.AppImage.zsync"
  else
    sed -i \
      -e "s|^Filename: .*|Filename: LibreWolf.x86_64.AppImage|" \
      -e "s|^URL: .*|URL: https://dl.librewolf.net/librewolf/${VERSION}/librewolf-${VERSION}-linux-x86_64-appimage.AppImage|" \
      "${pkgname}-${VERSION}-${arch_appimage}.AppImage.zsync"
  fi

  chmod +x ${pkgname}-${VERSION}-${arch_appimage}.AppImage
}

pkgname="librewolf"

tmpdir=$(mktemp -d)
(cd "$tmpdir" && tar xf "$PACKAGE")

echo "-> Building AppImage" >&2

(cd "$tmpdir" && build_appimage)


(cd "$tmpdir" && make_setup_folder)

version="$(curl -sfSA "" "$FORGE_URL/$FORGE_REPO_OWNER/source/raw/branch/main/version")"
release="$(curl -sfSA "" "$FORGE_URL/$FORGE_REPO_OWNER/source/raw/branch/main/release")"

echo "-> Building Redhat package" >&2
arch=$(rpm_arch)
outpkg="$tmpdir/${pkgname}-${VERSION}.${arch}.rpm"

echo "-> Running fpm"

(cd "$tmpdir/librewolf-$version" &&
  fpm -s dir -t rpm \
    --name "$pkgname" \
    --version "$version" \
    --iteration "$release" \
    --architecture "$arch" \
    --vendor "LibreWolf Community" \
    --url "https://librewolf.net/" \
    --license "MPL" \
    --description "The LibreWolf browser for privacy, with uBlock and tweaked settings." \
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

(cd "$tmpdir/librewolf-$version" &&
  mkdir -p etc/apparmor.d &&
  cp "$BSYS6/../assets/librewolf-apparmor" etc/apparmor.d/librewolf &&
  chmod 644 etc/apparmor.d/librewolf)

echo "-> Running fpm"

(cd "$tmpdir/librewolf-$version" &&
  fpm -s dir -t deb \
    --name "$pkgname" \
    --version "$version" \
    --iteration "$release" \
    --architecture "$arch" \
    --vendor "LibreWolf Community" \
    --url "https://librewolf.net/" \
    --license "MPL" \
    --description "The LibreWolf browser for privacy, with uBlock and tweaked settings." \
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
    -d 'libfreetype6 >= 2.3.9' \
    -d 'libgcc1 >= 1:4.5' \
    -d 'libgdk-pixbuf-2.0-0 >= 2.22.0' \
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
