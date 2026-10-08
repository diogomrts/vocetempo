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

**4 magnet PAIRS** (Ø5 x 3 mm), pockets in printed plastic on both halves, press
fit + a drop of CA. They live on the cage's **base flange**, which drops into a
rebate counterbored into the panda's base (`panda_base_rebate()`); the pairs meet
on the flange's **top face**, cage magnet looking up and body magnet recessed into
the rebate's ceiling looking down, so the two faces touch with nothing between
them. That matters: with a plastic wall between them a Ø5x3 pair holds ~0.4 N in
shear, touching it is ~2 N, so 4 pairs give ~8 N against a ~2 N cage.

Positions are `mag_pos` in `dimensions.scad` - a front pair out over the feet and
a side pair over the base's side collar. They **must** sit outboard of the base
hatch: the hatch removes the body exactly where an earlier version put them, so
they had nothing to attract at all.

Pockets are modelled `magnet_fit` (0.05 mm) undersize per side for a press fit,
and bottom out on 1.2 mm of backing (`rim_h - magnet_t`) so a magnet cannot be
pushed through. If a pocket prints loose, CA is fine - but push the magnet in
**before** the glue grabs, because a magnet stuck half-in is not coming out.

**CHECK POLARITY on every pair before gluing.** Offer each magnet to its partner,
let it attract, mark that face, and glue it that way round. A reversed magnet
repels and will hold the cage off its seat.

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
  ear** (13 holes per ear, about 2.61 mm on the current 108.7% body,
  hex 4/5/4, on the dish's own major axis), fed by a
  shallow plenum under the skin and three ducts into the head void. See
  `panda_head_vents()` / `ear_vent()` in `panda.scad` and
  `previews/panda_ear_grille.png`. Open areas are matched (grille about 69.5 mm^2 per
  ear vs ~64.5 mm^2 of duct throat on the 108.7% body).
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
| microSD | Slot in the **base cover**, under the DFPlayer | Changeable without opening anything |
| Joystick | Bore in the body's rear, at panda Z50 | The one control; stalk cap presses in from outside |
| Amp vents | Slots low on the body's back | The DFPlayer's amp runs warm in a sealed box |

Make the USB-C opening `esp_usb_w`/`esp_usb_h` plus `fit_gap`, and **oversize it
generously** - a couple of mm of slop is invisible from the front and saves a
reprint when the sled sits 1 mm deeper than modelled. Remember the plug body is
much larger than the receptacle: leave a shallow recess around the slot, or a
chunky cable's moulding will hold the sled out by a millimetre or two.

### How the charge cable actually gets out - READ THIS BEFORE BUYING A CABLE

There is exactly **one** USB opening: a slot on the cage's **back wall** (cage Z22)
with a matching hole through the rump. The cable enters **horizontally from behind**,
at the height of the panda's lower back. It does **not** come out of the base - the
base would put the cable under the panda, where it gets pinched and where the panda
then will not sit flat.

The other opening in the base cover is the **microSD slot**, under the DFPlayer.
Different hole, different job.

The ESP32 is portrait on the left wall with its USB-C facing **down**, so its
receptacle mouth is at cage Z21.9 - and on the 200 mm host there are 21.9 mm below
it before the cover ledge. A **straight** USB-C plug's moulding is 15-20 mm long, so
for the first time it simply fits: the plug hangs down inside the cage and the cable
turns out through the slot. (At 160 mm the mouth was at cage Z6.5, on top of the
ledge, and a straight plug would have run out through the base cover into the table.)

Two upgrades are still worth considering:

1. **A right-angle USB-C cable.** The plug turns at the board edge and lies flat,
   pointing back at the slot. Buy one that exits toward the *back*, not the side.
   It is tidier than a straight plug and puts less leverage on the socket.
2. **A panel-mount USB-C breakout in the slot** (best). The slot is deliberately
   sized to `usb_flange_w`/`usb_flange_h` for exactly this, and two bosses are
   already there for its screws. A short internal lead reaches the ESP32, the
   external cable plugs into the panda's back, and the strain relief lands on the
   printed part instead of on the ESP32's surface-mount socket.

Option 2 also solves the strain-relief problem below, and means a stiff cable can
never lever the cage out of its magnets.

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
- Nothing should touch the joystick body - it must be free to tilt. Note the cage
  is built for `joy_use_tilt` (11 deg, plenty for d-pad use), **not** the stick's
  full `joy_throw_a` of 23: the printed cap and the rump bore are sized to 11.

---

## 9a. Fitting the joystick and closing the base

The joystick is on the **rump**, not the belly, and it bolts to the **OUTSIDE** of
the cage's back wall - so it goes on before the cage goes in. Order matters here:

1. Solder flying leads to the KY-023's 5-pin header. Unlike the old design you do
   **not** have to desolder or flatten it: the header faces outward into the rump,
   and the wires come back through a slot in the wall just below the board.
2. Bolt the PCB to the four **standoffs on the back wall's outer face**, through the
   module's own four holes (19.85 x 19.80). The gimbal points **away** from the
   wall, into the rump; fit it with the gimbal's wide (23.40 mm, nub) axis running
   **across X**, so the PCB's 32.30 mm dimension is horizontal. Four M3 self-tappers
   from the rump side; do not overtighten a 0.92 mm PCB.
3. Route the five leads through the wire slot under the board and into the cage.
4. **Do not fit the thumb cap yet.** It presses on from *outside* the panda, once
   the cage is in.
5. Slide the cage up into the body. The whole assembly stands **14.68 mm** proud of
   the cage's back face, far more than the base hatch clears, so it rides up the
   **insertion channel** moulded into the rump. The revised body also has a narrow
   groove for the bare shaft, which reaches another 5.95 mm beyond the gimbal.
   Keep the stick centred during insertion and use the orientation in step 2.
   The v2 body has the broad deep recess on the LEFT when looking at its back
   and allows 3 mm more PCB spacing than the nominal 2 mm stand-off.
   The older STL missed the shaft's travel and could catch even when oriented
   correctly; see the assembly-relief notes in `enclosure/README.md`.
   The v3 body also removes the catching lip between the feet and adds a 0.8 mm
   entrance lead-in. Higher corner shaping beside the paws is retained to avoid
   wall holes; the entrance check does not guarantee a friction-free full stroke.
6. For the **217.4 mm v8 body**, print and fit **`joy_cap_scaled_body`** through the
   unchanged rump bore. Its 20 mm stalk reaches the enlarged back; the older
   11 mm `joy_cap` is only for the 200 mm bodies. The keyed socket is unchanged.
   Print the 4 mm neck solid, test movement before gluing, then secure with a
   small drop of CA. The oval socket keys it against rotation; if it will not
   seat, rotate it 90 degrees. The new cap has been checked geometrically, not
   strength-tested as a physical print.
7. Thread the USB-C lead out of the **rear slot** and fit the printed **`cover`**
   over the base: 6 self-tappers up into the ledge inside the walls. The cover has
   a microSD slot under the DFPlayer and a finger notch at the front - check you
   can get a card in and out **before** you glue anything.

**Printing the cover.** It is no longer a flat plate: its outer surface is the
panda's own domed base, so it is ~7 mm thick at the rim and thinner in the middle.
Print it **flat face down** (the machined-looking side on the bed, dome upward) and
it needs no supports. Fitted, its lowest point clears the table by ~0.8 mm, so the
panda still stands on its own feet.

The v8 body **uniformly enlarges the whole original panda to 108.7%**, reduced
from v6's 115%. It measures **157.3 × 150.2 × 217.4 mm (W/D/H)**; print at **100%
slicer scale** so the cavity stays the same size. The cage, cover, mounting
positions and hardware cuts remain unchanged. The minimum modeled notch wall
above the flange seat is **1.019 mm**; going to 108.6% would leave less than 1 mm.
The round outer shape is preserved and the underside remains open for insertion.
Use the matching 20 mm cap from step 6. The known small higher front-corner snags
remain; the repaired entrance is clear in the model. V8 also opens a short internal
transition above the speaker so its full offset grille feeds the central chimney.
The printed cage and the v7 20 mm cap stay unchanged.

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

## 11. Modelling status

The enclosure is no longer a massing model - `cage.scad` and `panda.scad` export
printable geometry, and `enclosure/verify_cage.py` asserts the mounts are real.

Done:

- [x] **Host: the de-embossed sculpt at 200 mm**, with the import transform derived
      from the mesh instead of hand-fitted (`refit.py` re-derives everything)
- [x] Cage shell 75 x 80 x 88, base flange, magnet pockets; `shell_prof` **solved**
      against the sculpt including its per-height front setback (`fit_shell.py`
      computes it - do not hand-tune it)
- [x] OLED window + 4 mounting bosses, all on flat wall, screen 15.7 mm deep
- [x] Joystick on the rump: four standoffs on the back wall's **outer** face, stalk
      cap, stepped insertion channel through the body
- [x] ESP32 / RTC / DFPlayer mounts + retention bars; a **straight** USB-C plug now
      fits below the ESP32
- [x] Speaker throat, head resonator, neck chimney and ear grilles
- [x] Base hatch and rebate, **base cover** (clipped to the sculpt's domed base) and
      its ledge
- [x] USB-C exit - in the cage **and** in the body
- [x] `breach` fit-check renders empty; `verify_cage.py` and `verify_window.py` green

Open:

- [ ] The measurements in [`MEASUREMENTS.md`](MEASUREMENTS.md) section 9. The OLED
      header's position is the one that matters: it currently costs 5 mm of screen
      depth purely because nobody knows which edge it is on.
- [ ] **The screen sits ~16 mm behind the belly surface.** The belly skin over the
      window is at panda Y53.8 and the glass lands at Y37.2. The cage cannot simply
      move forward - past `cage_yfront` 46 the flat wall the OLED needs collapses
      (run `fit_shell.py --yfront 48` to see it). Options are a forward pedestal
      through the front wall, or relieving the header so the standoff drops to 2 mm.
- [ ] Print-splitting and orientation
- [ ] Amp vents

Dimensions for all of the above are now in `dimensions.scad`. Before the final
export, work through [`MEASUREMENTS.md`](MEASUREMENTS.md) with calipers and
replace the `[verify]` values with your actual parts - clones vary by a couple of
mm, which is the difference between a snug fit and a reprint.
