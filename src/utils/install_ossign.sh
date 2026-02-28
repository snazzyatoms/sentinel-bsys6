#!/usr/bin/env bash
set -eu

echo "-> Installing ossign" >&2
curl https://pkg.ossign.org/debian/repository.key -o /etc/apt/keyrings/gitea-ossign.asc
echo "deb [signed-by=/etc/apt/keyrings/gitea-ossign.asc] https://pkg.ossign.org/debian all main" | tee /etc/apt/sources.list.d/ossign.list
$BSYS6/utils/dependencies.sh "ossign" ""
