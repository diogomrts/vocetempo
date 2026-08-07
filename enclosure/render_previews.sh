#!/usr/bin/env bash
# Render PNG previews of the enclosure parts.
# Requires OpenSCAD (brew install --cask openscad).
#
# Usage:  ./render_previews.sh
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p previews

SCAD="${OPENSCAD:-openscad}"
SIZE="1000,1000"
SCHEME="Tomorrow"

# camera = transx,transy,transz, rotx,roty,rotz, distance
render () {
  local out="$1" cam="$2"; shift 2
  echo "Rendering $out ..."
  "$SCAD" -o "previews/$out" \
    --imgsize="$SIZE" --camera="$cam" --colorscheme="$SCHEME" \
    --projection=perspective "$@"
}

# The electronics cage - front 3/4 and back (USB slot).
render cage_final.png  "0,0,48,62,0,25,430"  cage.scad
render cage_back.png   "0,0,48,62,0,205,430" cage.scad

# Retention bars (separate printed parts).
"$SCAD" -o previews/esp32_bar.png --imgsize=600,300 -D 'part="esp32_bar"' \
  --viewall --autocenter --colorscheme="$SCHEME" cage.scad
"$SCAD" -o previews/dfp_bar.png   --imgsize=600,300 -D 'part="dfp_bar"' \
  --viewall --autocenter --colorscheme="$SCHEME" cage.scad

# Back-wall board layout map (collision check).
"$SCAD" -o previews/layout_backwall.png --imgsize=800,1000 \
  --camera=0,48,300,0,0,0,0 --projection=orthogonal --viewall --autocenter \
  --colorscheme="$SCHEME" layout_backwall.scad

echo "Done. See enclosure/previews/*.png"
