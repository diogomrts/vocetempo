// ============================================================================
// Vocetempo enclosure - shared component dimensions.
//
// These are the real-world sizes of every part that has to fit in (or show
// through) the enclosure. EVERY concept file includes this one, so we only
// ever edit measurements in a single place.
//
// !!! IMPORTANT !!!
// The values below are NOMINAL (typical datasheet / "as sold" numbers). Before
// exporting a FINAL printable case, measure YOUR actual boards with calipers
// and update them here - clones vary by a couple of mm, which is the
// difference between a snug case and one that doesn't close. For picking a
// concept shape, nominal values are fine.
//
// docs/MEASUREMENTS.md is a fill-in checklist covering every value marked
// [verify] below, including how to measure the awkward ones (hole centres, the
// OLED's lit area, the joystick's tilt angle).
//
// Units: millimetres. Coordinate convention used by the concepts:
//   +X right, +Y up (away from viewer / toward the panda's back is -Y),
//   +Z up (vertical). The panda sits on the Z=0 ground plane.
// ============================================================================

// ---- OLED: Hailege 2.42" SSD1309, I2C -------------------------------------
// MEASURED 2026-08-04. The old nominals were well off: the real board is 3.4mm
// narrower and 6.6mm TALLER than assumed (72x40 -> 68.63x46.60), which would
// have made any case built on the old numbers unusable.
oled_pcb_w      = 68.63;  // PCB width  (X)  [measured]
oled_pcb_h      = 46.60;  // PCB height (Y)  [measured]
oled_pcb_t      = 0.98;   // PCB thickness   [measured] (thin 1.0mm board)
oled_glass_w    = 62.30;  // glass panel width  [measured]
oled_glass_h    = 39.90;  // glass panel height [measured] at its widest; there
                          // is a ~1mm slope/notch at the bottom middle
// Active area derived from the 2.42" diagonal at the panel's 2:1 aspect
// (128x64 square pixels): 61.47mm diagonal -> 54.98 x 27.49.
// The previous oled_active_h of 37.0 was geometrically impossible.
// Confirm both against the lit rectangle with `pio run -e oled_test`.
// Confirmed with oled_test (all pixels on) against the lit rectangle. Height 28
// finally buries the old impossible 37.0. Edge-to-lit gaps: L=R=7.35 (centred
// in X); top=6.2, bottom=12.6 -> lit sits 3.1mm ABOVE the PCB centre (toward the
// top edge, away from the bottom pin header). The window must NOT be centred.
oled_active_w   = 55.0;   // lit area width  [measured]
oled_active_h   = 28.0;   // lit area height [measured]
oled_active_dx  = 0;      // X offset from PCB centre (horizontally centred) [measured]
oled_active_dy  = 3.1;    // Y offset from PCB centre, +Y toward top edge [measured]
// Mounting holes: 4, one at each corner of a plain rectangular PCB, ~1mm from
// the edges. Spacing derived from edge->hole readings cross-checked against the
// board size; both reconcile with a sane wall thickness (0.9mm H, 0.55mm V).
oled_hole_dx    = 64.3;   // hole horizontal centre-to-centre [measured]
oled_hole_dy    = 43.0;   // hole vertical   centre-to-centre [measured]
oled_hole_d     = 2.5;    // mounting-hole diameter (M2 clearance) [measured]

// Depth behind the glass front face, which sets how deep the panel recess must
// be. The header adds 6.3mm; cutting it down or fitting a right-angle one would
// save that much sled depth.
oled_depth_bare = 6.23;   // glass front -> back of PCB          [measured]
oled_depth_hdr  = 12.55;  // glass front -> back of soldered header [measured]

// ---- THE BELLY WINDOW: the full lit area, and what it costs ----------------
// DECISION (user): every one of the 128x64 pixels must be visible. So the window
// is the whole lit area + fit_gap, 55.4 x 28.4, and the folded paws that stand in
// front of it are simply CUT THROUGH. That is a deliberate trade, not an oversight
// - the alternatives were measured and all cost more (see below).
//
// WHAT GETS CUT. The paws' inboard edges reach X-19.6 at Z51 while the window needs
// 27.7, so the cut takes 8.1mm off each paw, over Z42..58, leaving a flat vertical
// face on the inboard side of each. The arms therefore end abruptly at the screen
// rather than reading as folded. Nothing else on the body is touched.
//
// THE CORNER RADIUS is the one real knob, and it does NOT affect the paw cut at all
// (8.10mm at Z50.5 for every radius, because that height is in the window's
// full-width span). It only trades CORNER PIXELS against the FEET, whose inner
// edges come to |X| 24.7 at Z32. Measured:
//     r      lit px hidden   corner icons   bite into the feet
//     2.0        4 / 8192    both survive   2.1mm at Z32..35
//     4.0       48           both clipped   1.1mm
//     6.0      120           both clipped   0.04mm
//     8.0      236           both clipped   none        <- what this used to be
// r = 2.0 is chosen because the requirement is all pixels visible: it hides 4 of
// 8192 (the single extreme pixel in each corner) and keeps the quiet-hours and mute
// icons, which sit in the top corners, on screen. The price is a ~2mm nick out of
// each foot's top-inner corner - next to an 8.1mm paw cut, it does not show.
//
// WHAT WAS REJECTED, all built and measured:
//  * Sizing the window to the sculpt's own embossed screen plaque (36 x 21mm, its
//    raised frame becoming the bezel). Geometrically perfect - nothing trimmed or
//    deformed, rim on flat plaque to +-0.15mm - but it only exposes an 84 x 48
//    safe area of the panel, so a third of the pixels are hidden. Rejected.
//  * Countersinking the window (oled_bevel_*): left two flat "wings" beside the
//    screen ending in a hard crescent line.
//  * A rolling-ball paw trim (arm_trim()): rolled the sculpted paw tip into a
//    spherical dome and planed its crest.
//  * Swinging the arms outboard in Blender first (panda_arms.py). This DID free the
//    paws and keep them fully rounded, and it cleared this exact window with a
//    1.3..2.1mm bezel. But there are only 2.6mm of surface between the paw's
//    underside (Z42) and the top of the feet (Z39.4), so the swing's taper either
//    tore a serrated ridge across the belly or sheared the leg tops into POINTY
//    TIPS; the best of ~30 swept configurations still rotated the legs 13mm and
//    visibly widened the stance, and left only 1.3mm of bezel on the -X side (the
//    sculpt's paws are not symmetric). A biharmonic solve was 20x worse still,
//    because the sculpt's triangulation is far too irregular for a Laplacian
//    method. Rejected as costing more than the paw cut it was avoiding.
//  * A smaller 1.54" 128x64 panel (~35 x 17.5mm active) would fit the plaque
//    entirely - all pixels, panda untouched, no firmware change - but needs a
//    different module, a new cage OLED mount, and gives a much smaller clock.
//    Worth revisiting if the sliced paws ever grate.
oled_win_w      = 55.4;   // = oled_active_w + fit_gap; full lit width
oled_win_h      = 28.4;   // = oled_active_h + fit_gap; full lit height
oled_win_r      = 2.0;    // corner radius; see the table above before changing

// ---- ESP32 DevKit (DollaTek 30-pin) ---------------------------------------
esp_w           = 53.20;  // board length (X) [measured]
esp_h           = 28.40;  // board width  (Y) [measured]
esp_t           = 1.45;   // PCB thickness (ignoring pin headers below) [measured]
esp_top_h       = 4.63;   // tallest point above the top face (chip/can; USB-C
                          // shell is the same height) - sets sled clearance [measured]
esp_usb_w       = 8.80;   // USB-C receptacle shell width [measured]
esp_usb_h       = 3.10;   // USB-C port opening height for the wall cutout [measured]
esp_usb_out     = 1.5;    // how far the receptacle sticks out past the PCB edge [measured]
// CHARGING ROUTING (decided): ESP32 mounts USB-C-DOWN; the cable curves ~90deg
// in the board-to-wall gap and exits a SLOT LOW ON THE BACK WALL (not the base,
// which faces the table). The slot is sized to a PANEL-MOUNT USB-C flange so a
// fixed back port can be retrofitted later without a redesign; for now a loose
// cable threads it. See usb_exit_cut in cage.scad.
esp_pin_drop    = 10;     // clearance needed below the board for header pins

// ---- DS3231 RTC module (ZS-042, DS3231SN + AT24C32) -----------------------
rtc_w           = 38;     // board length (X) [confirmed ~nominal]
rtc_h           = 22;     // board width  (Y) [confirmed ~nominal]
rtc_t           = 1.58;   // PCB thickness [measured]
rtc_batt_d      = 21.63;  // CR2032 holder diameter [measured]
rtc_batt_z      = 7.80;   // holder height above PCB (swap clearance) [measured]
// 3 mounting holes (NOT 4). Positions below are the ZS-042 layout read FROM THE
// PHOTO, origin = bottom-left corner, board 38(X) x 22(Y), header on the right
// short edge. Confidence ~+-1.5mm (small board, slight angle) - acceptable ONLY
// because bosses take self-tapping screws (forgiving) not heat-set inserts.
// CONFIRM with calipers before final print if the fit is tight.
rtc_hole_d      = 2.30;   // mounting-hole diameter [measured]
rtc_hole1_x     = 30.0;   // top hole, by header    [from photo]
rtc_hole1_y     = 17.0;
rtc_hole2_x     = 30.0;   // bottom hole, by header [from photo]
rtc_hole2_y     = 4.0;
rtc_hole3_x     = 4.0;    // lone hole, far end     [from photo]
rtc_hole3_y     = 11.0;

// ---- DFPlayer Mini (audio) - SD slot must stay reachable ------------------
dfp_w           = 20.70;  // module length (X) [measured]
dfp_h           = 20.20;  // module width  (Y) [measured]
dfp_t           = 2.00;   // PCB thickness [measured]
dfp_top_h       = 4.96;   // tallest part above PCB [measured]
// SD slot and pin headers exit the SAME edge - keep that edge accessible.
dfp_sd_w        = 11.20;  // microSD slot mouth width [measured]
dfp_sd_h        = 0.86;   // microSD slot mouth height (card thickness) [measured]
dfp_sd_insert   = 15;     // card + finger clearance past slot [verify with card in]

// ---- Speaker: ENCLOSED boxed speaker with 4 mounting ears -----------------
// NOT a bare round driver (old spk_d/spk_t were for a 40mm driver - wrong part).
// Rectangular plastic box, ears extend on the LENGTH axis only.
//
// MOUNTING (decided): bolts to the TOP of the electronics sled/cage, grille
// facing UP so it fires into the panda's HEAD chamber. The head acts as the
// resonating port; sound vents out the face (mouth/nostrils or hidden chin
// grille). This keeps ALL wiring on the sled - nothing crosses the sled/body
// boundary. Requires: (a) an open neck/throat from the sled top into the head
// (opening >= the grille), and (b) vent holes in the head so sound escapes.
spk_box_l       = 51.25;  // main body length, excluding ears [measured]
spk_box_w       = 30.90;  // main body width [measured]
spk_overall_l   = 69.50;  // tab-tip to tab-tip (length axis) [measured]
spk_h           = 16.38;  // total box depth (grille face -> back) [measured]
spk_grille_l    = 37.35;  // grille opening, long axis (stadium shape) [measured]
spk_grille_w    = 26.80;  // grille opening, short axis (semicircular ends) [measured]
spk_ear_hole_d  = 3.20;   // mounting-ear hole diameter (M3) [measured]
spk_ear_dx      = 63.60;  // ear hole spacing, long axis (60.4 n-to-n + 3.2 d) [measured]
spk_ear_dy      = 21.20;  // ear hole spacing, short axis [measured]

// ---- Joystick: KY-023 analog thumbstick (replaces the 4 buttons) ----------
// Clones vary more than most modules here, so measure yours. The stick needs
// clearance to TILT, not just to pass through - hence a cone/chamfer on the
// panel hole rather than a straight bore (joy_throw_a is the half-angle).
joy_pcb_w       = 26.70;  // PCB width  (X) [measured]
joy_pcb_h       = 32.30;  // PCB height (Y) [measured]
joy_pcb_t       = 0.92;   // thin PCB [measured]
// The gimbal base is NOT square: 19.8 one way, 23.40 the other (a plastic nub
// protrudes on one side). The sled pocket must clear the wider 23.40.
joy_body_w      = 19.80;  // black gimbal body, narrow axis [measured]
joy_body_w2     = 23.40;  // black gimbal body, wide axis (has protruding nub) [measured]
joy_body_h      = 11.76;  // gimbal body height above the PCB [measured]
// The widest part is a 26mm round flange ~12mm up, and the thumb cap on top is
// also ~26mm. So everything above the 12mm flange sweeps at 26mm dia - THIS is
// what the panel cone must clear, not the narrow stick.
joy_flange_d    = 26.0;   // widest round flange diameter [measured]
joy_flange_z    = 12.0;   // flange height above the PCB [measured]
joy_cap_d       = 26.0;   // thumb cap diameter [measured]
joy_cap_z       = 29.43;  // height of cap top above the PCB [measured]
// Cap top (z=29.43) sweeps ~12.5mm sideways at full tilt -> atan(12.5/29.43)
// = ~23 deg half-angle. NOTE: the panel cone must clear the 26mm flange at
// z=12 at this tilt, not just the cap - compute the opening from both.
joy_throw_a     = 23;     // stick tilt half-angle [measured, ~12.5mm cap sweep]
// DECISION: the stock 26mm cap forces a ~32mm panel opening (nearly screen-sized
// and ugly). We PRINT A SLIM REPLACEMENT CAP instead. Used as a d-pad, the stick
// only needs ~11 deg of travel, so a small cap + tiny swing is plenty.
joy_slim_cap_d  = 16.0;   // printed replacement thumb-cap diameter
joy_use_tilt    = 11;     // effective tilt clearance in the panel (d-pad use)
joy_panel_open  = 20.0;   // resulting panel opening dia (slim cap + swing + clr)
// Stock shaft under the rubber cap: an OVAL/double-flat post (a ~4mm cylinder with
// two flats bringing it to 3mm across the flats). The printed cap's socket matches
// this so it press-fits AND keys against rotation. [MEASURED: 3.0 x 4.0 x 5.95 tall]
joy_shaft_w     = 3.0;    // shaft, across the flats  [measured]
joy_shaft_d     = 4.0;    // shaft, across the round  [measured]
joy_shaft_len   = 5.95;   // shaft length above the gimbal (socket depth) [measured]
// 4 mounting holes forming a near-square, offset toward the pin-header edge (so
// they look uneven per-corner but are a clean rectangle). Confirmed by caliper.
joy_hole_dx     = 19.85;  // horizontal centre-to-centre [measured]
joy_hole_dy     = 19.80;  // vertical   centre-to-centre [measured]
joy_hole_d      = 3.20;   // M3 clearance [measured]

// Kept for reference in case push buttons are ever fitted alongside the stick.
btn_cap_d       = 8;      // button cap / plunger diameter
btn_spacing     = 16;     // centre-to-centre if placed in a row

// ---- Mounting: NO perfboard --------------------------------------------------
// Decided: no protoboard. Each module screws directly to PRINTED STANDOFFS on
// the cage, wired point-to-point. Standoffs must lift each board clear of its
// bottom-side pins (see esp_pin_drop etc). Attachment uses each module's own
// measured hole pattern:
//   OLED     Ø2.5  @ 64.3 x 43.0   (4 corners)
//   Joystick Ø3.2  @ 19.85 x 19.8  (4, near-square, offset to pins)
//   RTC      Ø2.3  x3 holes        (2 by pins, 1 top corner)
//   Speaker  Ø3.2  @ 63.6 x 21.2   (4 ears, on sled TOP, grille up)
//   DFPlayer NO usable holes (one half-slot on top edge, opposite the SD slot)
//            -> printed snap-in clip/cradle, same as ESP32
//   ESP32    NO holes -> printed snap-in cradle (pocket 53.2 x 28.4 + tabs)

// ---- Slide-out electronics cage ----------------------------------------------
// All electronics live on a cage that slides into the body, so the panda never
// has to be opened. See docs/ASSEMBLY.md.
sled_wall       = 2.0;    // cage wall thickness
sled_slide_gap  = 0.35;   // clearance per side in the cavity (per side, not total)
sled_rail_w     = 3.0;    // guide rail width, stops the sled racking as it goes in
sled_rail_h     = 2.0;    // guide rail height
sled_lead_cham  = 1.5;    // chamfer on the sled's leading edges, to self-centre
sled_finger_w   = 20;     // finger notch width on the sled face, for pulling out
sled_finger_h   = 6;

// ---- Magnets (cage retention) ------------------------------------------------
// Decided: MAGNET PAIRS (cage + body), mounted in OPEN (through) pockets so the
// two faces TOUCH metal-to-metal (no hidden plastic wall). This matters a lot:
// with a hidden wall a Ø5x3 pair holds ~0.4N in shear; touching, it's ~2N each.
// 4 magnets -> ~8N vs the ~2N cage weight = ~4x margin, enough to hold the cage
// against gravity when the panda is lifted (base-hatch insertion).
//
// RULES: (1) pocket depth = magnet_t EXACTLY so the face sits flush and the pair
// meets with zero gap; (2) glue with CA (friction alone lets neodymium creep
// out); (3) CHECK POLARITY before gluing each one - offer to its partner, let it
// attract, mark that face, glue it that way. A reversed magnet repels & won't
// seat. (4) Place near the 4 corners of the base rim to resist twist/rock.
magnet_d        = 5.0;    // disc diameter [measured]
magnet_t        = 3.0;    // disc thickness [measured]
magnet_fit      = 0.05;   // pocket undersize per side for a press fit (glue too)
magnet_count    = 4;      // one near each corner of the base rim

// ---- Base flange + where the magnet PAIRS actually meet -----------------------
// The flange is the cage's foot: it seats in a REBATE counterbored into the panda's
// base (panda_base_rebate()), and the pairs meet on the flange's TOP face - cage
// magnet flush in the flange looking up, body magnet flush in the rebate ceiling
// looking down, so the two faces touch with no plastic between them.
//
// The magnets HAVE to sit outboard of the base hatch: the hatch (|X|<=40.5,
// Y -23..43 in panda coords) removes the body exactly where the old positions were,
// so they had nothing to attract. Raycast of the base at the rebate ceiling (Z 6..9)
// shows the solid ring outside the hatch is (a) a wide FRONT band at Y>=44 - the
// cavity's front face stops at Y 40.35 and the feet run out to Y 62 - and (b) SIDE
// bands at |X|>=42. The rump is useless: its skin is at Y -22..-26, so the hatch
// already reaches it.
// Positions below are in the CAGE frame; panda = (-cx, cage_yc - cy). Both pairs are
// verified inside the skin from Z2 (the flange's underside) upward, with >=1.5mm of
// wall around every pocket:
//   front pair  cage (+-34, -40)  ->  panda (+-34, 50)  over the feet
//   side  pair  cage (+-43, -16)  ->  panda (+-43, 26)  over the side collar
// (a side pair at panda |X|44 was tried first and fails: still outside the skin at
// Z2, because the base tapers in toward the floor.)
// NOTE: the cage's outer dimensions are defined HERE, above the base-flange
// block, because flange_xw / front_yf / back_yb / mag_ear_root are computed FROM
// them. They used to live ~30 lines further down, which made all four evaluate to
// undef (OpenSCAD does not forward-reference) and silently fed garbage into
// base_flange_2d() - so the cage's base flange, the panda's base rebate and the
// magnet ears were all being built from undef. Keep this order.
// The cage: front face (OLED over joystick) faces the belly; slides in from the
// BASE; speaker on top fires up the neck into the head cavity (~Z128+).
cage_w          = 75;     // outer width  (X) - OLED 68.63 + walls/clearance
cage_h          = 78;     // outer height (Z) - OLED & joystick centres 28mm apart
                          //   (devices overlap in Z at different depths to fit
                          //   the panda belly); OLED top ~62 + speaker margin
// DEPTH (Y): the panda torso is ROUND, so a deep rectangular cage pokes its
// front/back CORNERS out through the belly and shoulders (the old cage_d=80 with
// square-ish corners breached the skin at nearly every Z - confirmed by the
// breach fit-check). The mesh was re-analysed this session (raw skin -> per-Z
// angular radius map): the usable window is front belly ~Y44 at the corners, back
// ~Y-16, ~75 wide, necking in toward the top where the arms fold. Depth only needs
// ~45mm internally (front stack ~19 + back stack ~21 + wiring), so 60mm outer is
// roomy AND fits the round torso. The corner relief that makes it fit is captured
// in shell_prof (below) - a per-height chamfer that keeps the walls FLAT where the
// boards mount and only trims the feature-free corners.
cage_d          = 60;     // outer depth  (Y) - was 80 (corners breached the belly)
cage_z0         = 2;      // cage base sits at this Z (just above the feet lip)

rim_h           = magnet_t + 1.2;   // flange thickness: magnet depth + backing (4.2)
front_rim       = 4;      // flange's outward rim at the FRONT (over the feet)
side_rim        = 3;      // ... and on the SIDES
back_pull       = 8;      // pull the BACK edge IN (the rump recedes at the base)
back_xw         = 24;     // back edge half-width (the rump narrows)
flange_xw       = cage_w/2 + side_rim;       // SIDE reach (40.5)
front_yf        = -(cage_d/2 + front_rim);   // FRONT reach, cage -Y (-34)
back_yb         = cage_d/2 - back_pull;      // BACK edge, pulled IN (22)
mag_ear_r       = magnet_d/2 + 2.0;          // 4.5 - ear radius round a pocket
mag_pos         = [[ 34, -40], [-34, -40],   // front pair (over the panda's feet)
                   [ 43, -16], [-43, -16]];  // side pair  (over the side collar)
// where each ear meets the flange proper (clamped to the cage's own footprint)
mag_ear_root    = [[ 34, -cage_d/2], [-34, -cage_d/2],
                   [ cage_w/2, -16], [-cage_w/2, -16]];
// Steel-washer fallback kept in case the pair approach is dropped later.
washer_d        = 12;     // steel washer outer diameter [unused]
washer_t        = 1.2;    // [unused]

// ---- Panda host model & cage placement ---------------------------------------
// Source mesh: Downloads/a87ed6a5-...stl, in normalized units (0.70 x 0.70 x
// 0.96). We rescale to 16cm tall (factor ~166.7) and hollow it, then boolean the
// screen/joystick/speaker openings. Sliced cross-sections (scaled to 16cm):
//   Z~15  (base)  ~115 wide    <- widest, feet
//   Z~48  (belly) ~106 wide    <- cage front face lives here
//   Z~80  (waist) ~92  wide    <- TIGHT POINT: 75 cage + ~8.5mm body each side
//   Z~112 (chest) ~103 wide
//   Z~128+(head)  depth pinches -> HEAD CAVITY (speaker resonator) starts here
panda_scale     = 166.7;  // normalized-units -> mm, gives ~160mm tall
panda_h         = 160;    // final height (Z) [target]
panda_w         = 115;    // approx overall width at the base
// The cage front (belly) face lands at this PANDA Y. Belly surface over the window
// is Y~64-67 at centre but only ~48-50 at the corners; the rounded front face sits
// just inside it, leaving a thin belly wall the window pierces (a shallow recessed
// screen). Cage back then lands at Y-16, clear of the folded arms.
// PLACEMENT: cage.scad's own frame has the OLED front at -Y, so in the panda the
// cage is ROTATED 180 about Z, then translated:
//     translate([0, cage_yc, cage_z0]) rotate([0,0,180]) cage();
// After the 180 spin, the cage front (-D/2) maps to +D/2, i.e. panda Y cage_yfront.
cage_yfront     = 40;     // panda Y of the cage FRONT (belly) outer face
                          // (was 42; pulled back 2mm to thicken the thin belly wall
                          //  above the screen - it had pin-holed at the arm-fold
                          //  crease. Screen recess deepens ~2mm, still shallow.)
cage_yc         = cage_yfront - cage_d/2;   // panda Y of the cage centre (= 12)
// The cross-section shape (which corners are chamfered, and by how much, per
// height) is defined by shell_prof further down - a single source of truth shared
// by cage.scad (the box) and panda.scad (the cavity).

// ---- SINGLE SOURCE OF TRUTH for device placement (panda Z + cage Z) ----------
// The panda sculpt was MESH-ANALYSED this session (orthographic front render with
// 2mm Z markers + depth-deviation map): the embossed screen plaque centres at
// panda Z~40 and the round belly knob at panda Z~20, only ~20mm apart. But the
// OLED lit window is 28mm tall and the slim-cap joystick opening ~26mm (20mm panel
// + tilt flare), so the two PANEL OPENINGS need ~32mm centre-to-centre to leave a
// solid ~3mm wall BRIDGE between them - they CANNOT both sit dead-centre on the
// sculpt. DECISION (user): spread them symmetrically about the feature midpoint
// (panda Z30) -> OLED window at panda Z46, joystick at panda Z14. Each opening
// still lands on its sculpted feature (drifts ~2mm); the belly around them is plain
// so the small offset reads fine. [Was 44/16 = 28mm, which left NO bridge: the
// joystick cone top and OLED window bottom overlapped at the centreline and the
// front wall was cut clean through. Verified with a front-wall slab section.]
//
// Mapping rule: cage-internal Z + cage_z0 = panda Z. Both panda.scad and cage.scad
// derive their cuts from these, so they can never drift apart again.
dev_oled_pz     = 46;     // OLED lit-window centre, PANDA Z [on the screen plaque]
dev_joy_pz      = 20;     // joystick opening centre, PANDA Z [on the round knob]
dev_sep         = dev_oled_pz - dev_joy_pz;   // = 26 (opening centre spacing)
// Cage-frame centres (derived; used by cage.scad):
//   window centre (lit area) = dev_oled_pz - cage_z0
//   OLED PCB centre          = window centre - oled_active_dy  (lit sits +3.1 up)
//   joystick centre          = dev_joy_pz - cage_z0
oled_cz         = dev_oled_pz - cage_z0 - oled_active_dy;  // OLED PCB centre (cage Z)
joy_cz          = dev_joy_pz  - cage_z0;                   // joystick centre (cage Z)

// ---- Print / fit parameters -----------------------------------------------
wall            = 2.4;    // shell wall thickness (good on a 0.4mm nozzle)
fit_gap         = 0.4;    // clearance around parts and in cutouts
screw_boss_d    = 6;      // outer diameter of a self-tap screw boss
screw_hole_d    = 2.5;    // self-tap pilot hole (boss bites the screw; no insert)
// NOTE: using self-tapping screws into printed bosses - NO heat-set inserts.
corner_r        = 4;      // general rounding radius for a friendly look

// ---- Shell cross-section profile (the "loaf" that fits the round panda) -------
// The cage OUTER cross-section is a W x D rectangle whose FRONT and BACK corners
// are chamfered by amounts that vary with height. This is the single source of
// truth for the shell shape; BOTH cage.scad (the box) and panda.scad (the cavity
// that must contain it) build from it, so they cannot drift.
//
// WHY: the panda torso is round AND its folded arms pinch the upper-BACK (worst
// around cage Z70-74, easing again by the top where the speaker sits). A plain
// box pokes its corners through the skin; a simple taper moves the walls away
// from the board-mounting bosses (they ended up floating outside - the bug this
// fixes). So the profile keeps FLAT, FULL walls through the whole board zone
// (Z12..~60, where OLED/joystick/ESP/RTC/DFPlayer mount) and only chamfers the
// corners where there are NO features: the feet (low front) and the shoulders/
// arms (high front & back). Each [z, front_chamfer, back_chamfer] row is in the
// cage frame (front = -Y). Values were solved against a per-Z angular map of the
// raw panda skin so every point clears the surface (breach fit-check: ~1mm skin
// at the tightest point). Speaker ears (near the Y centre) stay inside the top.
// cf = FRONT (belly) corner chamfer, cb = BACK corner chamfer.
// The folded arms pinch the BELLY (front, +Y) at Z~64-76, so the big chamfer is on
// the FRONT now; the back only needs a little (shoulders) plus a small chamfer at
// the base for the splayed feet/rump. Both cf and cb are monotonic non-decreasing
// toward the top so the corners never flare back OUT (that flare is what made the
// pointy tabs). Solved against the correctly-oriented belly skin (breach fit-check).
shell_prof = [
  // z    cf    cb
  [ 0,    0,   13],   // base: rump/feet recede at the back -> back chamfer
  [ 4,    0,    9],
  [ 8,    0,    3],
  [12,    0,    0],   // ---- full flat box through the board zone ----
  [60,    0,    0],
  [62,    8,    1],   // OLED top standoffs ~here; small chamfer (clip trims edges)
  [63,   15,    2],   // belly pinches sharply above the OLED -> FRONT chamfer HARD
  [64,   20,    3],
  [65,   22,    4],
  [66,   24,    5],
  [67,   24,    6],
  [68,   25,    8],
  [70,   25,   10],   // belly/arm pinch worst -> deepest FRONT chamfer, then HELD
  [72,   25,   12],
  [74,   25,   13],
  [76,   25,   13],
  [78,   25,   13],
];

// ---- Rendering smoothness (higher = smoother, slower) ---------------------
$fn = 48;
