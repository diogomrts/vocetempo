// ============================================================================
// Vocetempo - electronics CAGE.
//
// The real mechanical deliverable: a printable box that holds every module and
// slides into the hollowed panda FROM BELOW (base hatch). The panda mesh is
// hollowed and openings are cut to match this cage - the cage is designed
// first, the body adapts to it.
//
// Coordinate convention (matches dimensions.scad):
//   +X right,  +Y = toward the BACK wall (front face is at -Y, faces the belly),
//   +Z up.  Cage base rim sits on the local Z=0 plane here; in the panda it is
//   lifted to cage_z0.
//
// FRONT FACE  (-Y): OLED on top, joystick directly below it.
// TOP FACE    (+Z): speaker, grille up, firing into the head cavity.
// BACK WALL   (+Y): ESP32 (snap cradle), DFPlayer (clip), RTC (bosses).
// BASE        (-Z): OPEN - this is the hatch the cage enters through.
//
// Everything dimensional comes from dimensions.scad. Nothing is hard-coded that
// has a variable there.
// ============================================================================

include <dimensions.scad>
include <helpers.scad>

// ---- Local shorthands ------------------------------------------------------
W  = cage_w;        // 75  outer width  (X)
H  = cage_h;        // 78  outer height (Z)
D  = cage_d;        // 60  outer depth  (Y)
t  = sled_wall;     // 2.0 cage wall thickness
eps = 0.01;         // tiny overlap so booleans cut cleanly

// Inner cavity (the usable volume once walls are removed).
IW = W - 2*t;
ID = D - 2*t;
IH = H - t;         // base is OPEN, so only the top eats a wall

// Front face is the plane y = -D/2 (outer) / y = -D/2 + t (inner).
// Back  wall is the plane y = +D/2.

// ---------------------------------------------------------------------------
// SHELL: a box open on the bottom (base hatch). It is built from shell_prof
// (dimensions.scad) via shell_stack (helpers.scad): a W x D rectangular cross
// section that is FLAT and FULL through the whole board-mounting zone, and only
// chamfered at the corners near the feet (low) and the shoulders/arms (high).
// This is what keeps every mounting boss backed by a real, flat wall (a plain
// box poked its corners through the round panda; a naive taper moved the walls
// away from the bosses so they floated - both are fixed here).
//
// shell_solid(shrink, ztop): the FILLED shell body (cavity not removed), inset by
// `shrink` and clipped to height `ztop`. shrink=0 is the outer surface; shrink=t
// is the inner surface used to carve the wall. It doubles as the "is this inside
// the shell?" oracle used to clip the bosses (see cage()).
module shell_solid(shrink = 0, ztop = H) {
    intersection() {
        shell_stack(shell_prof, shrink);
        translate([-200, -200, -50]) cube([400, 400, 50 + ztop]);
    }
}

module cage_shell() {
    difference() {
        shell_solid(0, H);                       // outer
        // interior: same shape inset by the wall thickness, dropped below the base
        // (open hatch) and capped t below the top (leaves the top wall).
        translate([0, 0, -2*eps]) shell_solid(t, H - t);
    }
}

// ---------------------------------------------------------------------------
// BASE RIM + MAGNET POCKETS.
// A shallow outward flange around the open base gives the cage a face to seat
// against the body's hatch collar and houses the 4 retention magnets. Pockets
// are OPEN (through the flange) so the magnet face sits flush and meets its
// body-side partner metal-to-metal. Pocket depth = magnet_t (flush).
// ---------------------------------------------------------------------------
rim_h = magnet_t + 1.2;     // flange thickness: magnet depth + a little backing
// At the base the panda's FEET/paws stick forward on the BELLY (front, cage -Y) -
// lots of solid base there - while the RUMP (back, cage +Y) recedes and narrows.
// So the flange puts its full outward rim + magnets on the FRONT (feet) and SIDES,
// and pulls the BACK edge IN to follow the rump (no back rim). flange_* are cage-
// frame reaches (front = -Y). [Breach fit-check against the reoriented base skin.]
front_rim = 4;              // outward rim at the FRONT (over the feet base)
side_rim  = 3;              // outward rim on the SIDES
back_pull = 8;              // pull the BACK edge IN (rump recedes at the base)
back_xw   = 24;             // back edge half-width (the rump narrows)
flange_xw = W/2 + side_rim;      // SIDE reach
front_yf  = -(D/2 + front_rim);  // FRONT (feet) reach, cage -Y (outward)
back_yb   = D/2 - back_pull;      // BACK (rump) edge, pulled IN

module base_flange() {
    difference() {
        translate([0, 0, rim_h/2])
            hull() {
                // front two corners (full rim, over the feet)
                for (sx=[-1,1])
                    translate([sx*(flange_xw-corner_r), front_yf + corner_r, 0])
                        cylinder(h=rim_h, r=corner_r, center=true);
                // side mid points (full side rim) where the side magnets sit
                for (sx=[-1,1])
                    translate([sx*(flange_xw-corner_r), 0, 0])
                        cylinder(h=rim_h, r=corner_r, center=true);
                // back two corners (pulled IN, follows the receding rump)
                for (sx=[-1,1])
                    translate([sx*(back_xw-corner_r), back_yb - corner_r, 0])
                        cylinder(h=rim_h, r=corner_r, center=true);
            }
        // keep the interior open (don't block the hatch)
        translate([0, 0, rim_h/2 - eps])
            cube([IW, ID, rim_h + 2*eps], center=true);
    }
}

// 4 magnet pockets, open from the base (-Z), flush top. Placed where the flange
// sits over SOLID body base: the two FRONT corners (over the feet) and two on the
// SIDES. Centres are inset from the outer flange edge so the pocket wall stays intact.
mag_side_y = 0;             // side magnets at mid-depth (cage frame)
mag_inset  = 3;            // pocket-centre inset from the outer flange edge
module magnet_pockets() {
    pts = [[ flange_xw - mag_inset,  front_yf + mag_inset],   // front-right (foot)
           [-flange_xw + mag_inset,  front_yf + mag_inset],   // front-left  (foot)
           [ flange_xw - mag_inset,  mag_side_y],             // side-right
           [-flange_xw + mag_inset,  mag_side_y]];            // side-left
    for (p = pts)
        translate([p[0], p[1], magnet_t/2 - eps])
            cylinder(h = magnet_t + 2*eps, d = magnet_d - 2*magnet_fit, center=true);
}

// ---------------------------------------------------------------------------
// FRONT-FACE LAYOUT (the -Y wall).
// Z runs 0 (base) .. H (top). OLED sits high, joystick below it.
// Give a small margin from the top and a gap between the two devices.
// ---------------------------------------------------------------------------
front_y      = -D/2;                 // outer plane of the front wall

// OLED and joystick CENTRES come from dimensions.scad (single source of truth):
// oled_cz / joy_cz are DERIVED there from dev_oled_pz / dev_joy_pz and cage_z0 so
// that cage-internal Z + cage_z0 = panda Z. With the current values the devices
// land at panda Z46 (OLED window, on the screen plaque) and Z20 (joystick, on the
// round knob) - on the BELLY (+Y after the panda.scad reorientation).
// The joystick PCB overlaps behind the OLED PCB's lower dead-space (OLED lit area
// is only 28mm of the 46.6mm board, sitting +3.1 above centre); the two PCBs mount
// at DIFFERENT depths (short OLED standoffs, taller joystick standoffs) so they
// overlap in Z without touching. dev_sep, oled_cz, joy_cz are defined in
// dimensions.scad.

// ---------------------------------------------------------------------------
// OLED: window through the front wall (at the LIT area, offset +3.1 up), plus
// four standoffs behind the wall on the measured 64.3 x 43.0 / Ø2.5 pattern.
// The window is positioned by the OLED's active-area centre, which sits at
// (oled_active_dx, oled_active_dy) relative to the PCB centre (oled_cz).
// ---------------------------------------------------------------------------
module oled_window_cut() {
    // active-area centre in cage coords
    ax = oled_active_dx;
    az = oled_cz + oled_active_dy;
    translate([ax, front_y + t/2, az])
        rotate([90, 0, 0])
            linear_extrude(height = t + 4, center = true)
                offset(r = 1.5)   // rounded corners + a little bezel clearance
                    square([oled_active_w + fit_gap, oled_active_h + fit_gap],
                           center = true);
}

// A standoff post standing off the inside of the front wall, pointing +Y into
// the cavity. Height lifts the PCB clear of the wall; screw pilot up the axis.
// OLED and joystick both sit on SHALLOW standoffs. Although their PCBs overlap
// slightly in Z (28mm centres), their COMPONENTS don't share space: the OLED's
// header runs along its edges (X~+-33) while the joystick is central (X~+-13)
// and 10mm lower, so a modest standoff keeps everything clear - no deep offset
// needed (which had pushed joystick pins into the back-wall boards).
so_h_oled = 4;    // OLED standoff height off the wall
so_h_joy  = 6;    // joystick standoff (slightly taller for its gimbal clearance)
embed = 1;        // how far a post sinks INTO its wall so it fuses
module front_standoff(h) {
    translate([0, front_y + t - embed, 0])
        rotate([-90, 0, 0])          // cylinder axis -> +Y
            screw_boss(h + embed);
}

module oled_standoffs() {
    for (sx=[-1,1], sz=[-1,1])
        translate([sx*oled_hole_dx/2, 0, oled_cz + sz*oled_hole_dy/2])
            front_standoff(so_h_oled);
}

// ---------------------------------------------------------------------------
// JOYSTICK: a TILT CONE through the front wall (not a straight bore) so the
// stick can lean without fouling the wall, plus four standoffs on the
// 19.85 x 19.8 / Ø3.2 pattern.
//
// SIZING: uses the SLIM PRINTED CAP design (joy_panel_open ~20mm, joy_use_tilt
// ~11deg), NOT the stock 26mm cap - matching panda.scad's belly cut. (The old
// code sized this cone for the stock 26mm flange at 23deg, giving a ~38mm hole
// that collided with the OLED window above it and left no bridge in the front
// wall.) The opening is joy_panel_open at the flange plane plus the small d-pad
// swing, flared a touch toward the front face.
// ---------------------------------------------------------------------------
module joystick_cone_cut() {
    // radius needed at the panel plane for the slim cap
    r_inner = joy_panel_open/2 + fit_gap;
    // extra lateral room from the small d-pad tilt
    sweep   = tan(joy_use_tilt) * joy_flange_z;
    r_outer = r_inner + sweep + fit_gap;
    // cone from just inside the wall (small) flaring to the front face (large)
    translate([0, front_y + t + eps, joy_cz])
        rotate([90, 0, 0])           // cone axis -> -Y (out the front)
            cylinder(h = t + 2, r1 = r_inner, r2 = r_outer, center = false);
}

module joystick_standoffs() {
    for (sx=[-1,1], sz=[-1,1])
        translate([sx*joy_hole_dx/2, 0, joy_cz + sz*joy_hole_dy/2])
            front_standoff(so_h_joy);
}

// ---------------------------------------------------------------------------
// SPEAKER on the TOP face (+Z). Grille faces UP, firing into the head cavity.
// - A stadium-shaped throat through the top wall matches the grille opening
//   (spk_grille_l x spk_grille_w), so sound passes up.
// - Four bosses receive the ear screws on the 63.6 x 21.2 / Ø3.2 pattern.
// Speaker long axis (51.25 body, 69.5 tip-to-tip) runs along X; its 30.9 width
// runs along Y. Ears extend on the long (X) axis only.
//
// The whole speaker is shifted spk_cy_off toward the BELLY (-Y). Reason: the top
// necks IN at the back for the panda's folded arms; if the speaker stayed centred,
// its rear ears would need the top to flare back OUT (an outward-pointing overhang
// tab - the "pointy protrusions"). Nudging the speaker forward lets BOTH ear rows
// sit inside a top that necks in monotonically, so no tabs are needed.
top_z = H;          // outer plane of the top wall
spk_cy_off = 8;     // speaker Y-centre, shifted toward the BACK (+Y) so its ears
                    // clear the big FRONT chamfer that relieves the belly/arms

// A stadium (rectangle + semicircular ends) profile in the XY plane.
module stadium(len, wid) {
    r = wid/2;
    hull() for (sx=[-1,1]) translate([sx*(len/2 - r), 0]) circle(r = r);
}

module speaker_throat_cut() {
    translate([0, spk_cy_off, top_z - t/2])
        linear_extrude(height = t + 4, center = true)
            stadium(spk_grille_l + fit_gap, spk_grille_w + fit_gap);
}

// Boss hanging DOWN from the underside of the top wall, screw pilot up the axis.
spk_boss_h = 6;
module top_boss() {
    // extend 'embed' up into the top wall so it fuses to the shell
    translate([0, 0, top_z - t - spk_boss_h])
        screw_boss(spk_boss_h + embed);
}

module speaker_bosses() {
    for (sx=[-1,1], sy=[-1,1])
        translate([sx*spk_ear_dx/2, spk_cy_off + sy*spk_ear_dy/2, 0])
            top_boss();
}

// ---------------------------------------------------------------------------
// BACK WALL (+Y): the three free boards screw to bosses standing off the wall.
// NO snap clips (unreliable to print) - everything is screw-mounted.
//
// KEY INSIGHT: the OPEN BASE is the service side. Anything needing external
// access points DOWN toward it:
//   ESP32   - PORTRAIT on the LEFT, USB-C edge DOWN -> charge cable exits base.
//   DFPlayer- lower-RIGHT, SD-slot edge DOWN -> card reachable through the base.
//   RTC      - upper-RIGHT, its 3 real holes on bosses.
//
// Boards without holes (ESP32, DFPlayer) are trapped by a screwed CROSS-BAR:
// two bosses beyond the board edges and a printed bar that screws down over the
// board. Simple, printable, and removable.
//
// The back wall inner face is at y = back_y; bosses stand toward -Y by so_back.
// ---------------------------------------------------------------------------
back_y  = D/2 - t;      // inner face of the back wall
so_back = 12;           // board stand-off from the back wall (clears pins)

// A boss standing off the back wall toward -Y. Post base at the wall, top at
// y = back_y - h. Pilot hole bored from the -Y (open) end for a self-tap screw.
module back_boss(h = so_back) {
    // start 'embed' inside the wall (at back_y + embed) so it fuses to the shell
    translate([0, back_y + embed, 0])
        rotate([90, 0, 0])           // +Z of screw_boss -> -Y
        difference() {
            cylinder(h = h + embed, d = screw_boss_d);
            translate([0, 0, h + embed - insert_pilot_depth])
                cylinder(h = insert_pilot_depth + eps, d = screw_hole_d);
        }
}
insert_pilot_depth = 8;              // how deep the self-tap pilot runs

// Two bosses flanking a board on the given axis, for a screwed retention bar.
// board centred at (cx,cz); span is the boss-centre distance. Boss centres are
// CLAMPED to stay inside the usable wall so they never poke past the shell.
bmargin = screw_boss_d/2 + 1;        // keep boss fully inside the wall
module retention_bosses(cx, cz, span, vertical=false) {
    for (s=[-1,1]) {
        bx = vertical ? cx : cx + s*span/2;
        bz = vertical ? cz + s*span/2 : cz;
        cbx = max(-W/2 + t + bmargin, min(W/2 - t - bmargin, bx));
        cbz = max(t + bmargin,        min(H   - bmargin,     bz));
        translate([cbx, 0, cbz]) back_boss();
    }
}

// Layout verified collision-free (script check): ESP32 sits ABOVE the joystick
// keep-out band; RTC upper-right; DFPlayer far-right-low, clear of the joystick
// X band. USB-C (ESP32) and SD (DFPlayer) edges both point DOWN to the base.

// ---- ESP32: portrait, LEFT, USB-C down -------------------------------------
// board 53.2 tall (Z) x 28.4 wide (X). USB-C at the bottom edge -> exits base.
// esp_cz is pulled DOWN and the retention span kept just INSIDE the board ends so
// the TOP retention boss lands ~Z60 - inside the flat board zone, NOT up in the
// shoulder taper where it used to float. The bar then sits ~2mm onto each board
// end (clear of the central components).
esp_cx = -W/2 + t + 2 + esp_h/2;     // hug the left inner wall  (~ -19.3)
esp_cz = 35;                         // lowered so the top boss stays in the flat zone
module esp32_mount() {
    retention_bosses(esp_cx, esp_cz, esp_w - 4, vertical=true);   // bosses just inside the ends
}

// ---- RTC: upper-right, 3 measured holes ------------------------------------
// Lowered so its top mounting hole stays in the flat board zone (below the
// shoulder chamfer that starts ~Z60), not up in the necked-in top.
rtc_cx = W/2 - t - 2 - rtc_w/2;      // hug the right inner wall
rtc_cz = 50;                         // was H-8-rtc_h/2 (=59, too high)
module rtc_mount() {
    holes = [[rtc_hole1_x, rtc_hole1_y],
             [rtc_hole2_x, rtc_hole2_y],
             [rtc_hole3_x, rtc_hole3_y]];
    for (h = holes)
        translate([rtc_cx + (h[0] - rtc_w/2), 0, rtc_cz + (h[1] - rtc_h/2)])
            back_boss();
}

// ---- DFPlayer: bottom-right, SD slot down ----------------------------------
dfp_cx = W/2 - t - 2 - dfp_w/2;      // right wall, below the RTC
dfp_cz = t + 6 + dfp_h/2;
module dfp_mount() {
    retention_bosses(dfp_cx, dfp_cz, dfp_w + 8, vertical=false);
}

// ---- USB-C exit slot on the BACK wall --------------------------------------
// The ESP32's USB-C points DOWN (Z=40.2 @ x=esp_cx); the cable curves ~90 deg
// in the 12mm board-to-wall gap and exits the back. The slot is sized to the
// PANEL-MOUNT USB-C flange (not just the cable) so a fixed port can be retro-
// fitted later WITHOUT a redesign - for now the loose cable simply threads it.
// Two unused flanking bosses are left for the future panel-mount screws.
usb_slot_x   = esp_cx;               // under the ESP32's USB edge
usb_slot_z   = 16;                   // low on the back, above the base flange
pm_flange_w  = 20;                   // typical panel-mount USB-C flange footprint
pm_flange_h  = 12;
pm_screw_dx  = 24;                   // panel-mount screw spacing (future use)
module usb_exit_cut() {
    translate([usb_slot_x, back_y + t/2, usb_slot_z])
        rotate([90, 0, 0])
            linear_extrude(height = t + 4, center = true)
                offset(r = 1.5)
                    square([pm_flange_w - 3, pm_flange_h - 3], center = true);
}
// Future panel-mount screw bosses (harmless now; give the retrofit somewhere to
// land). Commented into the build so they print - they don't obstruct anything.
module usb_panelmount_bosses() {
    for (s=[-1,1])
        translate([usb_slot_x + s*pm_screw_dx/2, 0, usb_slot_z])
            back_boss(6);
}

// ---------------------------------------------------------------------------
// RETENTION BARS (separate printed parts).
// ESP32 and DFPlayer have no mounting holes, so a small printed bar screws to
// their two flanking bosses and traps the board against the standoffs. Bar
// length = boss span; two clearance holes at the ends; a shallow relief in the
// middle so it presses the board edges, not the components.
// bore = clearance for the self-tap screw shank.
// ---------------------------------------------------------------------------
bar_w  = 8;      // bar cross width
bar_th = 3;      // bar thickness
screw_clear_d = 3.2;   // clearance hole for the screw shank

module retention_bar(span, board_th = 1.6) {
    // laid flat for printing: length along X = span + end pads
    L = span + bar_w;
    difference() {
        union() {
            cube([L, bar_w, bar_th], center=true);
            // small feet at the ends that reach down to the board edge
        }
        // two screw clearance holes at +-span/2
        for (s=[-1,1])
            translate([s*span/2, 0, 0])
                cylinder(h = bar_th + 2, d = screw_clear_d, center=true);
    }
}

module esp32_bar() { retention_bar(esp_w + 8, esp_t); }
module dfp_bar()   { retention_bar(dfp_w + 8, dfp_t); }

// ---------------------------------------------------------------------------
// SLIM JOYSTICK CAP (separate printed part).
// Replaces the stock 26mm rubber thumb-cap so the panel opening can be a tidy
// ~20mm instead of ~32mm. Used as a d-pad the stick only needs ~11 deg of travel.
//
// A ~16mm domed disc with a KEYED OVAL SOCKET underneath that press-fits the stock
// shaft (an oval post: 4.0mm across the round, 3.0mm across two flats, 5.95mm tall).
// The oval keys the cap against rotation. Socket at nominal shaft size + a hair of
// clearance; a drop of CA locks it. Print socket-up (dome on the bed) or dome-up
// with supports; socket-up needs none and hides layer lines on top.
// ---------------------------------------------------------------------------
cap_wall   = 2.0;    // wall around the socket
cap_h      = 8.0;    // overall cap height (dome + socket barrel)
sock_clr   = 0.15;   // socket clearance over the shaft (CA glue takes up the rest)

// An oval cross-section: a circle of dia `d` flattened to width `w` across the flats.
module oval2d(w, d) {
    intersection() {
        circle(d = d);
        square([w, d + 1], center = true);
    }
}

module joy_cap() {
    d = joy_slim_cap_d;
    sock_d = joy_shaft_d + 2*sock_clr;   // socket across the round
    sock_w = joy_shaft_w + 2*sock_clr;   // socket across the flats
    sock_depth = joy_shaft_len + 0.5;    // a touch deeper than the shaft
    difference() {
        union() {
            // socket barrel (keyed oval outer follows the shaft, + wall)
            linear_extrude(cap_h - 2)
                oval2d(sock_w + 2*cap_wall, sock_d + 2*cap_wall);
            // domed top disc
            translate([0, 0, cap_h - 2])
                hull() {
                    linear_extrude(0.1) circle(d = d);
                    translate([0, 0, 2]) scale([1, 1, 0.5]) sphere(d = d - 1);
                }
            // blend the barrel into the disc
            translate([0, 0, cap_h - 3]) cylinder(h = 1.2, d1 = sock_w + 2*cap_wall + 2, d2 = d);
        }
        // the keyed oval socket, open at the bottom (-Z)
        translate([0, 0, -eps])
            linear_extrude(sock_depth)
                oval2d(sock_w, sock_d);
        // a small chamfer at the socket mouth to guide the shaft in
        translate([0, 0, -eps])
            linear_extrude(1.0)
                oval2d(sock_w + 1.2, sock_d + 1.2);
    }
}

// ---------------------------------------------------------------------------
// ASSEMBLY
// ---------------------------------------------------------------------------
module cage() {
    difference() {
        union() {
            cage_shell();
            base_flange();          // flange sticks OUT past the shell by design
            // All wall-mounted bosses are CLIPPED to the outer shell so none can
            // ever protrude past a wall or float outside it (a boss in the cavity
            // is fully inside shell_solid(0), so it is kept; only stray material
            // outside the outer surface is trimmed). This is the safety net that
            // guarantees "no screw holes outside the box"; the shell profile above
            // already ensures every board's bosses land on a flat wall so their
            // heights stay consistent.
            intersection() {
                union() {
                    oled_standoffs();
                    joystick_standoffs();
                    speaker_bosses();
                    esp32_mount();
                    rtc_mount();
                    dfp_mount();
                }
                shell_solid(0, H);
            }
        }
        oled_window_cut();
        joystick_cone_cut();
        speaker_throat_cut();
        magnet_pockets();
        usb_exit_cut();
    }
}

// ---------------------------------------------------------------------------
// PART SELECTOR - set `part` to export/preview individual printable pieces.
//   "cage"      the main cage body
//   "esp32_bar" ESP32 retention bar
//   "dfp_bar"   DFPlayer retention bar
//   "joy_cap"   slim replacement joystick thumb-cap
//   "all"       everything, small parts laid beside the cage (preview only)
// ---------------------------------------------------------------------------
part = "cage";

if      (part == "cage")      cage();
else if (part == "esp32_bar") esp32_bar();
else if (part == "dfp_bar")   dfp_bar();
else if (part == "joy_cap")   joy_cap();
else if (part == "all") {
    cage();
    translate([-W, -D, 0]) esp32_bar();
    translate([-W, -D-15, 0]) dfp_bar();
    translate([-W, -D-30, 0]) joy_cap();
}
