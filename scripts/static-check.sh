#!/usr/bin/env bash
# Narrow, dependency-free check for single-line GDScript function declarations.
set -euo pipefail
cd "$(dirname "$0")/.."
failed=0
while IFS= read -r -d '' file; do
  if awk '/^[[:space:]]*(static[[:space:]]+)?func[[:space:]].*\)[[:space:]]*(->[[:space:]]*[[:alnum:]_.\[\]]+)?[[:space:]]*$/ {print FILENAME ":" FNR ": missing colon in function declaration"; bad=1} END {exit bad+0}' "$file"; then
    :
  else
    failed=1
  fi
done < <(find scripts tests -type f -name '*.gd' -print0)
exit "$failed"
