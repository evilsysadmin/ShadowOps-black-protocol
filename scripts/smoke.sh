#!/usr/bin/env bash
# Local-only startup gate; never launches a graphical window.
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/static-check.sh
engine="${GODOT_BIN:-godot}"
if ! command -v "$engine" >/dev/null 2>&1; then
  echo "Godot 4 not found; set GODOT_BIN to its executable." >&2
  exit 127
fi
version="$("$engine" --version)"
if [[ "$version" != 4.* ]]; then
  echo "Expected Godot 4, found $version" >&2
  exit 2
fi
# Linux local gate: never read or write the player's actual campaign.
scratch="$(mktemp -d)"
trap 'rm -rf -- "$scratch"' EXIT
export XDG_DATA_HOME="$scratch/data"
export XDG_CONFIG_HOME="$scratch/config"
export XDG_CACHE_HOME="$scratch/cache"
export BLACK_PROTOCOL_SMOKE_ROOT="$scratch"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
log="$scratch/godot.log"
run_checked() {
  : > "$log"
  if ! "$engine" "$@" 2>&1 | tee "$log"; then
    return 1
  fi
  # Godot can exit zero even when GDScript failed to load.
  if grep -Eq '(^|[[:space:]])(SCRIPT ERROR:|ERROR:|Parse Error:)' "$log"; then
    echo "Godot reported an error." >&2
    return 1
  fi
}
run_checked --headless --path . --editor --import
run_checked --headless --path . --quit-after 120
run_checked --headless --path . res://scenes/briefing.tscn --quit-after 120
run_checked --headless --path . res://scenes/dossier.tscn --quit-after 120
run_checked --headless --path . res://scenes/hotel.tscn --quit-after 120
run_checked --headless --path . res://scenes/archive.tscn --quit-after 120
run_checked --headless --path . res://tests/campaign_regression.tscn --quit-after 300
if ! grep -Fxq "CAMPAIGN REGRESSION PASSED" "$log"; then
  echo "Campaign regression did not finish successfully." >&2
  exit 1
fi
echo "Local Godot import, startup and campaign regression passed."
