# Vocetempo - Component Measurement Sheet

Fill in the **Yours** column, then the values go into `enclosure/dimensions.scad`
and the enclosure can be modelled against real parts instead of catalogue
numbers. Clones vary by a couple of mm, which is exactly the difference between
a case that closes and a reprint.

Everything is in **millimetres, to 0.1 mm**. Your caliper reads 0.01 mm, but an
FDM printer holds maybe ±0.2 mm, so extra digits are false precision.

---

## Before you start

**1. Zero it.** Close the jaws fully, press ZERO. Open and close again - it must
return to `0.00`. If it drifts, the battery is low.

**2. Sanity-check it against something you already know.** The best free
standard in the box is a **pin header's plastic base**: it is moulded as exactly
`N x 2.54 mm` (the bodies butt together so strips can be ganged), and unlike the
pins themselves it cannot bend.

Count the pins, measure the plastic base outer-to-outer, and it should read
`N x 2.54`. A 15-pin strip must give **38.1 mm**. Within 0.1 mm and the caliper
is good enough for everything here.

Do NOT calibrate against the pins - they lean, and the end ones leaning inward
reads short. If you do want to use them, remember the pitch is measured
centre-to-centre, so outer-to-outer is `2.54 x (N-1) + one pin width`.

> Lesson that applies everywhere below: **trust rigid references.** PCB edges,
> moulded plastic bodies and machined features measure repeatably. Pins, wires,
> thumb caps and speaker cones do not - treat those as approximate.

**3. Use the right part of the tool.**

| Feature | Use |
| --- | --- |
| Board length, width, thickness | Large lower jaws (outside) |
| Hole and slot diameters | Small upper jaws (knife edges, inside) |
| How far a connector sticks out | Depth rod (the tail that slides out the end) |
| Height of a part above its PCB | Depth rod, or the step on the back of the jaw |

**4. Light pressure.** PCBs are rigid, but thumb caps, foam and the speaker cone
compress. Squeeze hard and you will record a part smaller than it is, then print
a hole it does not fit through.

**5. Measure twice, in two places.** Boards warp and caps are never perfectly
round. For anything that needs **clearance** (holes, cutouts, cavities) record
the **larger** reading. For anything that needs a **press fit** (magnet pockets)
record the **smaller**.

---

## The centre-to-centre trick

You cannot put jaws on the middle of two holes, but mounting-hole spacing is
exactly what standoffs need. So measure edge to edge and correct:

```
   |<--------- A --------->|      A = outer edge to outer edge
   (  O  )           (  O  )
      |<----- C ----->|            C = A - d   (d = one hole diameter)
        |<--- B --->|              B = inner edge to inner edge
                                   C = B + d   <- same answer, use it to check
```

Do it **both ways**. If `A - d` and `B + d` disagree by more than 0.2 mm, one of
the readings slipped.

---

## Heights matter more than footprints

The usual mistake is measuring X and Y for everything and forgetting Z. The sled
depth is set by the **tallest thing in the stack**, which is likely the joystick
cap or the speaker.

Rather than adding up parts and hoping, **plug a module into its socket on the
perfboard and measure the whole assembled stack in one go**: perfboard underside
to the top of the tallest component. Do that for each module. Those four numbers
size the sled.

---

## 1. OLED - Hailege 2.42" SSD1309

For the active area, run the panel test first - it forces **every pixel on**, so
you can see the exact lit rectangle instead of guessing where the glass ends:

```sh
pio run -e oled_test -t upload
```

Then measure the **lit area**, and the gap from each PCB edge to the lit edge.
That gives size and position in one pass, which is what the window cutout needs.

| What | Variable | Nominal | Yours | How |
| --- | --- | --- | --- | --- |
| PCB width | `oled_pcb_w` | 72 | **68.63** | outside jaws |
| PCB height | `oled_pcb_h` | 40 | **46.60** | |
| PCB thickness | `oled_pcb_t` | 1.4 | **0.98** | ignore components |
| Glass width | `oled_glass_w` | 65 | **62.30** | the black panel, not the PCB |
| Glass height | `oled_glass_h` | 37 | **39.90** | at widest; ~1mm notch bottom-middle |
| **Lit area width** | `oled_active_w` | 55.0 | **55.0** | confirmed with `oled_test` |
| **Lit area height** | `oled_active_h` | 37.0 | **28.0** | confirmed; old 37.0 was impossible |
| PCB left edge to lit edge | *(for `oled_active_dx`)* | - | **7.35** | |
| PCB right edge to lit edge | *(for `oled_active_dx`)* | - | **7.35** | -> centred in X, dx=0 |
| PCB top edge to lit edge | *(for `oled_active_dy`)* | - | **6.2** | |
| PCB bottom edge to lit edge | *(for `oled_active_dy`)* | - | **12.6** | -> lit 3.1mm ABOVE centre, dy=+3.1 |
| Mounting hole spacing, horizontal | `oled_hole_dx` | 66 | **64.3** | edge-to-hole method (see below) |
| Mounting hole spacing, vertical | `oled_hole_dy` | 34 | **43.0** | |
| Mounting hole diameter | `oled_hole_d` | 3.0 | **2.5** | inside jaws |
| **Total depth, glass front to tallest thing on the back** | `oled_depth_hdr` | - | **12.55** | 6.23 bare, +6.3 for soldered header |

Give me all four edge-to-lit gaps and I will compute `oled_active_dx`/`dy`
myself - it is easy to get the sign wrong by hand.

> **Hole spacing without wedging jaws into a 2.5mm hole.** The centre-to-centre
> trick above assumes you can get a clean rim-to-rim reading; in a small hole the
> knife-edges over-read badly (we got 2.72 for a 2.5mm hole). What actually
> worked: measure **board edge -> near wall of the corner hole (A)** and
> **board edge -> far wall of the same hole (B)** with the big jaws closing on a
> flat gap. Then `centre-from-edge = (A+B)/2`, and by symmetry
> `spacing = board_dimension - (A+B)`. Cross-check: `B - A` must equal the hole
> diameter. This gave H: A=1.00,B=3.34 -> 68.63-4.34 = 64.3; V near-to-near=40.50
> -> +2.5 = 43.0. Both leave a sane wall to the edge, unlike the old 66/34.

## 2. ESP32 DevKit (DollaTek, CP2102) - MEASURED

| What | Variable | Nominal | Yours | How |
| --- | --- | --- | --- | --- |
| Board length | `esp_w` | 52 | **53.20** | |
| Board width | `esp_h` | 28.5 | **28.40** | |
| PCB thickness | `esp_t` | 1.6 | **1.45** | |
| USB-C shell width | `esp_usb_w` | 9.0 | **8.80** | across the metal shell |
| USB-C opening height | `esp_usb_h` | 3.2 | **3.10** | the port opening, for the wall cutout |
| USB-C stick-out past PCB | `esp_usb_out` | 1.5 | **1.5** | depth rod |
| Pin length below the board | `esp_pin_drop` | 10 | ~10 | |
| Tallest top-side part | `esp_top_h` | - | **4.63** | chip = USB-C height |

> No mounting holes -> **printed snap-in cradle** (pocket 53.2 x 28.4 + tabs).
> Note `esp_top_h` (board surface to top = 4.63) is NOT the USB opening height
> (3.10) - the shell doesn't start at the PCB face. Both are recorded separately.

## 3. DS3231 RTC (ZS-042) - MEASURED

| What | Variable | Nominal | Yours | How |
| --- | --- | --- | --- | --- |
| Board length | `rtc_w` | 38 | ~38 | ~nominal confirmed |
| Board width | `rtc_h` | 22 | ~22 | ~nominal confirmed |
| PCB thickness | `rtc_t` | 1.6 | **1.58** | |
| Battery holder diameter | `rtc_batt_d` | 20.5 | **21.63** | |
| Battery holder height above PCB | `rtc_batt_z` | - | **7.80** | tallest part; needs finger room to swap |
| Mounting hole diameter | `rtc_hole_d` | - | **2.30** | 3 holes: 2 by pins, 1 top corner |

> Battery is on the component side, top edge. **3 holes, not 4** - exact
> positions to be lifted from the photo when the RTC mount is designed.

## 4. DFPlayer Mini - MEASURED

| What | Variable | Nominal | Yours | How |
| --- | --- | --- | --- | --- |
| Module length | `dfp_w` | 21.6 | **20.70** | |
| Module width | `dfp_h` | 20.2 | **20.20** | |
| PCB thickness | `dfp_t` | 1.6 | **2.00** | |
| Tallest part above PCB | `dfp_top_h` | - | **4.96** | |
| SD slot mouth width | `dfp_sd_w` | 12 | **11.20** | |
| SD slot mouth height | `dfp_sd_h` | 1.6 | **0.86** | card thickness |

> SD slot and pin headers exit the **same edge** - keep it accessible. Only a
> half-slot on the opposite edge (no usable holes) -> **printed snap-in clip**.

## 5. Speaker - ENCLOSED BOXED UNIT (not a bare driver) - MEASURED

The nominal was for a 40mm round driver; the real part is a **rectangular boxed
speaker with 4 mounting ears** and flying leads.

| What | Variable | Nominal | Yours | How |
| --- | --- | --- | --- | --- |
| Body length (no ears) | `spk_box_l` | - | **51.25** | |
| Body width | `spk_box_w` | - | **30.90** | |
| Overall length (ear tip to tip) | `spk_overall_l` | - | **69.50** | ears on the length axis only |
| Total depth | `spk_h` | 6 | **16.38** | grille face to back |
| Grille opening (stadium) long | `spk_grille_l` | - | **37.35** | |
| Grille opening (stadium) short | `spk_grille_w` | - | **26.80** | |
| Ear hole diameter | `spk_ear_hole_d` | - | **3.20** | M3 |
| Ear spacing, long axis | `spk_ear_dx` | - | **63.60** | 60.4 n-to-n + 3.2 |
| Ear spacing, short axis | `spk_ear_dy` | - | **21.20** | |

> **Mounts to the TOP of the cage, grille UP, firing into the panda's HEAD
> chamber.** Head is the resonating port; vents out the face. All wiring stays
> on the cage. Grille and ears are on the same (up-facing) face.

## 6. Joystick (KY-023) - MEASURED

| What | Variable | Nominal | Yours | How |
| --- | --- | --- | --- | --- |
| PCB width | `joy_pcb_w` | 26 | **26.70** | |
| PCB height | `joy_pcb_h` | 34 | **32.30** | |
| PCB thickness | `joy_pcb_t` | 1.6 | **0.92** | |
| Gimbal body, narrow axis | `joy_body_w` | 24 | **19.80** | not square! |
| Gimbal body, wide axis | `joy_body_w2` | - | **23.40** | has a protruding nub |
| Gimbal body height above PCB | `joy_body_h` | 20 | **11.76** | |
| Widest flange diameter | `joy_flange_d` | - | **26.0** | THE part the cone must clear |
| Flange height above PCB | `joy_flange_z` | - | **12.0** | |
| Thumb cap diameter | `joy_cap_d` | 20 | **26.0** | |
| Cap top height above PCB | `joy_cap_z` | 32 | **29.43** | tallest thing in the whole build |
| Tilt half-angle | `joy_throw_a` | 25 | **23** | ~12.5mm cap sweep -> atan(12.5/29.43) |
| Mounting hole spacing X | `joy_hole_dx` | 20 | **19.85** | |
| Mounting hole spacing Y | `joy_hole_dy` | 28 | **19.80** | near-square, offset to pins |
| Mounting hole diameter | `joy_hole_d` | 3.0 | **3.20** | M3 |

> The cone must clear the **26mm flange at z=12** at 23deg tilt, not just the
> narrow stick - compute the panel opening from both.

## 7. Mounting & hardware - MEASURED / DECIDED

**No perfboard.** Modules screw to printed standoffs/bosses on the cage (or
snap-in cradles for the ESP32/DFPlayer), wired point-to-point. **Self-tapping
screws into printed bosses** - NO heat-set inserts (so the boss hole is a pilot
sized for the screw's core, and hole positions are forgiving).

| What | Variable | Nominal | Yours |
| --- | --- | --- | --- |
| Magnet diameter | `magnet_d` | 6.0 | **5.0** |
| Magnet thickness | `magnet_t` | 3.0 | **3.0** |

> Cage retained by **magnet PAIRS** (cage + body). Check polarity before gluing
> every magnet (offer to partner, let attract, mark, glue) - a reversed magnet
> repels and the cage won't seat. Press-fit + CA glue. Steel-washer variables
> kept unused as a fallback.
>
> RTC hole positions were read from the photo (~+-1.5mm); fine for self-tapping
> bosses but confirm with calipers if the fit is tight.

## 8. Cage layout - DECIDED

No stack-height table needed (no perfboard). Fixed requirements:

- **Front face (slides in / faces room):** OLED on top, joystick directly below.
- **Top face:** speaker, grille up into the head.
- **Back wall:** ESP32, RTC, DFPlayer mount flat, facing forward (shallow cage).

Envelope estimate: **~75 W x 89 H x 38 D mm** (width set by OLED 68.63; height by
OLED + joystick stacked; depth by OLED header + wiring + back-wall board pins,
and floored by the speaker's 31mm width needing to sit on the top face).

---

## When you're done

Paste the numbers back in any format - the filled tables, or just a list. I will
update `dimensions.scad`, work out the derived values (`oled_active_dx`/`dy`,
`joy_throw_a`), add the new variables that have no home yet, and flag anything
that looks off against the nominal figures.

If a part turns out very different from nominal, say so rather than assuming you
mismeasured - clones genuinely do vary, and a surprise is worth a second look
before it becomes a printed part.
