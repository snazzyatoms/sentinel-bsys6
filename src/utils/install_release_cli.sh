#!/usr/bin/env bash
set -eu

$BSYS6/utils/require_command.sh curl

echo "-> Installing GitLab release-cli" &>2
curl -L --output /usr/local/bin/release-cli "https://gitlab.com/gitlab-org/release-cli/-/package_files/163559016/download"
chmod +x /usr/local/bin/release-cli
