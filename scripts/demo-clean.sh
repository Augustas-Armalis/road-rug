#!/bin/bash
# Moves everything scripts/demo-mess.sh created to the Trash (recoverable), wherever it now is:
# still on the Desktop, or swept under the rug into ~/Library/Application Support/Road Rug/Under the Rug.
set -euo pipefail
cd "$(dirname "$0")/.."
MANIFEST="$(pwd)/demo-mess-manifest.txt"
STASH="$HOME/Library/Application Support/Road Rug/Under the Rug"
[ -f "$MANIFEST" ] || { echo "Nothing to clean (no manifest)."; exit 0; }

paths=()
while IFS= read -r p; do
  [ -n "$p" ] || continue
  under="$STASH/$(basename "$p")"
  if [ -e "$p" ]; then paths+=("$p"); elif [ -e "$under" ]; then paths+=("$under"); fi
done < "$MANIFEST"

for p in "${paths[@]}"; do
  osascript -e 'on run argv' -e 'tell application "Finder" to delete (POSIX file (item 1 of argv) as alias)' -e 'end run' "$p" >/dev/null
done
rm "$MANIFEST"
echo "Moved ${#paths[@]} demo items to the Trash."
