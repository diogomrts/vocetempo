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
# --render forces FULL geometry (F6) instead of the fast OpenCSG preview: the
# preview fakes transparency where the cut solids meet the skin, so it shows false
# "holes"/see-through panels. --render is artifact-free (what the STL actually is).
# BOTH views look at the BELLY (+Y) - that is where the functional openings are
# (OLED window + joystick), so a back-facing view shows nothing. rotz~180 faces the
# belly; the iso uses rx=80 (fairly side-on) so it doesn't sight-line through the
# joystick and out the open base.
"$SCAD" --backend=Manifold --render -o previews/panda_cut_front.png --imgsize=700,900 \
  --camera=0,0,0,90,0,180,0 --viewall --autocenter --projection=perspective \
  --colorscheme="$SCHEME" panda.scad
"$SCAD" --backend=Manifold --render -o previews/panda_cut_iso.png --imgsize=700,900 \
  --camera=0,0,0,80,0,193,0 --viewall --autocenter --projection=perspective \
  --colorscheme="$SCHEME" panda.scad
# Close-up of the RIGHT ear: the speaker grille must sit inside the stippled inner
# dish (see panda.scad ear_vent()), with an untouched stipple margin all round.
"$SCAD" --backend=Manifold --render -o previews/panda_ear_grille.png --imgsize=800,800 \
  --camera=40,0,147,78,0,168,110 --projection=perspective \
  --colorscheme="$SCHEME" panda.scad

# Integration fit-check: cage seated in the panda (ghost + section + breach).
"$SCAD" --backend=Manifold -o previews/fitcheck.png --imgsize=700,900 \
  --camera=0,0,0,68,0,25,0 --viewall --autocenter --projection=perspective \
  --colorscheme="$SCHEME" fitcheck.scad
"$SCAD" --backend=Manifold -o previews/fitcheck_section.png --imgsize=700,900 \
  --camera=0,0,0,90,0,90,0 --viewall --autocenter --projection=orthogonal \
  --colorscheme="$SCHEME" -D 'mode="section"' fitcheck.scad
# breach: cage material OUTSIDE the body - should be (near-)empty. Any large blob
# here means the cage pokes through the panda skin (regression check).
"$SCAD" --backend=Manifold -o previews/fitcheck_breach.png --imgsize=700,900 \
  --camera=0,0,0,68,0,25,0 --viewall --autocenter --projection=perspective \
  --colorscheme="$SCHEME" -D 'mode="breach"' fitcheck.scad

echo "Done. See enclosure/previews/*.png"
echo "Panda body STL: openscad --backend=Manifold -o stl/panda_body.stl panda.scad"
