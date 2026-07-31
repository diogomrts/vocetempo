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
// Units: millimetres. Coordinate convention used by the concepts:
//   +X right, +Y up (away from viewer / toward the panda's back is -Y),
//   +Z up (vertical). The panda sits on the Z=0 ground plane.
// ============================================================================

// ---- OLED: Hailege 2.42" SSD1309, I2C -------------------------------------
oled_pcb_w      = 72;     // PCB width  (X)  [verify]
oled_pcb_h      = 40;     // PCB height (Y)  [verify]
oled_pcb_t      = 1.4;    // PCB thickness
oled_glass_w    = 65;     // glass panel width [verify]
oled_glass_h    = 37;     // glass panel height [verify]
oled_active_w   = 55.0;   // visible/active area width  (2.42" diag)
oled_active_h   = 37.0;   // visible/active area height (approx, 128x64)
oled_active_dx  = 0;      // active-area centre offset from PCB centre, X
oled_active_dy  = 2;      // active-area centre offset from PCB centre, Y [verify]
oled_hole_dx    = 66;     // mounting-hole horizontal spacing [verify]
oled_hole_dy    = 34;     // mounting-hole vertical spacing   [verify]
oled_hole_d     = 3.0;    // mounting-hole diameter (M2.5/M3)

// ---- ESP32 DevKit (DollaTek 30-pin) ---------------------------------------
esp_w           = 52;     // board length (X) [verify]
esp_h           = 28.5;   // board width  (Y) [verify]
esp_t           = 1.6;    // PCB thickness (ignoring pin headers below)
esp_usb_w       = 9;      // micro-USB connector width (for the access port)
esp_usb_h       = 4;      // micro-USB connector height
esp_pin_drop    = 10;     // clearance needed below the board for header pins

// ---- DS3231 RTC module ----------------------------------------------------
rtc_w           = 38;     // [verify - "mini" boards are ~38x22, others differ]
rtc_h           = 22;
rtc_t           = 1.6;
rtc_batt_d      = 20.5;   // CR2032 holder diameter (reach for replacement)

// ---- DFPlayer Mini (audio) - SD slot must stay reachable ------------------
dfp_w           = 21.6;   // module length (X)
dfp_h           = 20.2;   // module width  (Y)
dfp_t           = 1.6;
dfp_sd_w        = 12;     // microSD card width  (the slot mouth)
dfp_sd_h        = 1.6;    // microSD card thickness (slot height)
dfp_sd_insert   = 15;     // how far the card + finger clearance sticks past slot

// ---- Speaker (CQRobot 3W 4ohm) --------------------------------------------
spk_d           = 40;     // outer diameter [verify - some are 28/36/40/50]
spk_t           = 6;      // body depth
spk_grille_d    = 34;     // sound opening diameter (grille hole pattern spans)

// ---- Buttons (4x through-panel tactile, on caps) --------------------------
btn_cap_d       = 8;      // button cap / plunger diameter
btn_spacing     = 16;     // centre-to-centre if placed in a row

// ---- Perfboard base the modules mount to ----------------------------------
perf_w          = 70;     // [choose your protoboard; verify]
perf_h          = 50;
perf_t          = 1.6;
perf_hole_pitch = 2.54;   // standard 0.1" grid

// ---- Print / fit parameters -----------------------------------------------
wall            = 2.4;    // shell wall thickness (good on a 0.4mm nozzle)
fit_gap         = 0.4;    // clearance around parts and in cutouts
screw_boss_d    = 6;      // outer diameter of an M3 screw boss
screw_hole_d    = 2.9;    // M3 self-tap pilot hole
corner_r        = 4;      // general rounding radius for a friendly look

// ---- Rendering smoothness (higher = smoother, slower) ---------------------
$fn = 48;
