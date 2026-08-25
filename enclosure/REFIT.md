# Re-fit spec: 200 mm host, de-embossed sculpt

> **LANDED 2026-08-21.** Sections 1-6 below are implemented in `dimensions.scad`,
> `panda.scad`, `cage.scad` and `helpers.scad`; the tools now default to this host,
> `verify_cage.py` and `verify_window.py` are green, and the `breach` fit-check
> renders empty. This file is kept as the derivation record. **Where it and the
> source disagree, the source is right** - see "Corrections found while applying it"
> at the bottom, which lists every place the spec turned out to be wrong or
> incomplete.

Every number here is solved against `panda/panda_original_without_embosses.stl` by
the tools in this directory (`refit.py`, `fit_shell.py`, `scale_sweep.py`,
`probe_skin.py`).

Re-derive any of it with:

```sh
python refit.py                     # full constant set for a given host
python scale_sweep.py               # host height vs every gate
PANDA_STL=panda/panda_original.stl python fit_shell.py   # compare to the old host
```

---

## 1. Host

```
panda_stl     = "panda/panda_original_without_embosses.stl"
panda_h       = 200
panda_scale   = 212.9087          # = 200 / 0.93937 raw Z span
panda_y_off   =   9.036           # panda_raw() translate; was a hand-fitted 26
panda_x_off   =   0               # this mesh is symmetric (the old one was 0.44 off)
```

`panda_raw()` becomes
`translate([0, panda_y_off, 0]) rotate([0,0,180]) scale(panda_scale) import(...)`,
which reproduces the frame every tool here uses: X centred, feet on Z0, belly at
+Y, Y bounding box centred on Y0.

## 2. Cage envelope

```
cage_w = 75      cage_h = 80      cage_d = 88      cage_z0 = 7
cage_yfront = 45                  -> cage_yc = 1
```

* `cage_h 80` gives 78 mm of interior. A portrait ESP32 needs 61.2, or 77.2 with a
  straight USB-C plug - so at 200 mm the straight plug fits and the panel-mount
  port goes back to being optional. At 160 mm only 62 mm was available, which is
  what deadlocked the whole layout.
* `cage_d 88` leaves 25.9 mm of rump and, critically, a real base rim for the
  magnets. Going deeper shortens the joystick stalk but eats that rim: at
  `cage_d 100` the rump is 13.9 mm but the hatch reaches within ~5 mm of the skin
  front and back.
* `cage_yfront 45` is the front PLATE position, held through the board zone by the
  new setback column (section 3).

## 3. shell_prof - now four columns

`[z, cf, cb, fyb]`. The 4th is a per-height FRONT SETBACK; `shell_section()` already
took an `fyb` argument, and `shell_stack()` + `prof_fyb()` now pass it through
(already committed in `helpers.scad`).

Without it, cage height and screen depth fight directly - a single front plane has
to clear the arm pinch at the very top, so a cage tall enough for the ESP32 (top at
panda Z87) drags the front back to Y29.6 and buries the screen ~31 mm deep.

```
shell_prof = [
  // z      cf      cb     fyb
  [  0.0,   0.00,   0.00,   2.22],
  [  2.0,   0.00,   0.00,   0.22],
  [  4.0,   0.00,   0.00,   0.00],
  [ 42.0,   0.00,   0.00,   0.00],   // ---- front plate at full Y45 ----
  [ 44.0,   1.52,   0.00,   0.00],
  [ 46.0,   1.81,   0.00,   0.11],
  [ 48.0,   0.00,   0.00,   0.00],
  [ 62.0,   0.00,   0.00,   0.00],   // ---- arms start to pinch above here ----
  [ 64.0,   0.00,   0.00,   0.86],
  [ 66.0,   0.00,   0.00,   2.58],
  [ 68.0,   0.00,   0.00,   4.49],
  [ 70.0,   0.00,   0.00,   7.15],
  [ 72.0,   0.00,   0.00,  10.04],
  [ 74.0,   1.91,   0.00,  12.40],
  [ 76.0,   1.91,   0.00,  13.76],
  [ 78.0,   1.92,   0.00,  15.16],
  [ 80.0,   1.92,   0.00,  16.57],
];
```

Rows between 4 and 42, and between 48 and 62, are all zeros - collapse them as
shown or write them out, the loft is linear either way. `cb` is **0 everywhere**,
so the back wall is full width for the first time: the joystick, the DFPlayer and
the USB exit all get an uncramped 71 mm to share.

## 4. Devices

```
dev_oled_pz = 47.8        OLED lit-window centre, panda Z
                          -> oled_cz 37.7, PCB spans cage Z14.4..61.0
                          -> bosses at cage Z16.2 and 59.2, both on flat wall
dev_joy_pz  = 50          joystick centre, panda Z, on the RUMP
so_h_oled   = 7           still clears both of the OLED's back headers
```

Screen recess is **15.7 mm** (10.7 if the left-edge OLED header is desoldered and
`so_h_oled` drops to 2). That is close to the floor for this display - see
`README.md`; a flat 68.63 mm board can only reach the narrowest point across its own
width, and that lateral belly drop is 4-10 mm at any scale.

### Joystick: change how it mounts

Move it from the pocket-and-frame arrangement to **standoffs on the OUTER face of
the back wall**, using the KY-023's own four holes. With the gimbal pointing away
from the wall there is no bore/boss conflict, so this deletes `joystick_plinth()`,
`joystick_pocket_cut()`, `joystick_bore_cut()`, `joystick_frame_bosses()` and the
whole `joy_frame` part. Only a small wire slot remains.

```
2 mm standoffs off the outer face -> PCB at panda Y-45, gimbal top at Y-57.68
rump skin at panda Z50 is Y-68.71   ->  joy_cap_stalk = 11.0
```

The rump insertion channel stays (the assembly now stands ~13 mm proud of the back
face instead of 9), and must clear the 32.3 mm PCB rather than the 24 mm gimbal.

## 5. Head, neck, ears

Both frames are the same mesh at different scales, so these scale linearly from the
values `refit.py` derived at 160 mm - multiply by **1.25**:

```
head_c   = [0, -5.0, 147.5]        head_r = [45.0, 37.5, 35.0]
sp_z0    = 75      sp_z1 = 135     sp_cy  = cage_yc
ear_cx   = 51.4    ear_cz = 182.9
ear_pl_y1 / ear_pl_y0 / ear_duct_y / ear_duct_y2 and every ear_ducts coordinate:
  scale by 1.25 as well
```

Verify with the existing empty-render checks: `panda_head_cavity()` minus the skin
must render empty, and all three ducts per ear must terminate inside the cavity.

## 6. Everything else that moves

* `cover_screws` - the flange grows with `cage_d`; put the six back on the ledge
  (sides `x +-33`, front `y -41`, back `y +40`), all inboard of the magnet ears.
* `mag_pos` - re-verify with `refit.py` section 8 once `cage_yc` is 1. The four
  positions scale with the flange, and the hatch is now 77 x 90.
* `usb_slot_z` - keep it aligned with the ESP32's receptacle mouth
  (`esp_cz - esp_w/2 - esp_usb_out`), as fixed previously.
* `cav_clip_z`, `skin_cy`, and the `skin_inset()` erosion radius (currently a
  hard-coded 34) all need the 200 mm figures: `skin_cy` ~-5, radius ~62.

## 7. Order of work

1. `dimensions.scad` - sections 1, 2, 3, 4 above.
2. `panda.scad` - `panda_raw()` transform, then section 5, then the rump joystick
   cuts (bore + PCB pocket + wider insertion channel) and the USB cut.
3. `cage.scad` - joystick to the outer face (section 4), then re-check the ESP32 /
   RTC / DFPlayer / speaker / cover positions against the taller, deeper box.
4. `python verify_cage.py stl/cage.stl` and the `breach` fit-check mode.
5. `./render_previews.sh` and re-export all STLs.
6. Update `README.md` (drop the "swap is pending" section), `docs/ASSEMBLY.md`
   (joystick fitting order changes), `docs/MEASUREMENTS.md` (cage envelope).

All six steps are done. `verify_cage.py` passes, `verify_window.py` passes, and the
breach check - a 0.27 mm speck on the old host - now renders completely empty.

---

## 8. Corrections found while applying it

The spec above is accurate about the cage envelope, `shell_prof`, the OLED, the
joystick and the head. Six things it got wrong or left out, all caught by measuring:

1. **`front_rim` cannot stay positive** (section 6 does not mention the flange's
   front). Over the flange's own Z band (panda Z7..11.2) the belly bottoms out at
   Y44.38 around \|X\|27, so a 4 mm outward front rim - panda Y49 - pokes out of the
   belly across \|X\|15..27. It is now `front_pull = 3` (panda Y42). The BACK, by
   contrast, gained an outward rim: the rump gives 10 mm+ there at cage_d 88.

2. **The magnet positions do not simply "scale with the flange".** `(+-34, -40)`
   scaled to panda Y50 fails: at panda Z7 the foot's inner edge is at \|X\|~28 and
   the skin there is only Y52.4, so the pocket's outboard halo breaks out. Solved
   positions are cage `(+-38, -49)` and `(+-44, -16)`. Note also that refit.py's
   original `solid_at()` was a convex `back < y < front` test, which calls the gap
   between the feet and the belly solid - it is now a crossing-parity test.

3. **The front cover screws cannot go at `y -41`.** `shell_prof` row 0 sets the
   front face back 2.22 mm, so the front ledge's outer edge walks from y-39.78 at
   cage Z0 to y-42 at Z4. `-38.5` is the only band on the ledge over the whole
   0..6 run. (Sides `+-33` and back `+40` are as specified.)

4. **The base cover cannot be a flat plate at `cage_z0` 7.** The sculpt's base is
   domed - at panda Z2 its silhouette has tucked back to Y40.3 at X0 and Y28.7 at
   \|X\|34 - so a 7 mm prism of the cage footprint stands up to 14 mm proud of the
   belly. It is now intersected with the sculpt. The base hatch was likewise
   changed from a plain `cage_d + 2` rectangle to the cage's own row-0 section, so
   it stops cutting 3 mm further forward than the cage actually reaches.

5. **The ear's Y values must be re-measured, not scaled by 1.25** (section 5 says
   to scale them). `ear_cx` and `ear_cz` do scale - 51.4 / 182.9 is right, and the
   density centroid confirms 51.46 / 183.35 - but `panda_y_off` moved from a
   hand-fitted 26 to a derived 9.036, so the whole Y frame shifted. The old plenum
   at Y13.5..18.0 scaled to 16.9..22.5 is ~20 mm outside this mesh; measured, it is
   Y-7.8..-2.2. The duct START points must also keep their original (unscaled)
   offsets from the dish centre, because the grille itself does not scale - scaling
   them walks the lowest duct off the edge of the plenum it opens into.

6. **`cav_clip_z` had to go UP, not just scale.** 50 x 1.25 = 62.5, but the front
   plate now runs at panda Y45 with as little as 1.9 mm of belly over it at Z69,
   and the skin erosion is 1.35 mm - clipping there would shave the wall the OLED's
   bosses stand on. It is 71 (cage Z64), exactly where `fyb` starts. The erosion
   radius was measured at 57-60 over the pinch, so `skin_r` is 60 rather than 62,
   and `cav_*` / `skin_*` moved to `dimensions.scad` because `use <panda.scad>`
   imports modules but not variables - `cage_clip_z` was silently undef otherwise.

Also worth recording: **the OLED window no longer cuts the paws at all.** At 160 mm
it took 8.1 mm off each; at 200 mm their inboard edges are at \|X\|29.5 (panda Z40)
and \|X\|35.5 (Z47.8) against the window's 27.7. `verify_window.py` reports 0.00 mm
into the paws, 0.00 into the shoulder, 0.83 into the feet, 8188/8192 pixels visible.
