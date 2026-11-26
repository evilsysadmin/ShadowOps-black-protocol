#!/usr/bin/env bash
# Local-only startup gate; never launches a graphical window.
set -euo pipefail
cd "$(dirname "$0")/.."
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
log="$(mktemp)"
trap 'rm -f "$log"' EXIT
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
echo "Local Godot import and startup smoke passed."
