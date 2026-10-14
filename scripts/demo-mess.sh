#!/bin/bash
# Fills ~/Desktop with realistic-looking junk for a demo video, and records every path it creates
# in demo-mess-manifest.txt so scripts/demo-clean.sh can remove exactly those (and nothing else).
set -euo pipefail
cd "$(dirname "$0")/.."
DESK="$HOME/Desktop"
MANIFEST="$(pwd)/demo-mess-manifest.txt"
SRC="$(pwd)/Resources/rug.png"
touch "$MANIFEST"

new() {   # new <name>: refuse to overwrite anything that already exists
  local p="$DESK/$1"
  if [ -e "$p" ]; then echo "skip (exists): $1" >&2; return 1; fi
  echo "$p" >> "$MANIFEST"
  printf '%s' "$p"
}

# Screenshots (real PNGs, varied sizes).
for t in "09.12.44" "09.13.02" "11.47.30" "14.32.11" "14.32.59" "16.05.18" "18.21.07" "22.40.51"; do
  p=$(new "Screenshot 2026-10-14 at $t.png") || continue
  sips -Z $((300 + RANDOM % 900)) "$SRC" --out "$p" >/dev/null
done
for n in "IMG_4821.HEIC" "IMG_4822.jpg" "IMG_4830.jpg" "photo (1).jpg" "photo (2).jpg"; do
  p=$(new "$n") || continue
  sips -s format jpeg -Z $((400 + RANDOM % 800)) "$SRC" --out "$p" >/dev/null
done

# Documents.
doc() { p=$(new "$1") || return 0; printf '%s\n' "$2" | textutil -stdin -format txt -convert "$3" -output "$p" >/dev/null; }
doc "Untitled.rtf" "Untitled" rtf
doc "Notes.rtf" "meeting notes - remember to clean desktop" rtf
doc "final_FINAL_v3.docx" "Final version. Really final this time." docx
doc "final_FINAL_v4 (1).docx" "Okay, this one is the final." docx
doc "Resume 2026.docx" "Curriculum vitae" docx
doc "invoice_0931.html" "Invoice 0931" html
for n in "todo.txt" "ideas.txt" "passwords_NOT.txt" "untitled folder notes.txt" "copy.txt" "copy 2.txt"; do
  p=$(new "$n") || continue; echo "$n" > "$p"
done
for n in "Tax return 2025.pdf" "boarding-pass.pdf" "Lease agreement SIGNED.pdf" "lecture-07-slides.pdf"; do
  p=$(new "$n") || continue
  echo "$n" | cupsfilter -i text/plain - > "$p" 2>/dev/null || echo "$n" > "$p"
done

# Bigger stuff (makes bigger lumps under the rug).
big() { p=$(new "$1") || return 0; mkfile -n "$2" "$p"; }
big "screen-recording-final.mov" 180m
big "Archive.zip" 40m
big "Archive (2).zip" 12m
big "node_modules_backup.tar.gz" 95m
big "design-export@2x.psd" 60m
big "song idea 3.m4a" 6m
big "Install macOS.dmg" 250m
big "random.csv" 2m

# Folders with a few things inside.
for d in "untitled folder" "untitled folder 2" "New Folder (3)" "old stuff" "Downloads copy" "project-old-DO-NOT-DELETE"; do
  p=$(new "$d") || continue
  mkdir "$p"
  for k in 1 2 3; do echo "$d $k" > "$p/file $k.txt"; done
done

echo "Created $(wc -l < "$MANIFEST" | tr -d ' ') items on the Desktop (listed in demo-mess-manifest.txt)."
