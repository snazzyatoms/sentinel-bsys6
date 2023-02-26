#!/usr/bin/bash
set -eu

for pkgmgr in apt-get pacman; do
  if command -v $pkgmgr >/dev/null; then
    $BSYS6/dependencies_$pkgmgr.sh
    return
  fi
done

echo "No supported package manager found."
exit 1
