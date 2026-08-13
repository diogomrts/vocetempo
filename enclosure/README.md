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
| `verify_window.py` | Blender check: pixel coverage of the OLED window + exactly where its cut lands on the sculpt. Run it after touching `oled_win_*`. |

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

## The OLED window and the sliced paws

**Requirement: every one of the 128×64 pixels must be visible.** So the window is
the full lit area + `fit_gap` (`oled_win_w × oled_win_h` = 55.4 × 28.4 mm), and the
sculpt's folded paws, which stand in front of it, are simply **cut through**. That is
a deliberate trade. The paws' inboard edges reach X−19.6 at Z51 against the window's
27.7, so the cut takes **8.1 mm off each paw** over Z42–58, leaving a flat vertical
face on each. The arms end abruptly at the screen rather than reading as folded.

Verify with:

```sh
cd enclosure && blender -b -P verify_window.py
```

which checks pixel coverage and reports exactly where the cut lands. Current result:
**8188 of 8192 lit pixels visible**, both corner icons on screen, 2.13 mm into the
feet, 4.41 mm into the shoulder, 8.10 mm into the paws (deliberate).

### The corner radius is the one real knob

It does **not** affect the paw cut — that is 8.10 mm at *every* radius, because Z50
sits in the window's full-width span. It only trades corner pixels against the feet,
whose inner edges come to |X| 24.7 at Z32:

| `oled_win_r` | lit px hidden | corner icons | bite into the feet |
| --- | --- | --- | --- |
| **2.0 mm** (current) | **4 / 8192** | both survive | 2.1 mm at Z32–35 |
| 4.0 mm | 48 | both clipped | 1.1 mm |
| 6.0 mm | 120 | both clipped | 0.04 mm |
| 8.0 mm | 236 | both clipped | none |

r = 2.0 is chosen because the requirement is all pixels: it hides one pixel per
corner and keeps the quiet-hours and mute icons, which live in the top corners, on
screen. The price is a ~2 mm nick in each foot's top-inner corner — invisible next to
an 8.1 mm paw cut.

### What was rejected

All of these were built and measured:

- **Sizing the window to the sculpt's own embossed screen plaque** (36 × 21 mm, its
  raised frame becoming the bezel). Geometrically perfect — nothing trimmed or
  deformed, rim on flat plaque to ±0.15 mm — but it exposes only an 84 × 48 safe area,
  hiding a third of the panel. Rejected on the pixel requirement.
- **Countersinking the window** (`oled_bevel_*`) — two flat "wings" beside the screen
  ending in a hard crescent line.
- **A rolling-ball paw trim** (`arm_trim()`) — rolled the sculpted paw tip into a
  spherical dome and planed its crest.
- **Swinging the arms outboard in Blender first** (`panda_arms.py`). This *did* free
  the paws and keep them fully rounded, clearing this exact window with a 1.3–2.1 mm
  bezel. But there are only **2.6 mm** of surface between the paw's underside (Z42)
  and the top of the feet (Z39.4), so the swing's taper either tore a serrated ridge
  across the belly or sheared the leg tops into **pointy tips**. The best of ~30 swept
  configurations still rotated the legs 13 mm and visibly widened the stance, and left
  only 1.3 mm of bezel on the −X side (the sculpt's paws are not symmetric). A
  biharmonic thin-plate solve was **20× worse** (3,600 new creases vs 149), because
  the sculpt's triangulation (21:1 edge lengths, 19% negative cotangent weights) is
  far too irregular for a Laplacian method. Rejected as costing more than the paw cut
  it was avoiding.
- **A smaller 1.54" 128×64 panel** (~35 × 17.5 mm active) would fit the plaque
  entirely — all pixels, panda untouched, no firmware change — but needs a different
  module, a new cage OLED mount, and gives a much smaller clock. Worth revisiting if
  the sliced paws ever grate.

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
