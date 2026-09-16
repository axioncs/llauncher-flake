#!/usr/bin/env bash
# Checks LLauncher's latest GitHub release and, if newer than what's pinned
# in version.json, updates the version + fetches a fresh sha256 for the
# amd64 .deb asset.
#
# Note: unlike TwintailLauncher, LLauncher's release tags have no prefix
# (just "1.3.3", not "ttl-v1.3.3") — confirm this hasn't changed if the
# bot ever stops finding updates.

set -euo pipefail

REPO="AugustLigh/LLauncher"
FILE="version.json"

current_version=$(jq -r '.version' "$FILE")
current_hash=$(jq -r '.hashes.amd64' "$FILE")

latest_tag=$(curl -fsSL \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${REPO}/releases/latest" \
  | jq -r '.tag_name')

latest_version="$latest_tag"

if [ -z "$latest_version" ] || [ "$latest_version" = "null" ]; then
  echo "Failed to determine latest version from tag '$latest_tag'" >&2
  exit 1
fi

if [ "$latest_version" = "$current_version" ] && [[ "$current_hash" != *"0000000000"* ]]; then
  echo "Already up to date ($current_version)."
  exit 0
fi

echo "Update available: $current_version -> $latest_version"

url="https://github.com/${REPO}/releases/download/${latest_version}/LLauncher_${latest_version}_amd64.deb"

echo "Fetching amd64 asset..." >&2
if ! curl -fsSL -o "/tmp/llauncher_amd64.deb" "$url"; then
  echo "Failed to download $url" >&2
  exit 1
fi

amd64_hash=$(nix hash file --sri "/tmp/llauncher_amd64.deb")

jq -n \
  --arg version "$latest_version" \
  --arg amd64 "$amd64_hash" \
  '{version: $version, hashes: {amd64: $amd64}}' \
  > "$FILE"

echo "Updated $FILE to version $latest_version."
