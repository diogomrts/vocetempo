// ============================================================================
// Wall layout MAP (debug/preview only, not a printed part).
//
// Unrolls the cage's four mounting walls side by side, each seen from INSIDE the
// cage looking outward, with every board footprint and boss to scale. This is the
// cheap collision check: run it before touching any mount in cage.scad.
//
// Replaces layout_backwall.scad, which (a) only drew the back wall, where nothing
// but the joystick lives any more, and (b) re-declared esp_cx / rtc_cz / dfp_cz by
// hand with the comment "kept in sync manually here" - which is precisely how a
// layout map ends up lying to you. This file INCLUDES cage.scad instead, so every
// number is the one the geometry is actually built from. `part` is forced to
// "none" so including it renders nothing of its own.
//
// Colours:
//   grey        usable wall boundary
//   steelblue   ESP32        seagreen  RTC        orange  DFPlayer
//   violet      joystick     yellow    OLED
//   red         boss centres (screw_boss_d)
// ============================================================================

include <cage.scad>
// NB this must come AFTER the include. OpenSCAD assignments are not sequential -
// the last one in a scope wins for the whole scope - and `include` is a textual
// inline, so cage.scad's own `part = "cage"` would otherwise override us and draw
// the whole cage on top of the map.
part = "none";

pad = 14;           // gap between the unrolled walls

module rect(cu, cv, su, sv) { translate([cu, cv]) square([su, sv], center = true); }
module boss(cu, cv) { translate([cu, cv]) circle(d = screw_boss_d); }
module frame(su, sv, cv) {
    color("lightgrey") difference() {
        translate([0, cv]) square([su, sv], center = true);
        translate([0, cv]) square([su - 1, sv - 1], center = true);
    }
}
module label(txt, cv) {
    color("black") translate([0, cv]) text(txt, size = 4, halign = "center");
}

// ---- FRONT wall (-Y): the OLED, alone ---------------------------------------
// Horizontal axis = cage X, vertical = cage Z.
translate([0, 0]) {
    frame(W - 2*t, H - t, (H + t)/2);
    label("FRONT (-Y): OLED", H + 6);
    color([1, 1, 0, 0.35]) rect(0, oled_cz, oled_pcb_w, oled_pcb_h);
    color([1, 0.7, 0, 0.5]) rect(oled_active_dx, oled_cz + oled_active_dy,
                                 oled_active_w, oled_active_h);
    color("red") for (sx=[-1,1], sz=[-1,1])
        boss(sx*oled_hole_dx/2, oled_cz + sz*oled_hole_dy/2);
}

// ---- BACK wall (+Y): the joystick + the USB exit ----------------------------
// The joystick is drawn here even though it lives on the wall's OUTER face - this
// map is about who competes for wall area, and it does: its four standoffs and its
// wire slot are cut into the same wall the DFPlayer and the USB exit use.
translate([W + pad, 0]) {
    frame(W - 2*t, H - t, (H + t)/2);
    label("BACK (+Y): joystick (outside) + USB", H + 6);
    // PCB (sideways: joy_pcb_h across X, joy_pcb_w up Z) + gimbal footprint
    color([0.6, 0.3, 0.8, 0.45]) rect(0, joy_cz, joy_pcb_h, joy_pcb_w);
    color([0.3, 0.1, 0.4, 0.6]) rect(0, joy_cz, joy_body_w2, joy_body_w);
    color("red") for (sx=[-1,1], sz=[-1,1])
        boss(sx*joy_hole_dy/2, joy_cz + sz*joy_hole_dx/2);
    // wire slot, just below the PCB's bottom edge
    color([0.4, 0.4, 0.4, 0.6])
        rect(0, joy_cz - joy_pcb_w/2 - 3, joy_wire_w, joy_wire_h);
    // USB exit slot + its future panel-mount bosses
    color([0.2, 0.6, 0.9, 0.5]) rect(usb_slot_x, usb_slot_z, usb_flange_w, usb_flange_h);
    color("red") for (s=[-1,1]) boss(usb_slot_x + s*usb_screw_dx/2, usb_slot_z);
    // DFPlayer, lower-right (20.2 across X, 20.7 up Z, SD edge at the bottom)
    color([1, 0.65, 0, 0.5]) rect(dfp_cx, dfp_cz, dfp_h, dfp_w);
    color("red") for (s=[-1,1]) boss(dfp_cx + s*dfp_span/2, dfp_cz);
}

// ---- SIDE walls: horizontal axis = cage Y, vertical = cage Z ----------------
// Left wall carries the ESP32; right wall the RTC and DFPlayer.
translate([2*(W + pad), 0]) {
    frame(D - 2*t, H - t, (H + t)/2);
    label("LEFT (-X): ESP32", H + 6);
    color([0.27, 0.51, 0.71, 0.5]) rect(esp_cy, esp_cz, esp_h, esp_w);
    color("red") for (s=[-1,1]) boss(esp_cy, esp_cz + s*(esp_w - 4)/2);
    // the base-cover ledge eats the bottom of every wall
    color([0.5, 0.5, 0.5, 0.35]) rect(0, cover_ledge_h/2, D - 2*t, cover_ledge_h);
}

translate([3*(W + pad), 0]) {
    frame(D - 2*t, H - t, (H + t)/2);
    label("RIGHT (+X): RTC", H + 6);
    color([0.24, 0.7, 0.44, 0.5]) rect(rtc_cy, rtc_cz, rtc_h, rtc_w);
    color("red") for (h = [[rtc_hole1_x, rtc_hole1_y],
                           [rtc_hole2_x, rtc_hole2_y],
                           [rtc_hole3_x, rtc_hole3_y]])
        boss(rtc_cy + (h[1] - rtc_h/2), rtc_cz + (h[0] - rtc_w/2));
    color([0.5, 0.5, 0.5, 0.35]) rect(0, cover_ledge_h/2, D - 2*t, cover_ledge_h);
}
