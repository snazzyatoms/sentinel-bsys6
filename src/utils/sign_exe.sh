#!/usr/bin/env bash
set -eu


if [ "$#" -eq 1 ]; then
  in="$1"
  out="$1"
elif [ "$#" -eq 2 ]; then
  in="$1"
  out="$2"
else
  echo "Usage: sign_exe.sh <exe_in> <exe_out (optional)>" >&2
  exit 1
fi

if [ "${ENABLE_EXE_SIGNING:-}" != "true" ]; then
  exit 0
fi

if [ -z "${OSSIGN_CONFIG_FILE:-}" ]; then
  echo "Error: Unable to sign $in because OSSIGN_CONFIG_FILE is not set" >&2
  exit 1
fi

echo "-> Signing $in with ossign"
ossign -c "$OSSIGN_CONFIG_FILE" -t pecoff -o "$out" "$in"
