# Vocetempo - Assembly, Soldering & Enclosure Plan

How to take the working breadboard build and make it permanent, serviceable and
reliable. Wiring itself (which pin goes where) is in [`WIRING.md`](WIRING.md);
this document is about the physical build.

---

## 1. The sled concept - review

The plan is a rectangular opening in the body, and a separate box ("the sled")
carrying all the electronics that slides in and out, held by magnets and
screws, with the speaker poking up through the sled's roof into the head.

**This is the right architecture, for one reason above all: no wire crosses the
boundary.** Every failure I would expect in a design like this comes from
cabling that has to be unplugged to open the case, or that flexes every time you
do. If the speaker rides on the sled and fires *up into* the head - rather than
being mounted in the head and wired down - then the sled is a single
self-contained unit with exactly one thing attached to the outside world: the USB
lead. That is as good as it gets.

Three changes worth making:

**a) The sled's front face should be the visible front panel.** Put the OLED and
the joystick on it. If they are mounted in the body instead, their wires cross
the boundary and the whole benefit is lost. The belly opening becomes a flat
recessed rectangle that the sled face fills.

**b) Magnets *or* screws for routine access, not both.** Two magnets and two
screws means undoing screws every time, so the magnets are decoration. Use
magnets as the only routine retention, and add the screws as an *optional*
lock - handy if the clock ever travels, unnecessary on a bedside table. If you
do want both, put the screws where a screwdriver reaches without moving the
clock (i.e. the underside, not the back).

**c) Seal the speaker to the sled roof.** A speaker with an open back cancels
its own bass - the rear wave meets the front wave and the low end largely
disappears. Mounting it in the sled roof does something genuinely good here: the
head becomes the front chamber and the sled interior becomes the sealed rear
volume. That only works if the joint is airtight, so fit a thin foam or silicone
gasket between the speaker flange and the sled roof. It is the difference
between a tinny beep and a voice.

---

## 2. Extra parts to buy

| Part | Spec | Why |
| --- | --- | --- |
| Perfboard | ~70 x 50 mm, 2.54 mm pitch | Sled backbone (`perf_w`/`perf_h`) |
| Female header strip | 2.54 mm, ~60 pins total | Sockets so modules unplug |
| Neodymium discs | 6 x 3 mm, x2-x4 | Sled retention (`magnet_d`) |
| Steel washers | M4-M6, 12 mm OD, x2-x4 | Magnet counterpart in the body |
| Heat-set inserts | M3 brass, 4.2 mm OD | Screw threads that survive re-use |
| Screws | M3 x 8 mm cap head | Optional sled lock |
| Electrolytic cap | 470 µF, 6.3 V+ | DFPlayer bulk decoupling - see §3 |
| Ceramic caps | 2 x 100 nF | Local decoupling for RTC and OLED |
| JST-PH connector | 2-pin | Speaker, the one thing worth unpluggable |
| Foam/silicone strip | 2-3 mm, self-adhesive | Speaker gasket |
| Heat-shrink | 2 mm and 4 mm | Strain relief on every joint |
| Silicone wire | 26-28 AWG, stranded | Flexes without work-hardening |
| Coin cell | **LIR2032**, not CR2032 | RTC backup - see the warning in §3 |

Use **stranded silicone** wire, not solid core. Solid core is easier to poke
into a breadboard and is exactly wrong here: it work-hardens and cracks at the
solder joint after being flexed a few times, which is the classic
intermittent-fault-that-takes-a-week-to-find.

---

## 3. Electrical work to do before closing anything up

These are not optional polish. Each one prevents a specific failure.

### 3.1 Bulk capacitor across the DFPlayer's 5 V

**Do this one.** The DFPlayer's onboard amplifier pulls current in sharp bursts
as the voice plays. On breadboard wiring that shows up as audible popping, and
at worst it drags the 5 V rail down far enough to brown out the ESP32
mid-announcement - which then looks like a random reboot and is very hard to
diagnose.

Solder a **470 µF electrolytic** directly across the DFPlayer's `VCC` and `GND`
pins, as physically close to the module as possible. Watch polarity: the striped
side is negative.

### 3.2 DS3231 coin cell - read this before fitting a battery

The RTC has no backup cell yet (`PLAN.md`), so it forgets the time on every
power cut. Fitting one is the single biggest reliability win available.

> **The ZS-042-style DS3231 modules - which is what the DollaTek board is -
> include a charging circuit for a rechargeable LIR2032. If you fit a
> non-rechargeable CR2032, the board will try to charge it. A CR2032 being
> charged can leak or vent.**

Two safe options:

1. **Fit a LIR2032** (rechargeable, 3.6 V) and leave the board alone. Simplest.
2. **Fit a CR2032** and first disable the charger by removing the series diode
   (marked `D1`) or the charging resistor next to it. A CR2032 will then run the
   RTC for years.

Do not fit a CR2032 to an unmodified board.

### 3.3 Local decoupling

A 100 nF ceramic across `VCC`/`GND` at the OLED and again at the RTC. Cheap
insurance against I2C glitches on longer wiring - and the firmware already has
bus-recovery code (`main.cpp`) precisely because this bus has misbehaved before.
Better not to need it.

### 3.4 Keep the speaker leads away from the I2C pair

Route the two speaker wires down one side of the sled and the `SDA`/`SCL` pair
down the other. Speaker leads carry a relatively large swinging current; running
them alongside I2C for 10 cm is asking for corrupted reads.

### 3.5 Twist the I2C pair

Lightly twist `SDA` and `SCL` together with the ground return. Costs nothing,
measurably improves noise immunity.

---

## 4. Interconnect: socket the modules, solder the wiring

Do **not** solder the modules themselves down. Solder *female headers* to the
perfboard and plug the modules in.

```
   module (ESP32 / RTC / DFPlayer)
        │ male header pins (already on the module)
   ═════╪═════  female header, soldered to perfboard
        │
   ─────┴─────  perfboard: wiring soldered on the underside
```

Why: every interconnect is a proper soldered joint, so nothing works loose - but
any module that dies can be swapped in a minute without a desoldering iron. For
a static bedside device there is no vibration argument against sockets.

The two exceptions:

- **Speaker** - terminate in a 2-pin JST-PH so the sled roof can come off
  without cutting wires.
- **Joystick and OLED** - short flying leads soldered directly, since they are
  fixed to the sled's front face and never need to detach independently.

### Wiring the perfboard underside

- Bare tinned wire for the shared rails (a 3.3 V bus, a 5 V bus, a ground bus),
  run as straight lines along the board. Insulated jumpers for signals.
- Build the **ground bus first and make it generous.** Every reliability problem
  in a mixed digital/analog/audio build traces back to grounding. The joystick's
  ADC readings and the audio amp share this ground; a thin, shared, daisy-chained
  ground is how you get a noisy stick and a buzzing speaker.
- Star the grounds where you can: run the DFPlayer's ground back to the ESP32
  ground pin on its own path rather than chaining it through the RTC and OLED.

---

## 5. Soldering order - and what to test after each step

Solder one thing, verify it, then move on. The project already has a diagnostic
tool per subsystem, which is exactly what makes this practical. If step 5 breaks
something you know it was step 5.

| # | Solder | Verify with | Expected |
| --- | --- | --- | --- |
| 1 | Female headers + power/ground buses | Multimeter, **before** plugging anything in | 3.3 V and 5 V present at every socket; no continuity between rails; no rail-to-ground short |
| 2 | ESP32 socket only | `pio run -e esp32dev -t upload` | Boot banner on serial |
| 3 | I2C pair + OLED and RTC sockets, + 100 nF caps | `pio run -e i2c_scanner -t upload` | Devices at `0x3C`, `0x68`, `0x57` |
| 4 | OLED flying leads | `pio run -e oled_test -t upload` | Test pattern, no flicker |
| 5 | Joystick flying leads | `pio run -e joystick_test -t upload` | Idle `x`/`y` near 1900-2100, `dir=None`; each push reads correctly |
| 6 | DFPlayer socket, 1 k resistor on RX, 470 µF cap | `pio run -e folder_test -t upload` | Folder addressing works |
| 7 | Speaker JST + gasket | `folder_test` again | Clean audio, no pops between clips |
| 8 | RTC coin cell (see §3.2) | Full app; unplug 30 s; replug | Time survives, no "power was lost" in the log |
| 9 | Everything closed up | Full app, overnight soak | `[hb]` heartbeats every 60 s, heap flat |

**Check step 1 with a multimeter before any module is plugged in.** A reversed
rail will kill the ESP32, the RTC and the DFPlayer in one go, and it is the one
mistake that cannot be undone.

Then confirm the joystick orientation and, if needed, flip `kInvertX`/`kInvertY`
in `src/Buttons.cpp` - see the end of [`WIRING.md`](WIRING.md).

---

## 6. The sled

### Retention

Magnets in the sled's rear corners, plain **steel washers** recessed into the
body behind them. Using washers rather than a second set of magnets halves the
parts and makes it impossible to get polarity wrong - a mistake that is
unfixable once the magnets are glued in.

Pockets are modelled `magnet_fit` (0.05 mm) undersize per side for a press fit,
with `magnet_wall` (0.8 mm) of material left over the top so they stay hidden.
If a pocket prints loose, a drop of cyanoacrylate is fine - but push the magnet
in **before** the glue grabs, because a magnet stuck half-in is not coming out.

Two 6 x 3 mm N42 discs give a firm hold with a deliberate tug. Start with two;
add the second pair only if it feels loose, because too much holding force makes
the clock lift off the table when you pull the sled.

### Guiding

Two things stop a sliding fit from being annoying:

- **Rails.** A `sled_rail_w` x `sled_rail_h` rib along each side of the cavity,
  with matching grooves in the sled. Without them the sled can rack diagonally
  and jam halfway.
- **A lead-in chamfer.** `sled_lead_cham` (1.5 mm) on the sled's leading edges so
  it self-centres instead of needing to be lined up by eye.

Clearance is `sled_slide_gap` (0.35 mm) **per side**. Print a 20 mm test stub of
the cavity and the sled nose first and check the fit before committing to an
8-hour print of the body.

Add a finger notch (`sled_finger_w` x `sled_finger_h`) to the sled face, or the
magnets will hold better than your fingernails can pull.

### Screw threads

If you fit the optional locking screws, use **M3 heat-set brass inserts**
(`insert_d`, `insert_z`), not self-tapping screws into bare plastic. Self-tapped
threads in PLA survive perhaps five or six cycles before stripping, and this is
a part designed to come apart repeatedly.

---

## 7. Speaker and the head

```
     ear grille   ear grille
         ░░           ░░       <- 13 holes each, in the stippled inner-ear dish
          \           /
        ┌──────────────┐
        │     head     │   <- front chamber (ellipsoid void, hollow)
        │   (hollow)   │
        └──────┬───────┘
          ═════╪═════       <- neck chimney (48 x 34), airtight
        ┌──────┴───────┐
        │  speaker on  │
        │   cage top   │   <- cage interior = sealed rear volume
        └──────────────┘
```

- Speaker mounts to the **top** of the cage, firing up, held by four M3 screws or
  a printed retaining ring.
- The stadium opening (`spk_grille_l` x `spk_grille_w`) in the cage top, with the
  gasket compressed between flange and roof.
- Sound then runs **cage top -> neck chimney -> hollow head -> ears**. The grille
  is *not* on the face: it is cut into the sculpted **stippled inner dish of each
  ear** (13 holes, 2.4 mm, hex 4/5/4, on the dish's own major axis), fed by a
  shallow plenum under the skin and three ducts into the head void. See
  `panda_head_vents()` / `ear_vent()` in `panda.scad` and
  `previews/panda_ear_grille.png`. Open areas are matched (grille 58.8 mm^2 per
  ear vs ~54.6 mm^2 of duct throat).
- `helpers.scad`'s generic `speaker_grille()` is unused - the ear grille is
  solved against the sculpt's own geometry instead.
- Keep the head cavity as sealed as practical. Every unintended gap is bass
  leaking out.
- Do not let the speaker's magnet sit against the DS3231 or the OLED ribbon.

---

## 8. Port access

| Port | Where | Why |
| --- | --- | --- |
| USB-C | Slot in the body's rear, aligned with the sled's ESP32 | Reflash and power without removing the sled |
| microSD | Reachable with the sled out | Rarely changed; not worth a body cutout |
| Amp vents | Slots low on the body's back | The DFPlayer's amp runs warm in a sealed box |

Make the USB-C opening `esp_usb_w`/`esp_usb_h` plus `fit_gap`, and **oversize it
generously** - a couple of mm of slop is invisible from the front and saves a
reprint when the sled sits 1 mm deeper than modelled. Remember the plug body is
much larger than the receptacle: leave a shallow recess around the slot, or a
chunky cable's moulding will hold the sled out by a millimetre or two.

`esp_usb_out` is how far the receptacle overhangs the PCB edge, which sets how
far back the ESP32 has to sit so the connector lands flush with the body wall.

### Choose the wall charger with care (USB-C specific)

Many CP2102 dev boards with a USB-C socket **omit the two 5.1 kohm CC pull-down
resistors**. A proper USB-C source will then never enable its output, and the
board simply stays dead on a C-to-C cable while working perfectly on A-to-C.

Yours currently runs from a Mac, so if that is over a C-to-C cable the resistors
are present and any charger will do. If it is A-to-C, **test your intended wall
charger and cable before the enclosure is closed** - discovering this with the
sled glued in is miserable. The workaround is an A-to-C cable, or soldering the
two resistors from CC1 and CC2 to ground.

### Strain relief on the USB lead

The USB-C socket is soldered to the ESP32 PCB with small surface-mount pads, and
it is the only thing tethering the clock. A yank on the cable tears the socket
off the board - this is the most likely way to kill the finished clock. Add a
printed clamp or a zip tie anchored to the body, so any pull lands on the
enclosure and not on the connector.

---

## 9. Cable routing inside the sled

- Leave a **service loop**: enough slack that the sled roof lifts off and lies
  beside the base without anything under tension.
- Heat-shrink over every solder joint, including the speaker terminals.
- Anchor bundles with adhesive tie-downs or printed loops so nothing rests on
  the DFPlayer's SD slot or the joystick's moving gimbal.
- Nothing should touch the joystick body - it must be free to tilt its full
  `joy_throw_a` (25 deg).

---

## 10. Final checks before it goes on the bedside table

1. Overnight soak; confirm `[hb]` heartbeats every 60 s and free heap flat
   (`soak/soak_logger.py` does this and writes a log).
2. Pull the USB for 30 s, replug: time must survive and the log must **not** say
   "RTC power was lost".
3. Volume at maximum: no buzz, no rattle, no pop between clips.
4. Set a quiet-hours window that starts in two minutes; confirm announcements
   stop, and that a stick-left tap still speaks.
5. Slide the sled out and in ten times; nothing snags, nothing loosens.
6. Set the DST region and confirm the displayed time does not move.

---

## 11. Still to model in OpenSCAD

The current concept files are massing models - shapes only. Before anything is
printable, the chosen concept needs:

- [ ] The sled: base, roof, front panel, rails, magnet pockets, insert bosses
- [ ] The body cavity that receives it, with matching rails and washer recesses
- [ ] Joystick panel hole, **flared** to `joy_throw_a` so the stick can tilt
- [ ] OLED window and mounting bosses (`oled_hole_dx`/`dy` exist already)
- [ ] Speaker opening in the cage top (done) + the ear grilles (done: see
      `ear_vent()` in `panda.scad`); `helpers.scad`'s `speaker_grille()` is unused
- [ ] Screw bosses - `helpers.scad` has `screw_boss()`, also never called
- [ ] USB slot and amp vents
- [ ] Print-splitting and orientation

Dimensions for all of the above are now in `dimensions.scad`. Before the final
export, work through [`MEASUREMENTS.md`](MEASUREMENTS.md) with calipers and
replace the `[verify]` values with your actual parts - clones vary by a couple of
mm, which is the difference between a snug fit and a reprint.
