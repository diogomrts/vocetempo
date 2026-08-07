// ============================================================================
// Back-wall layout MAP (debug/preview only, not a printed part).
//
// Draws the cage back-wall interior flat, looking from -Y toward +Y, with each
// board's footprint and mounting bosses to scale, so collisions are obvious
// before retention bars are modelled. Colours:
//   grey   = back-wall interior boundary (W x H usable)
//   blue   = ESP32     footprint
//   green  = RTC       footprint
//   orange = DFPlayer  footprint
//   red    = boss centres (Ø screw_boss_d)
//   yellow = keep-out for the front-face devices (OLED/joystick) so back-wall
//            parts don't foul them where they overlap in Z
// ============================================================================

include <dimensions.scad>

// Pull the same layout numbers cage.scad uses (kept in sync manually here).
W = cage_w; H = cage_h; t = sled_wall;
IWmin = -W/2 + t;  IWmax = W/2 - t;   // usable X
IHmin = 0 + t;     IHmax = H;         // usable Z (open base at 0)

// --- board centres (mirror of cage.scad) ---
esp_cx = -W/2 + t + 2 + esp_h/2;   esp_cz = 66.8;              // portrait, high
rtc_cx = W/2 - t - 2 - rtc_w/2;    rtc_cz = H - 11 - rtc_h/2;
dfp_cx = W/2 - t - 1 - dfp_w/2;    dfp_cz = t + 4 + dfp_h/2;

module rect(cx, cz, sx, sz) {
    translate([cx, cz]) square([sx, sz], center=true);
}
bmargin = screw_boss_d/2 + 1;
function clampx(x) = max(-W/2+t+bmargin, min(W/2-t-bmargin, x));
function clampz(z) = max(t+bmargin, min(H-bmargin, z));
module boss(cx, cz) { translate([clampx(cx), clampz(cz)]) circle(d = screw_boss_d); }

// ---- draw ----
projection_scale = 1;

// usable boundary
color("lightgrey") difference() {
    translate([(IWmin+IWmax)/2, (IHmin+IHmax)/2])
        square([IWmax-IWmin, IHmax-IHmin], center=true);
    translate([(IWmin+IWmax)/2, (IHmin+IHmax)/2])
        square([IWmax-IWmin-1, IHmax-IHmin-1], center=true);
}

// ESP32 (portrait: esp_h wide in X, esp_w tall in Z)
color("steelblue") rect(esp_cx, esp_cz, esp_h, esp_w);
// ESP32 retention bosses (vertical span)
color("red") { boss(esp_cx, esp_cz - (esp_w+8)/2); boss(esp_cx, esp_cz + (esp_w+8)/2); }

// RTC (rtc_w x rtc_h) + its 3 real holes
color("mediumseagreen") rect(rtc_cx, rtc_cz, rtc_w, rtc_h);
color("red") {
    translate([rtc_cx + (rtc_hole1_x - rtc_w/2), rtc_cz + (rtc_hole1_y - rtc_h/2)]) circle(d=screw_boss_d);
    translate([rtc_cx + (rtc_hole2_x - rtc_w/2), rtc_cz + (rtc_hole2_y - rtc_h/2)]) circle(d=screw_boss_d);
    translate([rtc_cx + (rtc_hole3_x - rtc_w/2), rtc_cz + (rtc_hole3_y - rtc_h/2)]) circle(d=screw_boss_d);
}

// DFPlayer + horizontal retention bosses
color("orange") rect(dfp_cx, dfp_cz, dfp_w, dfp_h);
color("red") { boss(dfp_cx - (dfp_w+8)/2, dfp_cz); boss(dfp_cx + (dfp_w+8)/2, dfp_cz); }

// Front-device keep-outs (where they sit in X/Z, for reference)
top_margin=5; gap_devices=4;
oled_top=H-top_margin; oled_cz=oled_top-oled_pcb_h/2;
joy_top=oled_top-oled_pcb_h-gap_devices; joy_cz=joy_top-joy_pcb_h/2;
color([1,1,0,0.25]) rect(0, oled_cz, oled_pcb_w, oled_pcb_h);   // OLED PCB shadow
color([1,1,0,0.25]) rect(0, joy_cz, joy_pcb_w, joy_pcb_h);      // joystick PCB shadow
