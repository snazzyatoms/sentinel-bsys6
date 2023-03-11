#!/usr/bin/bash
set -eu

if [ -z "${MSIX:-}" ]; then
  source $BSYS6/exports/require_target.sh "windows"

  source $BSYS6/exports/build_use_existing.sh

  echo "-> Building msix with mach" >&2
  (cd $SOURCE && MAKEAPPX=$MOZBUILD/msix-packaging/makemsix $SOURCE/mach repackage msix --publisher='CN=846D51B2-15A2-4033-86D1-071B877C86A7' --identity-name='31856maltejur.LibreWolf' --publisher-display-name='maltejur')
  source $BSYS6/exports/move_artifact.sh "MSIX" "$MOZBUILD/cache/mach-msix" "31856maltejur\.LibreWolf.*\.msix"
  source $BSYS6/exports/calculate_sha256.sh "MSIX"
fi
