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

# Retention bars + slim joystick cap (separate printed parts).
"$SCAD" -o previews/esp32_bar.png --imgsize=600,300 -D 'part="esp32_bar"' \
  --viewall --autocenter --colorscheme="$SCHEME" cage.scad
"$SCAD" -o previews/dfp_bar.png   --imgsize=600,300 -D 'part="dfp_bar"' \
  --viewall --autocenter --colorscheme="$SCHEME" cage.scad
"$SCAD" -o previews/joy_cap.png   --imgsize=600,500 -D 'part="joy_cap"' \
  --camera=0,0,4,60,0,30,55 --projection=perspective --colorscheme="$SCHEME" cage.scad

# Back-wall board layout map (collision check).
"$SCAD" -o previews/layout_backwall.png --imgsize=800,1000 \
  --camera=0,48,300,0,0,0,0 --projection=orthogonal --viewall --autocenter \
  --colorscheme="$SCHEME" layout_backwall.scad

# The hollowed panda body. NEEDS the Manifold backend (the 500k-tri mesh is far
# too slow for CGAL); requires OpenSCAD 2023+.
"$SCAD" --backend=Manifold -o previews/panda_cut_iso.png --imgsize=700,900 \
  --camera=0,0,0,72,0,8,0 --viewall --autocenter --projection=perspective \
  --colorscheme="$SCHEME" panda.scad

# Integration fit-check: cage seated in the panda (ghost + section).
"$SCAD" --backend=Manifold -o previews/fitcheck.png --imgsize=700,900 \
  --camera=0,0,0,68,0,25,0 --viewall --autocenter --projection=perspective \
  --colorscheme="$SCHEME" fitcheck.scad
"$SCAD" --backend=Manifold -o previews/fitcheck_section.png --imgsize=700,900 \
  --camera=0,0,0,90,0,90,0 --viewall --autocenter --projection=orthogonal \
  --colorscheme="$SCHEME" -D 'mode="section"' fitcheck.scad

echo "Done. See enclosure/previews/*.png"
echo "Panda body STL: openscad --backend=Manifold -o stl/panda_body.stl panda.scad"
