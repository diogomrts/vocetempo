# Vocetempo enclosure

Parametric 3D-printable enclosure for the panda-themed talking clock, written in
[OpenSCAD](https://openscad.org). The electronics live in a **slide-out cage**
that drops into a hollowed panda figurine from below, so the panda never has to
be opened to service the clock.

**Current body: v8, 217.4 mm tall (108.7% of the original sculpt).** The cage,
cavity and hardware cuts remain at their original size and position. Use the
new `joy_cap_scaled_body.stl` with this body; the original cap is too short.
Print the exports at **100% in the slicer** — do not scale the completed STL.

## Files

| File | Purpose |
| ---- | ------- |
| `dimensions.scad` | Every component measurement + design decision, in ONE place. **Edit here.** |
| `helpers.scad` | Shared shape modules (rounded box, screw boss, etc.). |
| `cage.scad` | The electronics cage - the real mechanical part. Print-ready. |
| `panda.scad` | The panda body: uniformly enlarges the original sculpt, then applies fixed-size hardware cuts. |
| `expand_rump.py` | Historical v5 local deformation generator; no longer used by the current body. |
| `fitcheck.scad` | Seats the cage in the body (ghost / section / breach modes). |
| `layout_walls.scad` | 2D map of all four mounting walls, unrolled (collision check). Includes `cage.scad`, so it cannot drift from the geometry. |
| `render_previews.sh` | Renders `previews/*.png`. |
| `verify_window.py` | Blender check: pixel coverage of the OLED window + exactly where its cut lands on the sculpt. Run it after touching `oled_win_*`. |
| `verify_cage.py` | Ray-casts the exported cage and asserts every mount is real: bosses on flat wall, OLED envelope clear, joystick standoffs proud of the back wall, base open, cover ledge present. Run it after touching any mount. |
| `verify_joystick_channel.py` | Checks the exported body against the printed cage, the joystick's full insertion sweep (including bare shaft and bent header), and the remaining rear wall. |
| `verify_entrance.py` | Checks the entrance against 353 cage positions and verifies that the local repair preserves the rest of the body and magnet supports. Reports higher corner interference separately. |
| `verify_rear_cover.py` | Historical v4/v5 rear-cover checks; not applicable to the uniformly scaled v6/v7 bodies. |
| `verify_assembly_alignment.py` | Audits actual OLED sight lines, speaker aperture/connected sound path/all 26 ear vents, USB alignment, unchanged cage geometry and the v8 internal-only correction. |
| `verify_uniform_body.py` | Checks exact uniform scaling, fixed hardware clearances, magnet supports, cage insertion and the longer cap at both PCB spacings/socket orientations. |
| `probe_skin.py` | Where the sculpt's belly surface is at any (X, Z). |
| `probe_env.py` | Belly / rump / half-width envelope per height - how big a box fits. |
| `fit_shell.py` | **Solves** `shell_prof` against the sculpt. Re-run after changing `cage_w`, `cage_d`, `cage_yfront`, `cage_z0` or `cage_h`. |
| `refit.py` | Derives EVERY host-dependent constant in one pass - the transform, `shell_prof`, the OLED and joystick placements, the head/neck/ear survey, the magnet check. Run it after swapping the sculpt or resizing the box. |
| `scale_sweep.py` | Host height vs every gate. This is the table that chose 200 mm. |
| `compare_mesh.py` | Diffs two sculpts (size, shape, where the surfaces moved). |

The Python tools need `numpy` (`verify_window.py` needs Blender). Every tool
reproduces `panda_raw()`'s frame exactly, so their numbers paste straight into
`dimensions.scad`.

## The cage (`cage.scad`)

A box, 75 (W) x 80 (H) x 88 (D) mm, open at the base (the "service side").
Its cross-section (defined by `shell_prof` in `dimensions.scad`) is a rectangle
whose FRONT FACE can be set back per height and whose CORNERS can be chamfered per
height. It stays flat, full and forward through the whole board-mounting zone - so
every module's bosses land on a real, flat wall - and only moves where there are no
features: the base fillet, the paw crests, and the shoulders. That is how it follows
the round panda without either spearing its corners through the skin OR moving the
walls away from the mounting bosses. On this host the `breach` fit-check renders
**completely empty**, and the cage-inside-body collision check has zero volume.

- **Front face:** the OLED window (the true 55 x 28 lit area, offset +3.1 mm up)
  and **nothing else**. The PCB is 68.63 x 46.60 and even 88 mm of depth does not
  make room for a second device on this wall.
- **Back wall:** the **joystick**, bolted to four standoffs on the wall's OUTER
  face; the DFPlayer lower-right and the USB-C exit slot lower-left, inside.
- **Side walls:** ESP32 (left, portrait, USB-C edge down); RTC (right, on its 3
  real holes). The corner chamfers never cut a side face (`cf` peaks at 1.92), so
  a side wall is full-depth through the whole board zone.
- **Top face:** stadium-shaped throat firing UP into the panda's head (the head
  is the acoustic resonator); four bosses for the boxed speaker's ears.
- **Base:** an outward flange with 4 magnet pockets (retains the cage in the
  body), a ledge round the inside of the walls, and a screw-on **base cover**.

### The joystick bolts to the OUTSIDE of the back wall

It is on the rump, not the belly: the OLED alone is 46.6 mm tall and the KY-023
adds another 26.7 plus clearance, which no front wall this sculpt offers can hold.

*How* it mounts changed with the re-fit. It used to drop into a pocket in a
thickened plinth inside the back wall, with the gimbal poking out through a bore and
a separate printed frame clamping the PCB down - all of that existed because the
module's own mounting holes (19.85 x 19.80) sit right on the edge of the bore the
gimbal (19.80 x 23.40) needs, so a boss there loses over half its section.

Turning the module round deletes the problem. With the PCB on standoffs on the
wall's OUTER face and the gimbal pointing away into the rump there is no bore, no
pocket, no plinth and no frame; the only thing that crosses the wall is five wires.
It also uses the module's own four holes, which is what they are for. Fit it before
the cage goes into the panda - the screws come from the rump side.

The cost is depth. Measured out from the cage's back face at panda Y-43:

```
 2.00  standoff
 0.92  PCB
11.76  gimbal body
14.68  proud of the wall  (the rump is 25.7 mm deep here, leaving 11.0 for the cap)
```

The rump has a **continuous insertion channel**, wide enough for the PCB and bent
header near the cage and narrowing toward the gimbal. The printed **stalk cap**
spans the remaining 11 mm to the surface and is fitted only after insertion.

### Assembly relief v2, 2026-10-07

The physical assembly needs more room than the original nominal clearance check
suggested. The joystick is mounted sideways, and the **left side when looking
straight into the panda's back** needs the deeper recess all the way across.
That side is **panda -X**. The first comparison's simplified hardware overlay
omitted the side projection and assumed the recorded 2 mm PCB stand-off; it must
not be used as a measurement of the assembled device.

The v2 body adds another **3 mm of depth beyond the first relief**, keeps the
channel **10 mm taller than the original**, and preserves the printed cage,
cover, cap bore, magnet seats and mounting locations:

- Main gimbal limit **Y-64.5**: **21.5 mm behind the cage wall**, 6 mm deeper than
  the original channel and 3 mm deeper than v1.
- PCB/header shoulders also gain **another 3 mm**, to Y-51 and Y-57.5.
- Bare-shaft groove **Y-67.43**: **24.43 mm behind the cage wall**, another 3 mm
  beyond v1. This allows 3 mm extra PCB spacing while keeping 0.8 mm beyond the
  recorded shaft tip.
- A **broad left recess** extends to X-22.9 and Y-64.5 through Z55. Above that it
  slopes inward with the narrowing rear skin and joins the **3 mm rounded roof**
  at Z75.35. Its 2 mm side corner radii avoid sharp notch corners.
- The continuous underside opening reaches approximately **Z19.2 mm**. The wall
  tapers above the opening; over Z25..75.35 the 0.5 mm inspection grid measured a
  minimum **1.06 mm** to the outside skin. The USB and cap holes are excluded.
  The user explicitly accepted a thinner rear wall for this clearance revision.

The export is one closed, consistently oriented solid. Checks pass for the
printed cage and the full insertion sweep with **3 mm extra PCB stand-off**, both
in-plane PCB/gimbal orientations, the bare shaft, both header directions and an
additional bulky left-side allowance. No unintended rear openings were found
above the entrance. These are geometric allowances, not confirmation of the
unmeasured assembly or a material-strength simulation.

Check the preserved v2 export from this directory:

```sh
# Requires numpy, trimesh, manifold3d, scipy and rtree:
python verify_joystick_channel.py stl/panda_body_joystick_relief_v2.stl
```

`stl/panda_body_joystick_relief_v2.stl` preserves the approved joystick revision.
The latest body adds the entrance fix and smooth rump expansion below. The original and first relief are
retained in `stl/previous/`.
See `previews/joystick_bottom_comparison_v2.png` for the actual channel profiles;
the blue line marks v1. Earlier comparison images are historical v1 views.

### Entrance relief v3, 2026-10-07

The printed cage caught a sharp lip between the feet. The old body cavity copied
the cage's narrowed base section, even though the wider upper cage wall must pass
that same height. At Z7.1 the lip projected about **1.8 mm into the insertion
path**. V3 removes it and adds a front-only **0.8 mm lead-in bevel**, tapering to
the existing front clearance at the flange seat, Z11.2.

Only 0.381 cm³ is removed, entirely within the front entrance below Z11.25.
The magnet pockets/supports, flange seat, OLED opening and joystick v2 geometry
are unchanged; none of the already-printed cage parts needs replacing. The
export is one closed solid. At 353 cage positions spaced 0.25 mm apart, entrance
overlap falls from 103.588 mm³ to zero. The seated cage and all joystick checks
also pass. See `previews/entrance_comparison_v3.png` and the accompanying check
reports.

**Scope limit:** the higher corner ridges beside the paws remain. Removing their
entire insertion envelope would open holes in the outer wall. A perfectly
straight full-body insertion still has up to 5.777 mm³ overlap there, unchanged
by this local repair. V3 fixes the reported entrance obstruction; it is not a
guarantee of a completely interference-free physical assembly.

`stl/panda_body_entrance_relief_v3.stl` preserves this revision for comparison.

```sh
python verify_entrance.py stl/panda_body_entrance_relief_v3.stl --baseline stl/panda_body_joystick_relief_v2.stl
```

### Reduced uniform enlargement v7, 2026-10-08

V7 reduces the body enlargement from **15% to 8.7%**, keeping the whole original
sculpt uniformly scaled about the ground-plane origin. Its round proportions are
unchanged. Overall size is **157.280 × 150.182 × 217.4 mm (W/D/H)**, down from
166.396 × 158.886 × 230 mm in v6. `panda_body_scale` controls only the body blank;
`panda_h`, `panda_raw()` and the original skin reference stay at 200 mm for the
already-printed cage and base cover.

**The lower-left notch corner sets the minimum scale.** With the fixed notch and
original outside shape, 108.7% leaves a minimum sampled wall of **1.019 mm** above
the underside flange seat at Z11.2. At 108.6% it drops to 0.976 mm. This is the
smallest tested scale in 0.1% increments that retains a 1 mm wall there. The
nearest-surface check covers 20,836 points, with 0.05 mm spacing along the limiting
lower edge; intentional USB and cap openings are excluded. This is a geometric
thickness measurement, not a material-strength guarantee. The wall higher up is
thicker because the unchanged notch and original outer curve are different
shapes; above Z25 its minimum is 6.667 mm, reduced from 10.538 mm in v6.

The cage cavity, v2 deep left joystick channel, v3 entrance lead-in, screen window,
14 mm cap bore, USB cutter, flange seat and magnet pockets keep their sizes and
coordinates. The sound chamber and ear vents follow the enlarged head; overlapping
original/scaled chimney sections join them to the fixed speaker position. The
screen is more recessed than on the original body, but less than in v6. The
underside remains open for cage insertion.

**Reprint the body and the matching `joy_cap_scaled_body` cap.** The back at the
cap centre is now 6.18 mm farther out than the original. The v7 cap has a **20 mm
stalk and 4 mm neck**, shortened from v6's 24 mm stalk; it retains the same keyed
socket and 16 mm thumb pad. It clears the unchanged bore in both socket
orientations, nominal and +3 mm PCB spacing, 0–11° tilt in 15° azimuth increments
(1,152 poses), also with a 10% radial size allowance. Print the neck solid and
check fit/movement before gluing. The cage, cover and retention bars are unchanged.

Validation: one connected closed body; the blank exactly matches the uniformly
scaled original; all fixed hardware cutters are clear; all four magnet supports
remain intact. The cage seats without collision and the repaired feet entrance
clears at 353 insertion positions. The existing **5.777 mm³ higher front-corner
interference remains**, so this is not a physical friction-free fit certification.
The PCB, sideways gimbal, bare shaft and both header orientations pass the existing
insertion-envelope checks, including the requested extra 3 mm PCB spacing.

**Latest body: `stl/panda_body_uniform_v8.stl`.** `panda_body.stl` and
`panda_body_joystick_relief.stl` are identical copies. The matching cap is
`stl/joy_cap_uniform_v7.stl`, also copied to `joy_cap_scaled_body.stl`.
`stl/Archive.zip` contains the current body, matching cap, unchanged cage/cover/bars
and printing notes. Slice these at **100%** to preserve the unscaled cavity;
217.4 mm usable print height is needed, plus any raft.

See `previews/uniform_body_comparison_v7.png` for original/v6/v7 size comparison
and `previews/uniform_body_section_v7.png` for the thinner rear-wall section.
Reports are `previews/uniform_body_v7_*checks.txt`.

```sh
# OpenSCAD Manifold; Python checks need numpy/trimesh/manifold3d/scipy/rtree.
openscad --backend=Manifold --export-format binstl -o stl/panda_body.stl panda.scad
openscad --backend=Manifold -D 'part="joy_cap_scaled_body"' -o stl/joy_cap_scaled_body.stl cage.scad
openscad --backend=Manifold -D 'mode="body_blank"' -o /tmp/blank.stl fitcheck.scad
openscad --backend=Manifold -D 'mode="hardware_void"' -o /tmp/hardware_void.stl fitcheck.scad
openscad --backend=Manifold -D 'mode="joystick_void"' -o /tmp/channel.stl fitcheck.scad
openscad --backend=Manifold -D 'mode="usb_void"' -o /tmp/usb.stl fitcheck.scad
python verify_uniform_body.py stl/panda_body.stl --scale 1.087 --channel /tmp/channel.stl --usb /tmp/usb.stl --blank /tmp/blank.stl --hardware-void /tmp/hardware_void.stl --cap stl/joy_cap_scaled_body.stl --baseline stl/panda_body_entrance_relief_v3.stl
python verify_joystick_channel.py stl/panda_body.stl --skin /tmp/blank.stl
```

Previous versioned bodies, caps and previews are retained for comparison. V4's
cover and v5's local rump deformation were rejected aesthetically; v6's uniform
115% enlargement was too large. The v5 generator/source pair is no longer used
by `panda.scad`. The original `joy_cap` remains available for 200 mm bodies.
Print exports and ZIPs stay local under the existing ignore rule.

### Assembly alignment audit / speaker inlet v8, 2026-10-08

V8 keeps v7's **108.7% sculpt, 217.4 mm height, 1.019 mm minimum notch wall,
fixed cage cavity and same cap**. A full export audit found that the speaker's
cage opening is centred at panda Y-7 (the cage speaker is shifted 8 mm), while
the neck chimney is centred near Y1. A 3.208 mm rear strip of the throat therefore
met body material immediately above the cage roof: 142.541 mm³ of obstruction
inside the exported throat cutter.

`panda_speaker_inlet()` now clears the whole opening through the roof and blends
it into the existing neck chimney. The speaker offset is shared in
`dimensions.scad` so the two parts cannot drift. It removes **580.715 mm³** of
internal plastic; the change stays at least **37.938 mm inside the outer skin**.
Nothing is added, and no external shape, electronics placement, magnet seat,
OLED/joystick/USB cut or cage geometry changes. The printed cage and v7 cap remain
usable; the body is the only updated print file.

The audit verifies:

- Current cage source versus already-printed `cage.stl`: **zero geometric change**.
  OLED, speaker and joystick bosses/pilots, base ledge and side-board mounts pass
  `verify_cage.py`.
- OLED: 55.4 × 28.4 mm body opening, centred X0/Z47.8; all 8,192 pixel sight lines
  clear the cage. The body shows **8,188**, with the same four extreme corner
  pixels masked by its original 2 mm corner radii.
- Speaker: full offset cage throat clear, connected inlet/chimney/head chamber,
  **all 26 ear vents open to the exterior**. Acoustic loudness/resonance has not
  been measured on a physical print.
- Joystick: fixed 14 mm bore at X0/Z50; sideways PCB/gimbal/header and bare-shaft
  insertion envelopes pass, including +3 mm PCB spacing and the deep left recess.
  The unchanged v7 20 mm cap passes all **1,152** movement poses.
- USB: both body and cage slots clear all **589** access-ray samples.
- Cage seating, four magnet supports, thin notch wall and repaired entrance still
  pass. The existing higher front-corner insertion interference remains unchanged.

Reports: `previews/assembly_v8_checks.txt`, `assembly_v8_cage_checks.txt`,
`assembly_v8_uniform_checks.txt` and `assembly_v8_joystick_checks.txt`.

```sh
openscad --backend=Manifold -D 'part="cage"' -o /tmp/cage-current.stl cage.scad
openscad --backend=Manifold -D 'mode="speaker_void"' -o /tmp/speaker.stl fitcheck.scad
openscad --backend=Manifold -D 'mode="speaker_inlet"' -o /tmp/inlet.stl fitcheck.scad
openscad --backend=Manifold -D 'mode="acoustic_void"' -o /tmp/acoustic.stl fitcheck.scad
python verify_cage.py stl/cage.stl
# /tmp/blank.stl comes from the body_blank export above.
python verify_assembly_alignment.py stl/panda_body.stl --baseline stl/panda_body_uniform_v7.stl --blank /tmp/blank.stl --cage-source /tmp/cage-current.stl --speaker /tmp/speaker.stl --acoustic /tmp/acoustic.stl --inlet /tmp/inlet.stl
```

### Printable parts (via the `part` selector at the bottom of `cage.scad`)

```sh
openscad --backend=Manifold -o stl/cage.stl      -D 'part="cage"'      cage.scad
openscad --backend=Manifold -o stl/cover.stl     -D 'part="cover"'     cage.scad
openscad -o stl/esp32_bar.stl -D 'part="esp32_bar"' cage.scad
openscad -o stl/dfp_bar.stl   -D 'part="dfp_bar"'   cage.scad
openscad -o stl/joy_cap_scaled_body.stl -D 'part="joy_cap_scaled_body"' cage.scad # current 217.4mm body
openscad -o stl/joy_cap.stl -D 'part="joy_cap"' cage.scad # historical 200mm body only
```

`cage` and `cover` need **Manifold**: both clip themselves to the panda mesh (the
cage's upper shell to the eroded skin, the cover to the sculpt's domed base). There
is no `joy_frame` any more.

Then check it:

```sh
python verify_cage.py stl/cage.stl
```

## Original 200 mm reference and design history

The following measurements describe the **200 mm reference used by the cage**.
The current v8 outer body is separately enlarged to 217.4 mm as described above.

`panda/panda_original_without_embosses.stl` removes the sculpt's embossed screen
plaque and belly knob, so openings no longer have to land on a sculpted feature.
It is the host, at **200 mm** tall. Both changes landed together, because they had
to: the replacement is a different size and shape, not the same mesh with two bumps
shaved off, and at 160 mm it did not fit the electronics at all.

| | old | de-embossed |
| --- | --- | --- |
| raw Z span | 0.95893 | 0.93937 (2% shorter) |
| raw Y span | 0.70079 | 0.64892 (7% shallower) |
| raw X | 0.44 mm off-centre | symmetric |
| belly @ the screen, X0 | plaque | smooth, no feature to key off |

The transform is now **derived from the mesh** rather than hand-fitted, so swapping
the sculpt again changes two constants instead of the whole design:

```
panda_scale   212.9096      (= 200 / 0.93937 raw Z span; was a hand-fitted 166.7)
panda_y_off     9.036       (was a hand-fitted 26)
panda_x_off     0           (this mesh is symmetric)
```

`refit.py` prints the entire constant set for a given host in one pass, and every
number in `dimensions.scad` that depends on the sculpt came from it.

### What 200 mm buys, and what it does not

The parts do not scale - a 2.42" OLED is 68.63 x 46.60 whatever size the panda is -
so the host's size *is* the clearance budget. `scale_sweep.py` sweeps it:

```
panda_h | yfront | cage_d | plate band (cage Z) | top setback | recess | rump
    160 |   36.0 |   70.4 |   2.0.. 32.0 =  30.0 !|      7.9   |   12.6 |  19.9
    180 |   40.5 |   79.2 |   2.0.. 36.0 =  34.0 !|     17.9   |   14.4 |  22.8
    190 |   42.8 |   83.6 |   2.0.. 38.0 =  36.0 !|     19.8   |   15.2 |  24.2
    200 |   45.0 |   88.0 |   2.0.. 62.0 =  60.0  |     16.2   |   15.7 |  25.7
    210 |   47.2 |   92.4 |   2.0.. 66.0 =  64.0  |     12.7   |   16.1 |  27.1
! = the front plate is shorter than the OLED's 46.6mm PCB, so the screen cannot mount
```

200 is the smallest host where the front plate is long enough to hang the screen on.
Below it the plate collapses to ~30-36 mm against the 46.6 the PCB needs.

It also unpicks the deadlock that stopped the re-fit landing for a session. At 160
`cage_h` had exactly one legal value with 0.8 mm to spare - the belly pinched at
panda Z72, capping it at 64, against the 61.2 mm (`cover_ledge_h` 6 + margin 2 +
`esp_w` 53.2) a portrait ESP32 needs - and at that height the ESP32's USB-C mouth
landed on the cover ledge, so a straight plug was impossible and the panel-mount
port became mandatory. At 200 the box is 80 tall, the interior is 78, and
`6 + 2 + 16 (straight plug) + 53.2 = 77.2` fits with 0.8 to spare. The panel-mount
port is optional again.

What it does **not** fix is the screen recess, and that is permanent:

```
lateral belly drop from X0 out to |X|35.5, i.e. across the OLED's own width
  panda_h 160:  3.5mm @Z26   7.7mm @Z38   4.3mm @Z50
  panda_h 200:  4.4mm @Z33  10.1mm @Z48   5.4mm @Z63
```

A flat 68.63 mm-wide board can only come as close as the NARROWEST point across its
own width, and that drop grows with scale at about the same rate as the belly moves
forward. The landed figure is **15.7 mm** with `so_h_oled` 7, or **10.7 mm** if the
left-edge header is desoldered and it drops to 2. ~11 mm is the floor for this board
on this belly at any scale; only a narrower display changes it.

### The front wall steps back (`shell_prof`'s fourth column)

With a **single-plane** front wall, cage height and screen depth fight each other
directly, because the plane has to clear the arm pinch at the very top:

```
panda_h 200, max flat-front Y vs how high the cage reaches
  top at panda Z74 -> yfront 41.6      top at Z80 -> 33.7      top at Z86 -> 29.6
```

A cage tall enough for the ESP32 would therefore drag the front wall back to Y29.6
and bury the screen ~31 mm deep. `shell_prof` now carries a per-height FRONT SETBACK
(`fyb`, the fourth column) so the front plate holds Y45 through the OLED's whole span
and steps back only above the arms - 0 up to cage Z62, then 0.86 -> 16.57 by the top.
That is the change that lets the screen and the ESP32 both fit. `shell_section()` in
`helpers.scad` already took an `fyb` argument; `shell_stack()` and `prof_fyb()` pass
it through.

A second consequence: on this host `cb` is **0 at every height**, so the back wall is
full width for the first time and the joystick, the DFPlayer and the USB exit share
an uncramped 71 mm.

`PANDA_STL=panda/panda_original.stl python fit_shell.py` switches the tools back to
the old sculpt for comparison.

## The panda body (`panda.scad`)

Imports the sculpt **untouched**, hollows only where the cage sits, and cuts the
OLED window (belly), the joystick cap bore + continuous insertion channel (rump), the
**USB-C exit** (rump), the speaker chimney into the hollow head, the ear grilles,
and the base hatch/rebate. Needs the **Manifold** backend (`--backend=Manifold`);
the 500k-triangle mesh is far too slow for CGAL.

Three things about this host are worth knowing before editing it:

- **The base is domed.** Its lowest points are the outer edges of the feet at
  |X|~40 (panda Z0.5); at X0 the body does not start until Z~1.5, and at Z2 the
  silhouette has already tucked back to Y40.3 at X0 and Y28.7 at |X|34. That is why
  `cage_z0` is 7, why the base flange's front rim is a *pull* rather than a reach,
  and why the base cover is intersected with the sculpt instead of being a flat
  plate (it would otherwise stand up to 14 mm proud of the belly).
- **The joystick channel opens through the underside.** V2/V3 also broke through
  the rear skin up to about Z19.2. V5 expands the original rump to close the rear breakout while
  preserving the underside entrance and the entire insertion channel.
- **Y coordinates do not scale with the host.** X and Z do, but `panda_y_off` moved
  when the transform stopped being hand-fitted, so anything hard-coded in Y - the
  head cavity centre, the ear plenum and ducts, the skin-erosion axis - has to be
  re-measured, not rescaled. Rescaling puts the ear plenum 20 mm outside the mesh.

The original sculpt is never edited in place. V5 generates a derived outer sculpt
with a smooth local expansion before the functional openings are subtracted.

### There is no colour split, on purpose

`panda.scad` used to have a `colored_3mf` mode that carved the classic black/white
panda markings out of the body with boxes, spheres and prisms and exported them as
two shells for a multi-material slicer. **It has been removed.**

The markings are curved features that follow the surface, and they are simply not
describable by primitives. Intersecting the body with analytic solids gives
boundaries that cut *across* the sculpted shapes instead of along them - straight
lines where the arm meets the chest, and eye patches that either spill past the
sculpted almond or shrink to the pupil depending on how the curved face happens to
slice the solid. No amount of tuning the numbers fixes that, and the numbers had to
be re-guessed on every host change because they were pure eyeballing.

## The OLED window (and the paws it no longer cuts)

**Requirement: every one of the 128×64 pixels must be visible.** So the window is
the full lit area + `fit_gap` (`oled_win_w × oled_win_h` = 55.4 × 28.4 mm), and the
sculpt's folded paws are allowed to be cut through if they stand in the way.

At 160 mm they did: the cut took **8.1 mm off each paw** over Z42–58 and the arms
ended abruptly at the screen. **On the 200 mm host they do not.** The paws are 25%
further apart - their inboard edges are at |X|29.5 at panda Z40 and |X|35.5 at Z47.8
against the window's 27.7 - so the arms stay exactly as sculpted.

Verify with:

```sh
cd enclosure && blender -b -P verify_window.py
```

which checks pixel coverage and reports exactly where the cut lands. Current result:
**8188 of 8192 lit pixels visible**, both corner icons on screen, **0.00 mm into the
paws**, 0.00 mm into the shoulder, 0.83 mm into the feet.

### The corner radius is the one real knob

It trades corner pixels against the feet, whose top-inner corners are the only thing
the window still touches. The table below was measured at 160 mm, where the bite was
about 2.5× what it is now:

| `oled_win_r` | lit px hidden | corner icons | bite into the feet |
| --- | --- | --- | --- |
| **2.0 mm** (current) | **4 / 8192** | both survive | 2.1 mm at Z32–35 |
| 4.0 mm | 48 | both clipped | 1.1 mm |
| 6.0 mm | 120 | both clipped | 0.04 mm |
| 8.0 mm | 236 | both clipped | none |

r = 2.0 is chosen because the requirement is all pixels: it hides one pixel per
corner and keeps the quiet-hours and mute icons, which live in the top corners, on
screen. The price on the 200 mm host is a **0.83 mm** nick in each foot's top-inner
corner.

### What was rejected

All of these were built and measured:

- **Sizing the window to the sculpt's own embossed screen plaque** (36 × 21 mm, its
  raised frame becoming the bezel). Geometrically perfect — nothing trimmed or
  deformed, rim on flat plaque to ±0.15 mm — but it exposes only an 84 × 48 safe area,
  hiding a third of the panel. Rejected on the pixel requirement, and moot now: the
  host is the de-embossed sculpt, which has no plaque.
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
# should render to NOTHING; any solid at all = the cage breaches the skin
openscad --backend=Manifold -o /tmp/breach.stl -D 'mode="breach"' fitcheck.scad
openscad --backend=Manifold -D 'mode="ghost"'   fitcheck.scad   # visual overlay
openscad --backend=Manifold -D 'mode="section"' fitcheck.scad   # X=0 cross-section
```

The cage cross-section (`shell_prof`, 88 mm depth, per-height front setback plus
corner relief) is **solved** against a rasterisation of the raw skin - not tuned -
so every point of every section stays 1.6 mm inside the surface. On this host the
breach renders completely empty, where the old one left a 0.27 mm speck.

Worth knowing: intersecting the placed cage with the finished body is *not* empty,
but its volume is exactly 0 - the facets it produces are the flange's top face lying
on the rebate ceiling (they are meant to touch) and the eroded-skin surface both the
cage and the cavity are clipped to. Check the volume, not the facet count.

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
  opening the shell. At 200 mm a straight USB-C plug fits, so the panel-mount
  port is an upgrade rather than a requirement.
- **The joystick comes off with four screws** from the rump side - no frame, no
  pocket, no bore to line up.
- **No perfboard:** modules screw directly to printed standoffs/bosses (ESP32 &
  DFPlayer, which lack holes, use screwed retention bars). Wired point-to-point.
