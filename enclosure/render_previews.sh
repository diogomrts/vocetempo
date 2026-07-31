#!/usr/bin/env bash
# Render PNG previews of every enclosure concept.
# Requires OpenSCAD (brew install --cask openscad).
#
# Usage:  ./render_previews.sh
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p previews

SCAD="${OPENSCAD:-openscad}"
SIZE="900,900"
SCHEME="Tomorrow"

# camera = eyex,eyey,eyez, centerx,centery,centerz, distance  (translate form)
render () {
  local file="$1" cam="$2"
  echo "Rendering $file ..."
  "$SCAD" -o "previews/${file%.scad}.png" \
    --imgsize="$SIZE" --camera="$cam" --colorscheme="$SCHEME" \
    --projection=perspective "$file"
}

render concept1_chubby_panda.scad  "0,0,70,60,0,25,420"
render concept2_box_panda.scad     "0,0,70,60,0,25,460"
render concept3_minimal_panda.scad "0,0,60,60,0,25,420"

echo "Done. See enclosure/previews/*.png"
