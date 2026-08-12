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

Imports `panda/panda_original.stl` (never edited in place), scales it to 160 mm,
hollows only where the cage sits, and cuts the OLED window, the joystick cone, the
speaker chimney into the hollow head, the ear grilles, and the base hatch/rebate.
Needs the **Manifold** backend (`--backend=Manifold`); the 500k-triangle mesh is
far too slow for CGAL.

**The folded arms / paw ends.** The OLED's lit area is 55.4 mm wide but the sculpted
belly plaque is only ~40 mm, so the window's side edges land on the sculpt's folded
paws. The arms cannot be relocated - at screen height they *are* the body's flank
(there is no belly surface behind them), the cage needs that material, and the belly
falls away too steeply outboard for a rigid slide to work - so instead each paw is
**shortened, with its inboard tip rolled off to stop 0.4 mm short of the window
rim**: everything in front of a bezel plane (`arm_y`, the plaque's own face level)
inside a box around the arm is planed off, except an idealised arm - `arm_chain`, a
chain of hulled spheres centred on that plane whose first sphere is tangent to the
aperture. Because the sphere centres lie on the bezel plane, the surviving surface is
a rolling-ball sweep: smooth along the arm and tangent to the window rim instead of
sliced.

`paw_r` is the knob that matters. Wherever the ball touches the window it reaches the
same place whatever its radius, but a big ball leans away much more slowly and so
undercuts far less of the paw behind the contact - at `paw_r = 16` only a ~3 mm strip
of each paw is reshaped and everything outboard of X-31 is bit-for-bit the original
sculpt (checked against the raw mesh: front-Y 62.5 at X-31, Z50, both before and
after). Every face of the trim box sits where the sculpted skin is already behind the
bezel plane (verified: 0.00 mm step on all four faces, 0.00 mm removed outboard of
X-37), so the cut leaves no steps anywhere. This replaces an earlier countersink
around the window (`oled_bevel_*`), which left two flat "wings" beside the screen.

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
