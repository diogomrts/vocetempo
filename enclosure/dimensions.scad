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
// The cage: front face (OLED over joystick) faces the belly; slides in from the
// BASE; speaker on top fires up the neck into the head cavity (~Z128+).
cage_w          = 75;     // outer width  (X) - OLED 68.63 + walls/clearance
cage_h          = 78;     // outer height (Z) - OLED & joystick centres 28mm apart
                          //   (devices overlap in Z at different depths to fit
                          //   the panda belly); OLED top ~62 + speaker margin
// DEPTH (Y): the panda belly BULGES ~86mm forward of the body centre. A shallow
// cage would leave the OLED at the bottom of a deep dark tunnel. So the cage is
// DEEP: its front face (OLED/joystick) sits just behind the belly surface while the
// back wall (ESP32/RTC/DFPlayer) sits near the torso's rear. The torso has room
// (~95-107mm deep through the cage region). [Integration fit-check, this session.]
cage_d          = 80;     // outer depth  (Y) - reaches the belly (was 38; tunnel)
cage_z0         = 2;      // cage base sits at this Z (just above the feet lip)
// The cage front (belly) face lands at this PANDA Y. Belly surface over the window
// is Y~61..67; the front face sits ~7-13mm behind, leaving a belly wall the window
// pierces (a shallow recessed screen). Cage back then lands at Y-26 (front - depth),
// clear of the torso rear (~Y-28..-40).
// PLACEMENT: cage.scad's own frame has the OLED front at -Y, so in the panda the
// cage is ROTATED 180 about Z, then translated:
//     translate([0, cage_yc, cage_z0]) rotate([0,0,180]) cage();
// After the 180 spin, the cage front (-D/2) maps to +D/2, i.e. panda Y cage_yfront.
cage_yfront     = 54;     // panda Y of the cage FRONT (belly) outer face
cage_yc         = cage_yfront - cage_d/2;   // panda Y of the cage centre (= 14)

// ---- SINGLE SOURCE OF TRUTH for device placement (panda Z + cage Z) ----------
// The panda sculpt was MESH-ANALYSED this session (orthographic front render with
// 2mm Z markers + depth-deviation map): the embossed screen plaque centres at
// panda Z~40 and the round belly knob at panda Z~20, only ~20mm apart. But the
// OLED lit window is 28mm tall and the slim-cap joystick opening ~20mm, so the two
// PANEL OPENINGS need >=28mm centre-to-centre (for a ~4mm bridge) - they CANNOT
// both sit dead-centre on the sculpt. DECISION (user): spread them symmetrically
// about the feature midpoint (panda Z30) -> OLED window at panda Z44, joystick at
// panda Z16. Each opening still lands on its sculpted feature; belly around them
// is plain so the small offset reads fine.
//
// Mapping rule: cage-internal Z + cage_z0 = panda Z. Both panda.scad and cage.scad
// derive their cuts from these, so they can never drift apart again.
dev_oled_pz     = 44;     // OLED lit-window centre, PANDA Z [on the screen plaque]
dev_joy_pz      = 16;     // joystick opening centre, PANDA Z [on the knob]
dev_sep         = dev_oled_pz - dev_joy_pz;   // = 28 (opening centre spacing)
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

// ---- Rendering smoothness (higher = smoother, slower) ---------------------
$fn = 48;
