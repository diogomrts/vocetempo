# Vocetempo enclosure

Parametric 3D-printable enclosure for the panda-themed talking clock, written in
[OpenSCAD](https://openscad.org). The electronics live in a **slide-out cage**
that drops into a hollowed panda figurine from below, so the panda never has to
be opened to service the clock.

## Files

| File | Purpose |
| ---- | ------- |
| `dimensions.scad` | Every component measurement + design decision, in ONE place. **Edit here.** |
| `helpers.scad` | Shared shape modules (rounded box, screw boss, etc.). |
| `cage.scad` | The electronics cage - the real mechanical part. Print-ready. |
| `panda.scad` | The panda body: imports the sculpt, hollows it, cuts the openings. |
| `fitcheck.scad` | Seats the cage in the body (ghost / section / breach modes). |
| `layout_backwall.scad` | 2D map of the back-wall board layout (collision check). |
| `render_previews.sh` | Renders `previews/*.png`. |
| `verify_window.py` | Blender check: proves the OLED window's rim lands on flat plaque with the sculpted frame intact. Run it after touching `oled_win_*`. |

## The cage (`cage.scad`)

A box, 75 (W) x 78 (H) x 60 (D) mm, open at the base (the "service side").
Its cross-section (defined by `shell_prof` in `dimensions.scad`) is a rectangle
that stays FLAT and FULL through the whole board-mounting zone - so every module's
bosses land on a real, flat wall - and is only chamfered at the CORNERS where
there are no features: low down (the feet) and up high (the shoulders / folded
arms). That is how it follows the round panda without either spearing its corners
through the skin OR moving the walls away from the mounting bosses (verified by
the `breach` fit-check and by clipping every boss to the shell - see below):

- **Front face:** OLED window (at the true 55 x 28 lit area, offset +3.1 mm up)
  above a joystick tilt-cone (sized for the slim printed cap). Both boards screw
  to printed standoffs on the flat front wall.
- **Top face:** stadium-shaped throat firing UP into the panda's head (the head
  is the acoustic resonator); four bosses for the boxed speaker's ears.
- **Back wall:** RTC on its 3 real holes; ESP32 (portrait) and DFPlayer screw
  to bosses + printed retention bars. USB-C and SD both point at the open base.
- **Base:** an outward flange with 4 magnet pockets (retains the cage in the
  body) and a USB-C exit slot low on the back (sized for a future panel-mount).

### Printable parts (via the `part` selector at the bottom of `cage.scad`)

```sh
openscad -o cage.stl      -D 'part="cage"'      cage.scad
openscad -o esp32_bar.stl -D 'part="esp32_bar"' cage.scad
openscad -o dfp_bar.stl   -D 'part="dfp_bar"'   cage.scad
```

## The panda body (`panda.scad`)

Imports `panda/panda_original.stl` **untouched**, hollows only where the cage sits,
and cuts the OLED window, the joystick cone, the speaker chimney into the hollow head,
the ear grilles, and the base hatch/rebate. Needs the **Manifold** backend
(`--backend=Manifold`); the 500k-triangle mesh is far too slow for CGAL.

Nothing in this pipeline trims, deforms or re-sculpts the mesh. Every opening is
sized to fit a feature the sculptor already put there.

## The OLED window is smaller than the screen, on purpose

The sculpt **already has a screen**: a raised frame, ~1 mm proud, enclosing the flat
embossed "88:45" plaque. Measured on `panda_original.stl` (raycast grid, plaque
surface fitted as `Y = 60.207 - 0.14885z - 0.004622x²`, edges taken as the first
departure > 0.8 mm):

| edge | measured | flatness |
|---|---|---|
| bottom | Z 35.2 | ±0.1 mm across the full width |
| top | Z 57.25 | ±0.05 mm |
| −X | 18.20 … 18.80 mm | narrowest 18.20 at Z56 |
| +X | 19.05 … 19.60 mm | sculpt sits ~0.4 mm off-centre in X |

That is a flat interior of **36.4 × 22.05 mm**, so the window is `oled_win_w × oled_win_h`
= **36 × 21 mm**, sized to sit just inside it. The sculpted frame becomes the bezel -
which is plainly what it was modelled to be. Verified on the final cut body: worst rim
deviation from the flat plaque **+0.15 mm**, and the frame's rise stays **≥0.35 mm**
outboard of the rim all the way round.

```sh
cd enclosure
openscad --backend=Manifold -o /tmp/panda.stl panda.scad
blender -b -P verify_window.py -- /tmp/panda.stl
```

Measure before you believe. An earlier version of this pipeline was signed off on
three sampled Z slices and shipped a defect - pointy leg tops and a serrated ridge
across the belly - that a whole-body check caught immediately. Any change to the
sculpt or the openings should be verified over the *entire* model, not at spot
heights: per-band displacement, plus per-edge dihedral angle before vs after, which
is what actually detects a smooth feature turning into a sharp one.

### Why not the full 55 mm lit area

The lit area is 55 mm wide, the plaque only 36.4. A 55.4-wide window overhangs by
9.5 mm per side and lands squarely on the folded paws - the paw's inboard edge reaches
X−19.6 at Z51, **8.1 mm inside** such a window. Everything tried to make room failed:

- **countersinking the window** (`oled_bevel_*`) - left two flat "wings" beside the
  screen ending in a hard crescent line.
- **a rolling-ball paw trim** (`arm_trim()`) - tangent-continuous and facet-free, but
  it still rolled the sculpted paw tip into a spherical dome and planed its crest.
- **intersecting with a shifted copy of the sculpt** - the shifted copy samples the
  belly *below* the arm, so past ~12 mm it erodes a diagonal swath across the belly.
- **swinging the arms outboard in Blender first** (`panda_arms.py`) - this freed the
  paws cleanly, and was shipped briefly. But there are only **2.6 mm** of surface
  between the paw's underside (Z42) and the top of the feet (Z39.4), and the swing's
  taper has to collapse ~12 mm of movement across it. Put the taper above the feet and
  it tears a serrated ridge across the belly (900+ inverted triangles); run it through
  the feet and it shears their tops into **pointy tips**. ~30 envelope configurations
  were swept, plus a biharmonic (thin-plate) solve with the paw as a handle and the
  feet pinned - the solve came out **20× worse** (3,600 new creases vs 149), because
  the sculpt's triangulation (21:1 edge lengths, 22,757 low-quality triangles, 19% of
  cotangent weights negative) is far too irregular for a Laplacian method. The best
  result still rotated the legs 13 mm and visibly widened the stance.

It is a hard geometric conflict, not a tuning problem. Sizing the window to the plaque
dissolves it. **Do not re-litigate this without reading `dimensions.scad`'s window
block first.**

### The cost lands on the firmware

Only part of the panel is visible. At 55.0/128 = 0.4297 mm and 28.0/64 = 0.4375 mm per
pixel, this window exposes pixels **x 22..105, y 8..55** - an **84 × 48 safe area** out
of 128 × 64. Anything outside it is hidden behind the belly. `src/Display.cpp` currently
centres on the full 128 and puts the quiet-hours and mute icons in the corners, so it
needs a safe-area pass. Note `"HH:MM"` in the GFX classic font at size 3 is 87 px of
ink, which does **not** fit 84 - the time needs size 2, or a custom narrow-colon layout.

## Rendering previews

```sh
brew install --cask openscad      # once
cd enclosure
./render_previews.sh              # writes previews/*.png
```

Or open `cage.scad` in the OpenSCAD GUI and press F5 (preview) / F6 (render).

## Fit-check (does the cage fit inside the panda?)

`fitcheck.scad` seats the cage inside the hollowed body. Its `breach` mode outputs
ONLY the cage material sticking OUT of the panda - it should be effectively empty:

```sh
# should render to (near-)nothing; any large solid = the cage breaches the skin
openscad --backend=Manifold -o /tmp/breach.stl -D 'mode="breach"' fitcheck.scad
openscad --backend=Manifold -D 'mode="ghost"'   fitcheck.scad   # visual overlay
openscad --backend=Manifold -D 'mode="section"' fitcheck.scad   # X=0 cross-section
```

The cage cross-section (`shell_prof`, 60 mm depth, corner-only relief) was tuned
against a per-Z map of the raw panda skin so it clears the surface with ~1 mm to
spare. Residual "breach" is limited to sub-millimetre slivers at the base-flange
rim (the flange *seating* against the body base) and at the top side corners where
the folded arms pinch hardest - thin spots, not open holes.

Separately, `part="cage"` clips every mounting boss to the shell, so no standoff
can float outside or poke through a wall (this was a real earlier bug). The board
zone is kept flat-walled so all of a board's standoffs stay the same height.

## Measurements

The numbers in `dimensions.scad` are **measured from the actual boards** (see
`docs/MEASUREMENTS.md` for the method and values). A few remain nominal / TODO
(noted inline) - the RTC exact hole positions were read from a photo and should
be caliper-confirmed if the fit is tight.

## Serviceability (baked into the design)

- **Slide-out cage:** all electronics on one cage that enters from the base;
  pull it out to service anything. Retained by 4 magnet pairs (~8 N vs ~2 N
  weight).
- **SD card & USB-C** point at the open base / back slot, reachable without
  opening the shell.
- **No perfboard:** modules screw directly to printed standoffs/bosses (ESP32 &
  DFPlayer, which lack holes, use screwed retention bars). Wired point-to-point.
