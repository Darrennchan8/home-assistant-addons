#!/usr/bin/env bash
# Fail if the overlaid add-on is missing anything this fork relies on.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
cfg=$here/../../claude-terminal/config.yaml

[ "$(yq '.slug' "$cfg")" = claude_code ] || { echo "slug not overridden"; exit 1; }
for t in $(yq '.[].type' "$here/map.yaml"); do
    yq -e ".map[] | select(.type == \"$t\" and .read_only == false)" "$cfg" > /dev/null \
        || { echo "missing read-write mapping: $t"; exit 1; }
done
# Exactly one mount at /config: the deprecated config type would collide
[ "$(yq '[.map[] | select(.type == "config" or .path == "/config")] | length' "$cfg")" = 1 ] \
    || { echo "more than one mapping at /config"; exit 1; }
yq -e '.image | test("^ghcr.io/heytcass/")' "$cfg" > /dev/null \
    || echo "::warning::image no longer points at heytcass's GHCR"
echo "overlay OK"
