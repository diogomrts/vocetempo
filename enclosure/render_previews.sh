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

# The electronics cage - front 3/4 (OLED wall) and back (joystick standoffs + USB).
# NEEDS Manifold: cage.scad clips its upper shell to the panda mesh (skin_inset).
render cage_final.png  "0,0,44,62,0,25,500"  --backend=Manifold cage.scad
render cage_back.png   "0,0,44,62,0,205,500" --backend=Manifold cage.scad

# Separate printed parts. The base cover is clipped to the sculpt's domed base, so
# it needs Manifold too - and it is no longer a flat plate.
"$SCAD" --backend=Manifold -o previews/cover.png --imgsize=800,700 -D 'part="cover"' \
  --viewall --autocenter --colorscheme="$SCHEME" cage.scad
"$SCAD" -o previews/esp32_bar.png --imgsize=600,300 -D 'part="esp32_bar"' \
  --viewall --autocenter --colorscheme="$SCHEME" cage.scad
"$SCAD" -o previews/dfp_bar.png   --imgsize=600,300 -D 'part="dfp_bar"' \
  --viewall --autocenter --colorscheme="$SCHEME" cage.scad
"$SCAD" -o previews/joy_cap.png   --imgsize=600,700 -D 'part="joy_cap"' \
  --camera=0,0,8,65,0,30,70 --projection=perspective --colorscheme="$SCHEME" cage.scad

# Wall layout map - all four mounting walls unrolled. This is the cheap collision
# check and it earns its keep: it is what caught the USB-C exit slot sitting on top
# of the joystick frame's lower bosses. Flat-on orthogonal, no camera rotation.
"$SCAD" --backend=Manifold -o previews/layout_walls.png --imgsize=1700,750 \
  --camera=0,0,0,0,0,0,340 --projection=orthogonal --viewall --autocenter \
  --colorscheme="$SCHEME" layout_walls.scad

# The hollowed panda body. NEEDS the Manifold backend (the 500k-tri mesh is far
# too slow for CGAL); requires OpenSCAD 2023+.
# --render forces FULL geometry (F6) instead of the fast OpenCSG preview: the
# preview fakes transparency where the cut solids meet the skin, so it shows false
# "holes"/see-through panels. --render is artifact-free (what the STL actually is).
# The belly (rotz~180) now carries ONLY the screen; the joystick and the USB-C exit
# moved to the RUMP, so there is a back view too - without it the two newest
# openings in the body would never appear in any preview.
"$SCAD" --backend=Manifold --render -o previews/panda_cut_front.png --imgsize=700,900 \
  --camera=0,0,0,90,0,180,0 --viewall --autocenter --projection=perspective \
  --colorscheme="$SCHEME" panda.scad
"$SCAD" --backend=Manifold --render -o previews/panda_cut_iso.png --imgsize=700,900 \
  --camera=0,0,0,80,0,193,0 --viewall --autocenter --projection=perspective \
  --colorscheme="$SCHEME" panda.scad
# The BACK: joystick bore, USB-C exit slot, and the insertion channel's notch at
# the bottom rear (which is meant to be there - see panda_joystick_cut).
"$SCAD" --backend=Manifold --render -o previews/panda_back.png --imgsize=700,900 \
  --camera=0,0,0,85,0,0,0 --viewall --autocenter --projection=perspective \
  --colorscheme="$SCHEME" panda.scad
# Close-up of the RIGHT ear: the speaker grille must sit inside the stippled inner
# dish (see panda.scad ear_vent()), with an untouched stipple margin all round.
"$SCAD" --backend=Manifold --render -o previews/panda_ear_grille.png --imgsize=800,800 \
  --camera=51,0,183,78,0,168,130 --projection=perspective \
  --colorscheme="$SCHEME" panda.scad
# Close-up of the screen + the folded paws. The window is the FULL lit area and is
# allowed to cut through the paws if it has to (see dimensions.scad) - on the 200mm
# host it no longer does, so check the bezel is even on both sides.
"$SCAD" --backend=Manifold --render -o previews/panda_paws.png --imgsize=800,800 \
  --camera=-25,12,50,76,0,203,300 --projection=perspective \
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
