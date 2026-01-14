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
    version="$(curl -sfS https://codeberg.org/librewolf/source/raw/branch/main/version)"

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

tmpdir=$(mktemp -d)
(cd "$tmpdir" && tar xf "$PACKAGE")
(cd "$tmpdir" && make_setup_folder)

pkgname="librewolf"
version="$(curl -sfS https://codeberg.org/librewolf/source/raw/branch/main/version)"

echo "-> Building Redhat package" >&2
arch=$(rpm_arch)
outpkg="$tmpdir/${pkgname}-${VERSION}.${arch}.rpm"

echo "-> Running fpm"

(cd "$tmpdir/librewolf-$version" && \
    fpm -s dir -t rpm \
        --name "$pkgname" \
        --version "$version" \
        --iteration "$RELEASE" \
        --architecture "$arch" \
        --vendor "LibreWolf Community" \
        --url "https://librewolf.net/" \
        --license "MPL" \
        --description "The LibreWolf browser for privacy, with uBlock and tweaked settings." \
        --rpm-os linux \
        --chdir . \
        --package "$outpkg" \
        -d 'alsa-lib' \
        -d 'atk' \
        -d 'gdk-pixbuf2' \
        -d 'glib2' \
        -d 'glibc' \
        -d 'libX11' \
        -d 'libX11-xcb' \
        -d 'libdrm' \
        -d 'libgcc' \
        -d 'libjpeg-turbo' \
        -d 'libstdc++' \
        -d 'libvpx' \
        -d 'mesa-libgbm' \
        -d 'nspr' \
        -d 'nss' \
        -d 'nss-util' \
        -d 'p11-kit-trust' \
        -d 'pango' \
        -d 'pciutils-libs' \
        -d 'pipewire-libs' \
        -d 'pixman' \
        -d 'systemd-udev' \
        -d 'zlib-ng-compat' \
        usr )
    
if [ -n "${SIGNING_KEY_FPR:-}" ]; then
    echo "-> Signing the RPM" >&2
    export GPG_TTY=$(tty)
    rpm --addsign "$outpkg"
fi

echo "-> Building Debian package" >&2
arch=$(deb_arch)
outpkg="$tmpdir/${pkgname}-${VERSION}.${arch}.deb"

chmod +x "$BSYS6/../assets/deb/postinst" "$BSYS6/../assets/deb/prerm"

(cd "$tmpdir/librewolf-$version" && \
    mkdir -p etc/apparmor.d/local && \
    cp "$BSYS6/../assets/librewolf-apparmor" etc/apparmor.d/local/librewolf \ &&
    chmod 644 etc/apparmor.d/local/librewolf)

echo "-> Running fpm"

(cd "$tmpdir/librewolf-$version" && \
    fpm -s dir -t deb \
        --name "$pkgname" \
        --version "$version" \
        --iteration "$RELEASE" \
        --architecture "$arch" \
        --vendor "LibreWolf Community" \
        --url "https://librewolf.net/" \
        --license "MPL" \
        --description "The LibreWolf browser for privacy, with uBlock and tweaked settings." \
        --chdir . \
        --package "$outpkg" \
        --after-install "$BSYS6/../assets/deb/postinst" \
        --before-remove "$BSYS6/../assets/deb/prerm" \
        -d 'debianutils >= 1.16' \
        -d 'fontconfig' \
        -d 'libasound2t64 >= 1.0.16' \
        -d 'libatk1.0-0t64 >= 1.12.4' \
        -d 'libc6 >= 2.39' \
        -d 'libcairo-gobject2 >= 1.10.0' \
        -d 'libcairo2 >= 1.10.0' \
        -d 'libdbus-1-3 >= 1.10' \
        -d 'libevent-2.1-7t64 >= 2.1.8-stable' \
        -d 'libffi8 >= 3.4' \
        -d 'libfontconfig1 >= 2.12.6' \
        -d 'libfreetype6 >= 2.3.5' \
        -d 'libgcc-s1 >= 4.5' \
        -d 'libgdk-pixbuf-2.0-0' \
        -d 'libglib2.0-0t64 >= 2.38.0' \
        -d 'libgtk-3-0t64 >= 3.13.7' \
        -d 'libnspr4 >= 2:4.32~' \
        -d 'libpango-1.0-0 >= 1.14.0' \
        -d 'libstdc++6 >= 12' \
        -d 'libvpx9 >= 1.12.0' \
        -d 'libx11-6' \
        -d 'libx11-xcb1' \
        -d 'libxcb-shm0' \
        -d 'libxcb1' \
        -d 'libxcomposite1 >= 1:0.4.6' \
        -d 'libxdamage1 >= 1:1.1' \
        -d 'libxext6' \
        -d 'libxfixes3' \
        -d 'libxrandr2 >= 2:1.4.0' \
        -d 'procps' \
        -d 'zlib1g >= 1:1.2.3.4' \
        usr )

if [ -n "${SIGNING_KEY_FPR:-}" ] && command -v dpkg-sig &>/dev/null; then
    echo "-> Signing the DEB" >&2
    dpkg-sig --sign builder "$outpkg"
fi

source $BSYS6/exports/move_artifact.sh "RPM" "$tmpdir" ".*\.rpm"
source $BSYS6/exports/move_artifact.sh "DEB" "$tmpdir" ".*\.deb"
