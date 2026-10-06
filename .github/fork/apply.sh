#!/usr/bin/env bash
# Apply this fork's changes on top of a checkout of upstream. Idempotent:
# running it on an already-overlaid tree changes nothing.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
cfg=$root/claude-terminal/config.yaml

cp "$here/repository.yaml" "$root/repository.yaml"

yq -i '.name = "Claude Code" | .slug = "claude_code" | .panel_title = "Claude Code"' "$cfg"

# Normalise upstream's map (short "share:rw" strings, or the deprecated
# "config" type, which is homeassistant_config at /config), then put ours
# first so unique_by keeps our entry for every type we define.
MAP_FILE=$here/map.yaml yq -i '
  .map |= (
    map(
      (select(tag == "!!str") |= {"type": split(":")[0], "read_only": (split(":")[1] != "rw")})
      | (select(.type == "config") |= (.type = "homeassistant_config" | .path = "/config"))
    )
    | (load(strenv(MAP_FILE)) + .) | unique_by(.type)
  )' "$cfg"
