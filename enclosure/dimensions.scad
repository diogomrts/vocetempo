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
// 4 mounting holes: a RECTANGLE, not the "near-square" previously recorded.
// CORRECTED 2026-08-24: 19.85 across the PCB's 26.70 width and 26.0 along its
// 32.30 length. The old joy_hole_dy of 19.80 was almost certainly the gimbal
// body's 19.80 width read as a hole pitch - the same class of mistake that made
// the first printed cage miss the joystick holes. Margins now reconcile with the
// board: (26.70 - 19.85)/2 = 3.4 and (32.30 - 26.0)/2 = 3.15 to each edge.
joy_hole_dx     = 19.85;  // c-to-c across the PCB width, 26.70 axis [measured]
joy_hole_dy     = 26.0;   // c-to-c along the PCB length, 32.30 axis [measured]
joy_hole_d      = 3.20;   // M3 clearance [measured]
// 5-pin header: leaves at a SHORT edge, extending the 32.30 length to ~37.5mm
// overall. The pins rise ~5mm off the component face and are BENT to run
// parallel to the board, so they are not aligned with the gimbal body. Mounted
// sideways on the cage the bent row sticks out past one side of the PCB, into
// the rump - panda_joystick_cut() carves a dedicated clearance step for it
// (symmetric, so the module can be fitted pins-left or pins-right).
joy_pin_ext     = 5.2;    // past the PCB edge along the long axis (37.5 total) [measured]
joy_pin_raise   = 6.0;    // bent row ~5mm above the PCB face + pin thickness [measured]
joy_pin_row     = 12.7;   // 5 pins x 2.54, centred on the edge

// Kept for reference in case push buttons are ever fitted alongside the stick.
btn_cap_d       = 8;      // button cap / plunger diameter
btn_spacing     = 16;     // centre-to-centre if placed in a row

// ---- Mounting: NO perfboard --------------------------------------------------
// Decided: no protoboard. Each module screws directly to PRINTED STANDOFFS on
// the cage, wired point-to-point. Standoffs must lift each board clear of its
// bottom-side pins (see esp_pin_drop etc). Attachment uses each module's own
// measured hole pattern:
//   OLED     Ø2.5  @ 64.3 x 43.0   (4 corners)
//   Joystick Ø3.2  @ 19.85 x 26.0  (4 corners, rectangle, offset to pins)
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
// NOTE: the cage's outer dimensions are defined HERE, above the base-flange
// block, because flange_xw / front_yf / back_yb / mag_ear_root are computed FROM
// them. They used to live ~30 lines further down, which made all four evaluate to
// undef (OpenSCAD does not forward-reference) and silently fed garbage into
// base_flange_2d() - so the cage's base flange, the panda's base rebate and the
// magnet ears were all being built from undef. Keep this order.
// The cage: front face (OLED) faces the belly; slides in from the BASE; joystick
// bolted to the OUTSIDE of the back wall; speaker on top fires up the neck into the
// head cavity.
//
// !!! RE-FIT 2026-08-21: 200mm HOST !!!  Every number in this block was re-solved
// against panda/panda_original_without_embosses.stl at panda_h 200 (enclosure/
// REFIT.md; re-derive with refit.py / fit_shell.py). At 160mm the layout was
// deadlocked - the belly pinched in above the folded arms at panda Z72, capping
// cage_h at 64, while a portrait ESP32 needs 61.2mm of interior and 77.2mm with a
// straight USB-C plug. Growing the host is what breaks the deadlock: the boards do
// not scale, so every clearance is bought back at once.
cage_w          = 75;     // outer width  (X) - OLED 68.63 + walls/clearance
// HEIGHT. 80 gives 78mm of interior: cover ledge 6 + 2 margin + a straight USB-C
// plug 16 + the 53.2mm ESP32 standing portrait = 77.2, with 0.8 to spare. So the
// panel-mount USB-C port is optional again rather than mandatory. The top can go
// this high because the front no longer has to be one plane - see shell_prof's
// fourth column.
cage_h          = 80;     // outer height (Z) -> top at panda Z87
// DEPTH (Y): the panda torso is ROUND, so a deep rectangular cage pokes its
// front/back CORNERS out through the belly and shoulders. 88 is a solved trade, not
// a guess: deeper shortens the joystick's cap stalk (it leaves 25.9mm of rump at
// dev_joy_pz) but eats the base rim the magnets need. At cage_d 100 the rump is
// 13.9mm but the hatch reaches within ~5mm of the skin front AND back, so there is
// nowhere left to put a magnet. The corner relief that makes 88 fit is in
// shell_prof (below) - and on this host cb is 0 at every height, so the back wall
// is full width for the first time.
cage_d          = 88;     // outer depth  (Y)
// The base is domed: at panda Z2 the belly skin at X0 is only Y40.3 and by |X|34 it
// has tucked back to Y28.7, while at Z7 it is Y50.4 / Y63.3. So the cage cannot
// start any lower - at Z2 its front wall would be 14mm outside the sculpt.
cage_z0         = 7;      // cage base sits at this panda Z

rim_h           = magnet_t + 1.2;   // flange thickness: magnet depth + backing (4.2)
side_rim        = 3;      // flange's outward rim on the SIDES
front_pull      = 3;      // pull the FRONT edge IN (see below)
back_rim        = 4;      // flange's outward rim at the BACK (into the rump)
back_xw         = 32;     // back edge half-width (the rump narrows toward the sides)
flange_xw       = cage_w/2 + side_rim;       // SIDE reach (40.5)
// THE FRONT RIM IS NOW A PULL, NOT A REACH. Over the flange's own Z band (panda
// Z7..11.2) the belly skin bottoms out at Y44.38 around |X|27, so a rim carried
// forward to panda Y49 - what front_rim 4 used to give - pokes out of the belly
// across |X|15..27 (measured). Pulling the edge 3mm inside the cage wall puts it at
// panda Y42 with 2.4mm to spare. The front loses its seat; the sides and the back
// (where the rump gives 10mm+) still carry the flange onto the rebate ceiling.
front_yf        = -(cage_d/2 - front_pull);  // FRONT edge, cage -Y (-41 = panda Y42)
back_yb         = cage_d/2 + back_rim;       // BACK reach (48 = panda Y-47)
mag_ear_r       = magnet_d/2 + 2.0;          // 4.5 - ear radius round a pocket
// The magnets HAVE to sit outboard of the base hatch, which is now 77 x 90 and
// spans panda Y -44..46: everything inside that is cut away for the cage. Positions
// are in the CAGE frame; panda = (-cx, cage_yc - cy). Both pairs are raycast-
// verified solid over panda Z11.2..15.7 (the body pocket) with >=4mm of body all
// round, AND their flange ears verified inside the skin over panda Z7.2..11.2:
//   front pair  cage (+-38, -49)  ->  panda (+-38,  50)  over the feet
//   side  pair  cage (+-44, -16)  ->  panda (+-44,  17)  over the side collar
// (the old front pair at panda Y50, |X|34 fails on this host: at panda Z7 the foot's
// inner edge is at |X|~28 and the skin there is only Y52.4, so the pocket's outboard
// halo breaks out.)
mag_pos         = [[ 38, -49], [-38, -49],   // front pair (over the panda's feet)
                   [ 44, -16], [-44, -16]];  // side pair  (over the side collar)
// where each ear meets the flange proper (clamped to the cage's own footprint)
mag_ear_root    = [[ 38, front_yf], [-38, front_yf],
                   [ cage_w/2, -16], [-cage_w/2, -16]];
// Steel-washer fallback kept in case the pair approach is dropped later.
washer_d        = 12;     // steel washer outer diameter [unused]
washer_t        = 1.2;    // [unused]

// ---- BASE COVER (was missing entirely) ---------------------------------------
// The cage's base is the hatch it enters through, so it is open by design - but
// nothing ever closed it afterwards. On the first print that leaves the electronics
// looking straight at the table, with no dust seal, nothing stopping a board from
// dropping out, and the panda's whole underside an open box.
//
// The cover is a separate plate that screws to the UNDERSIDE of the base flange,
// occupying panda Z0..cage_z0 - i.e. exactly the gap between the flange and the
// ground - so it finishes flush with the panda's base and adds no height. It is the
// last thing fitted and the first thing removed for service.
//
// AT cage_z0 7 IT IS NO LONGER A FLAT PLATE. The sculpt's base is domed: its lowest
// points are the outer edges of the feet at |X|~40 (panda Z0.5) and at X0 the body
// does not start until Z~1.5, while the silhouette at Z2 has already tucked back to
// Y40.3 at X0 and Y28.7 at |X|34. A 7mm prism of the cage's footprint would stand up
// to 14mm proud of the belly at the bottom rear of the feet. So base_cover() is
// INTERSECTED with the sculpt itself (cage.scad), which makes its outer surface the
// panda's own base - flush by construction. Print it flat-face-down, dome up.
cover_t         = cage_z0;      // fills the flange-to-ground gap exactly
cover_inset     = 0.3;          // shrink from the outline so it is never proud
cover_finger_w  = 18;           // notch to get a fingernail under it
// HOW IT IS HELD. Not on bosses: the flange's middle is cut away (it must not block
// the hatch), so a post standing anywhere in the base footprint would be floating in
// mid-air, fused to nothing. Instead a LEDGE is run round the inside of the shell
// walls at the very bottom - fused to the wall along its whole length, printable
// with no overhang, and stiffening the open base as a bonus. The cover screws up
// into it from below.
cover_ledge_w   = 5.0;          // how far the ledge reaches in from the wall
cover_ledge_h   = 6.0;          // its height above the cage's Z0
// Screw positions must all land ON that ledge at EVERY height it spans (cage Z0..6),
// not just at the top. On this host cb is 0 everywhere, so the back wall is finally
// full width and the back pair can move out to |X|25 (it used to be pinned inboard
// of |X|22 by a 15.5mm base chamfer). The FRONT pair is the fussy one: shell_prof's
// fyb pulls the front face back 2.22mm at cage Z0 and 0.22 at Z2, so the front
// ledge's outer edge walks from y-39.78 at Z0 to y-42 at Z4. -38.5 is the only band
// that is on the ledge over the whole 0..6 run.
cover_screws    = [[ 33,   0  ], [-33,   0  ],  // side ledges
                   [ 25, -38.5], [-25, -38.5],  // front ledge
                   [ 25,  40  ], [-25,  40  ]]; // back ledge (full width now)
// microSD access: the DFPlayer's card edge faces the base, so the cover needs a
// slot under it. Sized to the card plus finger room, not just the card.
cover_sd_w      = 16;
cover_sd_l      = 20;

// ---- USB-C charge exit (shared by the cage AND the panda) ---------------------
// Lives here, not in cage.scad, because BOTH parts have to cut it and they were
// out of sync: the cage had the slot, the panda had NO hole at all, so the cable
// vented into ~15.5mm of solid rump. The ESP32's USB-C faces DOWN toward the open
// base; the cable turns in the board-to-wall gap and exits low on the BACK wall,
// below the joystick. Sized to a PANEL-MOUNT USB-C flange so a fixed port can be
// retrofitted later without a redesign; for now a loose cable threads it.
// THE SLOT HAS TO LINE UP WITH THE RECEPTACLE. The ESP32's USB-C mouth sits at
// cage Z = esp_cz - esp_w/2 - esp_usb_out; the slot must be centred on it or a cable
// plugged in facing DOWN has to double back on itself to reach the exit.
// On the 200mm host the cage is 80 tall, so for the first time the board can sit
// high enough to leave a STRAIGHT plug's 16mm of moulding hanging below it: with
// esp_cz 50 the mouth is at cage Z21.9 and the plug body ends at ~Z6, right on top
// of the cover ledge. So the slot goes at Z22 and the panel-mount port it is sized
// for is now an option, not a requirement. A right-angle cable still works.
usb_slot_z      = 22;     // cage Z (panda Z29) = the ESP32's USB-C mouth
usb_slot_x      = -19.3;  // cage X, on the back wall's left half (clear of the
                          // DFPlayer at +18 and the joystick's |X|<=16.15)
usb_flange_w    = 20;     // panel-mount flange footprint
usb_flange_h    = 12;
usb_screw_dx    = 24;     // future panel-mount screw spacing

// ---- Panda host model & cage placement ---------------------------------------
// HOST: panda/panda_original_without_embosses.stl - the sculpt with the embossed
// screen plaque and belly knob shaved off - scaled to 200mm tall.
//
// The transform is DERIVED from the mesh, not hand-fitted (probe_skin.scad_transform
// / refit.py section 1). The old recipe hard-coded scale 166.7 and translate +26 in
// Y, both fitted by eye to panda_original.stl; they do not transfer, because the
// de-embossed mesh is 2% shorter and 7% shallower in Y (raw Z span 0.93937 vs
// 0.95893) and its X is symmetric where the old mesh was 0.44mm off-centre.
// Deriving it means the next sculpt swap only changes these two numbers.
//
// Resulting frame: X centred, feet on Z0, belly at +Y, Y bounding box centred on 0.
//   bbox  X -72.35..72.35   Y -69.08..69.08   Z 0..200
panda_scale     = 212.9096; // = 200 / 0.93937 raw Z span
panda_h         = 200;      // final height (Z)
panda_x_off     = 0;        // this mesh is symmetric (derived value 0.006)
panda_y_off     = 9.036;    // panda_raw() translate; was a hand-fitted 26
panda_w         = 145;      // approx overall width at the base
// WHY 200 AND NOT 160. The parts do not scale - a 2.42" OLED is 68.63 x 46.60 at
// any host size - so the sculpt's size IS the clearance budget. At 160 the belly
// pinched in above the folded arms at panda Z72, which capped cage_h at 64 against
// the 61.2mm a portrait ESP32 needs, put its USB-C mouth level with the cover ledge
// (no straight plug possible) and left the joystick's cap stalk longer than the
// rump. Every one of those is solved at 200; scale_sweep.py has the table.
//
// The cage front (belly) face lands at this PANDA Y. It is a real plate at Y45
// through the whole board zone, and only steps BACK above the arms - see shell_prof's
// fyb column, which is what decoupled cage height from screen depth.
// PLACEMENT: cage.scad's own frame has the OLED front at -Y, so in the panda the
// cage is ROTATED 180 about Z, then translated:
//     translate([0, cage_yc, cage_z0]) rotate([0,0,180]) cage();
// After the 180 spin, the cage front (-D/2) maps to +D/2, i.e. panda Y cage_yfront.
cage_yfront     = 45;     // panda Y of the cage FRONT (belly) outer face
cage_yc         = cage_yfront - cage_d/2;   // panda Y of the cage centre (= 1)
// The cross-section shape (which corners are chamfered, and by how much, per
// height) is defined by shell_prof further down - a single source of truth shared
// by cage.scad (the box) and panda.scad (the cavity).

// ---- Cavity clearances (panda.scad builds the void, cage.scad clips to it) -----
// These live HERE rather than in panda.scad because cage.scad needs them too and
// `use <panda.scad>` imports modules, not variables - so cage_clip_z was silently
// undef the moment it tried to derive itself from the body's clip line.
cav_clear     = 1.0;      // slide-in gap on the SIDES/BACK (easy insertion)
cav_front_gap = 0.35;     // MUCH tighter on the BELLY-FRONT face, so the wall over
                          // the screen stays thick. A uniform 1.0 inflates the
                          // cavity into the belly skin at the arm-fold -> pin-holes.
cav_fyb       = cav_clear - cav_front_gap;   // front-face bias (0.65)
cav_min       = 1.4;      // min belly wall the skin clip guarantees at the arm-fold
cav_clip_z    = 71;       // panda Z above which the cavity (and the cage's upper
                          // shell) are clipped to an inward-eroded skin. 71 = cage
                          // Z64, exactly where shell_prof's fyb column starts
                          // pulling the front back for the arms. It used to be far
                          // lower, but the front plate now runs at panda Y45 with as
                          // little as 1.9mm of belly over it at Z69, and the erosion
                          // is 1.35mm - clipping any lower would start shaving the
                          // wall the OLED's own bosses stand on.
skin_cy       = -5;       // body Y axis the skin is scaled toward (measured: the
                          // torso's mid-Y runs -6.2 at Z60 to -10.2 at Z87)
skin_r        = 60;       // belly radius from that axis at the pinch (measured
                          // 57-60 over panda Z62..70)

// ---- SINGLE SOURCE OF TRUTH for device placement (panda Z + cage Z) ----------
// Mapping rule: cage-internal Z + cage_z0 = panda Z. Both panda.scad and cage.scad
// derive their cuts from these, so they can never drift apart again.
//
// THE BELLY CARRIES ONLY THE SCREEN; THE JOYSTICK IS ON THE RUMP. They cannot
// share the front wall - the OLED alone is 46.6 tall and the KY-023 adds another
// 26.7 plus clearance, which never fitted in any front wall this sculpt offers.
// The rump has no competition: 25.9mm of solid body between the cage's back face
// and the skin at dev_joy_pz.
dev_oled_pz     = 47.8;   // OLED lit-window centre, PANDA Z
                          // -> oled_cz 37.7, PCB spans cage Z14.4..61.0,
                          //    bosses at cage Z16.2 and 59.2, both on flat wall
                          //    (fit_shell.py: cf is 0 through cage Z0..42 and only
                          //    1.5-1.8 at Z44/46, so |X|32.15 is never in a chamfer)
dev_joy_pz      = 50;     // joystick centre, PANDA Z, on the RUMP.
                          // The rump is 25.7mm deep here and still 26.1 at its
                          // deepest (Z40); 50 keeps the assembly clear of the USB-C
                          // exit slot (cage Z16..28) and the DFPlayer below it.
// Cage-frame centres (derived; used by cage.scad):
//   window centre (lit area) = dev_oled_pz - cage_z0
//   OLED PCB centre         = window centre - oled_active_dy  (lit sits +3.1 up)
oled_cz         = dev_oled_pz - cage_z0 - oled_active_dy;  // OLED PCB centre (cage Z)
joy_cz          = dev_joy_pz  - cage_z0;                   // joystick centre (cage Z)

// ---- Joystick: STANDOFFS ON THE OUTER FACE OF THE BACK WALL ------------------
// !!! CHANGED with the 200mm re-fit. It used to drop into a pocket in a thickened
// plinth on the INSIDE of the back wall, with the gimbal poking out through a bore
// and a separate printed FRAME screwed over the PCB's edges - because the module's
// own 4 holes (19.85 x 26.0) sit right on the gimbal bore's edge on the 19.85 axis
// (the gimbal is 19.80 wide there), so a boss there loses over half its section.
//
// Turn the module round and the conflict disappears. Bolt the PCB to standoffs on
// the OUTSIDE of the back wall with the gimbal pointing AWAY from it, and there is
// no bore at all - nothing has to pass through the wall except five wires. That
// deletes joystick_plinth(), joystick_pocket_cut(), joystick_bore_cut(),
// joystick_frame_bosses() and the whole joy_frame printed part, and it uses the
// module's own mounting holes as intended.
//
// SIDEWAYS still: the PCB is rotated 90deg, so 32.30 runs across X and 26.70 up Z,
// and the hole pattern becomes 26.0 (X) x 19.85 (Z) - standoffs at X+-13.0,
// Z joy_cz +- 9.925. Fit the gimbal with its WIDE (23.40, nub) axis across X; the
// bent header row then points out past one side of the PCB (either side works,
// the rump channel clears both).
//
// The price is depth. Measured out from the cage's back OUTER face at panda Y-43:
//     2.00  standoff
//     0.92  PCB
//    11.76  gimbal body
//   =14.68mm proud, so the rump needs a taller/wider INSERTION CHANNEL than before
//   (it has to pass the 32.3mm PCB, not the 24mm gimbal). See panda.scad.
joy_so_h        = 2.0;    // standoff height off the back wall's OUTER face
joy_wire_w      = 16;     // wire slot through the back wall, below the PCB
joy_wire_h      = 5;
// THE CAP. Stock rubber cap is 26mm and would need a ~32mm hole in the rump; we
// print a slim one (joy_slim_cap_d). Its socket is deeper than the 5.95mm shaft, so
// it bottoms on the gimbal's shoulder. PCB inner face at panda Y-45, so the shoulder
// is at -45 - 0.92 - 11.76 = -57.68, and the rump skin at dev_joy_pz is Y-68.71.
joy_cap_stalk   = 11.0;   // gimbal shoulder -> rump skin (68.71 - 57.68 = 11.03)
joy_cap_dome    = 3.5;    // dome standing proud of the rump (thumb finds it)
joy_cap_barrel_d = 8.6;   // at the socket (socket 4.3 + 2 x cap_wall)
joy_cap_tip_d    = 6.5;   // tapered down where it passes through the skin
// The rump bore only has to clear the STALK plus its swing, NOT the 16mm dome - so
// the dome overhangs the hole like a real thumbstick and hides its edge. The pivot
// sits ~6mm out from the PCB (panda Y-51.9), so the lever to the skin is 16.8mm and
// at joy_use_tilt the tip sweeps 16.8 x tan(11) = 3.26mm each way.
//   6.5 tip + 2 x 3.26 + slack = 14.0, comfortably under the 16mm dome.
joy_rump_bore_d = 14.0;

// Body-only relief v2 (2026-10-07): another 3mm beyond the first revision,
// including the PCB/header shoulders and bare-shaft groove. The left side,
// looking directly at the panda's back, also gets a broad deep recess.
// The printed cage, cap bore and mounting positions remain the same.
joy_channel_extra_depth  = 6.0;
joy_channel_extra_height = 10.0;
joy_channel_shoulder_gap = 4.5;
joy_channel_roof_r       = 3.0;
joy_channel_shaft_gap    = 3.8; // accommodates 3mm extra PCB spacing + 0.8mm gap
// Left recess setback above the working area: [panda Z, depth pulled inward].
// The rear skin narrows with height; this smooth slope keeps about 1mm of skin
// above the entrance instead of breaking through the upper-left rump.
joy_channel_left_profile = [[-1, 0], [55, 0], [60, 0.6],
                            [65, 1.3], [70, 2.1], [72.35, 2.6]];

// ---- Print / fit parameters -----------------------------------------------
wall            = 2.4;    // shell wall thickness (good on a 0.4mm nozzle)
fit_gap         = 0.4;    // clearance around parts and in cutouts
screw_boss_d    = 6;      // outer diameter of a self-tap screw boss
screw_hole_d    = 2.5;    // M3 self-tap pilot hole (boss bites the screw; no insert)
// A Ø2.5 pilot is sized for M3 self-tappers, which suit every hole that PASSES an
// M3: the joystick (Ø3.2), the speaker ears (Ø3.2), the retention bars and the
// base cover (Ø3.2 clearance). It does NOT suit the OLED (holes Ø2.5) or the RTC
// (Ø2.3): an M3 does not fit through those, and an M2 that does fit through has a
// 2.0mm thread OD, so it cannot bite a 2.5 pilot at all - the screw just spins.
// Those two modules take M2 self-tappers into this smaller pilot instead.
screw_hole_d_m2 = 1.7;    // M2 self-tap pilot (OLED + RTC bosses only)
// NOTE: using self-tapping screws into printed bosses - NO heat-set inserts.
// Shopping list: M3 self-tappers (joystick x4 = M3x4 MAX, see joy_pilot_web;
// speaker x4; cover x6; bars x4) and M2 self-tappers (OLED x4, RTC x3).
corner_r        = 4;      // general rounding radius for a friendly look

// ---- Shell cross-section profile (the "loaf" that fits the round panda) -------
// The cage OUTER cross-section is a W x D rectangle whose FRONT and BACK corners
// are chamfered by amounts that vary with height, and whose FRONT FACE can be set
// back per height. This is the single source of truth for the shell shape; BOTH
// cage.scad (the box) and panda.scad (the cavity that must contain it) build from
// it, so they cannot drift.
//
// Each row is [z, cf, cb, fyb] in the CAGE frame (front = -Y):
//   cf   FRONT (belly) corner chamfer
//   cb   BACK corner chamfer
//   fyb  FRONT SETBACK - pulls the whole belly-side face back at that height
//
// WHY THE FOURTH COLUMN EXISTS. Without it the front is a single plane, so it has
// to clear the WORST height anywhere on the cage - and the worst height is the arm
// pinch at the very top. That couples cage height to screen depth directly: a cage
// tall enough for the ESP32 (top at panda Z87) drags the front plane back to Y29.6
// and buries the screen ~31mm deep, while a cage short enough to keep the front at
// Y45 cannot fit the ESP32 at all. That is precisely the deadlock that stopped the
// re-fit landing. With a setback the front plate stays FORWARD at the full Y45
// through the OLED's whole span and steps back only above the arms.
//
// SOLVED, NOT GUESSED. The table is printed by fit_shell.solve_setback(), which
// rasterises the raw sculpt and, per height, (1) pulls the flat span |x| <= 35.5
// back by however much the OLED's 68.63mm PCB and its |X|32.15 bosses demand, then
// (2) chamfers only the feature-free corners beyond it. Everything must stay
// `margin` (1.6mm) inside the skin. Re-run it after changing cage_w, cage_d,
// cage_yfront, cage_z0 or cage_h - all five feed the solve:
//     python refit.py
//
// Key results on the 200mm host:
//   * cb is 0 AT EVERY HEIGHT. The back wall is full width for the first time, so
//     the joystick, the DFPlayer and the USB exit share an uncramped 71mm.
//   * the front plate holds Y45 from cage Z4 to Z42, which is where the OLED lives.
//   * cf only ever reaches 1.9 (the paw crests at cage Z44/46 and the shoulders at
//     Z74+), so no mounting boss is ever left standing in a chamfer.
//   * fyb ramps from 0.86 at cage Z64 to 16.57 at the top - that is the folded arms.
//   * row 0's fyb 2.22 is the base: at panda Z7 the belly has only reached Y44.4
//     around |X|27.
// Rows between 4 and 42 and between 48 and 62 are all zeros; the loft is linear, so
// collapsing them changes nothing.
shell_prof = [
  // z      cf      cb     fyb
  [  0.0,   0.00,   0.00,   2.22],   // base fillet
  [  2.0,   0.00,   0.00,   0.22],   // solver says 0; held at 0.22 so the step out
                                     // of the base fillet is exactly 45deg, not 48
  [  4.0,   0.00,   0.00,   0.00],
  [ 42.0,   0.00,   0.00,   0.00],   // ---- front plate at full Y45 ----
  [ 44.0,   1.52,   0.00,   0.00],   // paw crests clip the corners
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

// ---- Rendering smoothness (higher = smoother, slower) ---------------------
$fn = 48;
