#!/usr/bin/bash
set -eu

if [ -n "${SOURCE:-}" ]; then
  $SOURCE/mach clobber
fi
