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
// FRONT FACE  (-Y): the OLED, and nothing else - it is 68.63 x 46.60 and there was
//                   never room for a second device here.
// BACK WALL   (+Y): the JOYSTICK, bolted to standoffs on the wall's OUTER face so
//                   the gimbal points away from it into the rump, plus the DFPlayer
//                   and the USB-C charge exit inside, below it.
// SIDE WALLS  (+-X): ESP32 (left, portrait), RTC + DFPlayer (right). Moved off the
//                   back wall to make room for the joystick - and they are better
//                   off here anyway, because the shell's corner chamfers barely
//                   touch the side faces (at the worst height the side wall is
//                   still 38.7mm deep).
// TOP FACE    (+Z): speaker, grille up, firing into the head cavity.
// BASE        (-Z): the hatch the cage enters through - open for assembly, then
//                   closed by the printed BASE COVER (part = "cover").
//
// Everything dimensional comes from dimensions.scad. Nothing is hard-coded that
// has a variable there.
// ============================================================================

include <dimensions.scad>
include <helpers.scad>
use <panda.scad>          // for skin_inset(): trims the cage's upper front-side corners
                          // to the SAME inward-eroded skin the body cavity is clipped to,
                          // so the cage matches the thickened belly wall at the arm-fold
                          // and still seats. (Only the feature-free corners are shaved -
                          // clear of the OLED standoffs.) Loads the panda mesh on render.

// ---- Local shorthands ------------------------------------------------------
W  = cage_w;        // 75  outer width  (X)
H  = cage_h;        // 80  outer height (Z)
D  = cage_d;        // 88  outer depth  (Y)
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
// The footprint (core rim + the four magnet ears) lives in helpers.scad as
// base_flange_2d(), shared with the panda's rebate so the two cannot drift.
// rim_h / flange_xw / front_yf / back_yb / mag_pos are in dimensions.scad.
flange_lead = 1.5;      // step-back on the flange's bottom edge (see below)
module base_flange() {
    difference() {
        // The bottom flange_lead of the rim is stepped back. Two reasons: it is a
        // lead-in that helps the flange find its rebate, and it clears a small
        // breach - the flange's FRONT rim at panda Y44 was up to 0.47mm proud of
        // the sculpt's base fillet over panda Z2.00..2.47, |X|<26 (found by the
        // fitcheck "breach" mode). A step rather than a chamfer because
        // base_flange_2d() is non-convex (the magnet ears), so hulling two offsets
        // of it would bridge straight across between the ears.
        union() {
            linear_extrude(flange_lead)
                offset(delta = -flange_lead) base_flange_2d();
            translate([0, 0, flange_lead])
                linear_extrude(rim_h - flange_lead) base_flange_2d();
        }
        // keep the interior open (don't block the hatch).
        // BUG FIX 2026-08-20: this used to be
        //     translate([0,0,-eps]) cube([IW, ID, rim_h + 2*eps], center = true)
        // and `center = true` centres in Z as well, so the cube only reached
        // z = rim_h/2 (2.09) - leaving the top HALF of the flange solid right
        // across the base. The cage as printed therefore has a 2.1mm floor over
        // its whole footprint at Z2.1..4.2: measured on the exported STL, a
        // Z-ray anywhere in the base returns [2.1, 4.2]. That is not the open
        // hatch the design describes, and it sits directly under the DFPlayer's
        // SD slot and the ESP32's USB-C, both of which face down at it.
        translate([0, 0, -eps])
            linear_extrude(rim_h + 2*eps)
                square([IW, ID], center = true);
    }
}

// 4 magnet pockets, flush with the flange's TOP face (+Z) - that face is where the
// pair meets its body-side partner, which is recessed into the rebate's ceiling. The
// pocket bottoms out on 1.2mm of backing (rim_h - magnet_t) so the magnet cannot be
// pushed straight through, and is undersized by magnet_fit per side for a press fit.
// CHECK POLARITY against the body magnet before gluing (see dimensions.scad).
module magnet_pockets() {
    for (p = mag_pos)
        translate([p[0], p[1], rim_h - magnet_t])
            cylinder(h = magnet_t + eps, d = magnet_d - 2*magnet_fit);
}

// ---------------------------------------------------------------------------
// FRONT-FACE LAYOUT (the -Y wall): the OLED, alone.
// Z runs 0 (base) .. H (top). oled_cz comes from dimensions.scad (single source of
// truth), derived from dev_oled_pz and cage_z0 so cage Z + cage_z0 = panda Z.
// With dev_oled_pz = 47.8 the PCB spans cage Z14.4..61.0 and all four mounting
// bosses (at Z16.2 and Z59.2, |X|32.15) land on FLAT wall: shell_prof's cf is 0
// through cage Z42 and never exceeds 1.92, so a chamfer cannot reach them.
// ---------------------------------------------------------------------------
front_y      = -D/2;                 // outer plane of the front wall

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
//
// so_h_oled MUST clear the OLED's soldered pin header, which protrudes
// oled_depth_hdr - oled_depth_bare = 12.55 - 6.23 = 6.32mm behind the PCB. It used
// to be 4, so the header drove 2.3mm into a 2.0mm wall and out the front of the
// screen window - oled_depth_hdr was measured but never used by any geometry.
// 7 clears it anywhere on the board, with no assumption about which edge it is on.
//
// COST OF THAT, AND THE OPEN QUESTION: every mm of standoff pushes the glass
// further back from the belly. Glass front = cage_yfront - t - so_h_oled + 6.23 =
// panda Y42.23, and the belly skin over the window is at panda Y57.91, so the screen
// sits 15.7mm deep. Cutting the header down, fitting a right-angle one, or
// desoldering the left-edge header (so_h_oled 2) buys 5mm of that back - 10.7mm.
// That is close to the floor for this display whatever the host size: a flat 68.63mm
// board can only reach the narrowest point across its own width, and the belly's
// lateral drop from X0 to X34 is 4-10mm at any scale (README.md has the numbers).
so_h_oled = 7;    // OLED standoff height off the wall - clears the 6.32mm header
embed = 1;        // how far a post sinks INTO its wall so it fuses
module front_standoff(h) {
    translate([0, front_y + t - embed, 0])
        rotate([-90, 0, 0])          // cylinder axis -> +Y
            // M2 pilot: the OLED's own holes are Ø2.5, which an M3 cannot pass.
            screw_boss(h + embed, screw_hole_d_m2);
}

module oled_standoffs() {
    for (sx=[-1,1], sz=[-1,1])
        translate([sx*oled_hole_dx/2, 0, oled_cz + sz*oled_hole_dy/2])
            front_standoff(so_h_oled);
}

// ---------------------------------------------------------------------------
// JOYSTICK on the OUTER face of the BACK wall (+Y), laid SIDEWAYS
// (32.30 across X, 26.70 up Z, hole pattern 26.0 X x 19.85 Z - a rectangle;
// the old 19.80 X was the gimbal body's width misread as a hole pitch).
//
// It used to be built as a thickened plinth INSIDE the back wall, a pocket the PCB
// dropped into, a bore through the wall for the gimbal, and four bosses outboard of
// the PCB carrying a separate printed retention frame. All of that existed for one
// reason: the module's own mounting holes (19.85 x 19.80) sit right on the edge of
// the bore the gimbal (19.80 x 23.40) needs, so a boss there loses over half its
// section.
//
// Turning the module round deletes the whole problem. Screw it to four short
// standoffs on the OUTSIDE of the wall with the gimbal pointing away into the rump
// and there is no bore, no pocket, no plinth and no frame - the only thing that has
// to pass through the wall is five wires. It also uses the module's own holes, which
// is what they are for.
//
// Fit it before the cage goes into the panda: the screws come from the rump side.
// The assembly stands 14.68mm proud of the back face, so panda.scad cuts a stepped
// insertion channel up the rump for it to travel in.
// ---------------------------------------------------------------------------
back_y  = D/2 - t;      // inner face of the back wall
back_yo = D/2;          // OUTER face of the back wall

// A boss standing off the back wall toward -Y (into the cavity).
module back_boss(h = 12) {
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

// A boss standing off the back wall's OUTER face toward +Y. Same construction,
// mirrored - it starts inside the wall so it fuses, and the pilot is bored from the
// +Y (open) end so the screw goes in from the rump side.
module back_boss_out(h) {
    translate([0, back_yo - embed, 0])
        rotate([-90, 0, 0])          // +Z of the boss -> +Y
        difference() {
            cylinder(h = h + embed, d = screw_boss_d);
            translate([0, 0, h + embed - insert_pilot_depth])
                cylinder(h = insert_pilot_depth + eps, d = screw_hole_d);
        }
}

// The four standoffs the KY-023 bolts onto, on its own measured hole pattern.
module joystick_standoffs() {
    for (sx=[-1,1], sz=[-1,1])
        translate([sx*joy_hole_dy/2, 0, joy_cz + sz*joy_hole_dx/2])
            back_boss_out(joy_so_h);
}

// DEEPEN those pilots into the wall. back_boss_out()'s own pilot cannot reach past
// the wall's outer face: the boss is differenced BEFORE it is unioned with the
// shell, so the wall refills the bore and the printed pilot bottoms out at exactly
// joy_so_h = 2mm. A screw then gets 2mm of thread before its tip hits solid wall -
// an M3x4 through the 0.92mm PCB stops ~1mm before the head seats. These cuts run
// in cage()'s TOP-LEVEL difference (after the shell union), continuing each pilot
// through the wall but stopping joy_pilot_web short of the inner face, so the
// holes stay blind: usable depth 2 + 1.5 = 3.5mm (fits an M3x4; do not use longer).
joy_pilot_web = 0.5;
module joystick_pilot_cuts() {
    for (sx=[-1,1], sz=[-1,1])
        translate([sx*joy_hole_dy/2, back_y + joy_pilot_web, joy_cz + sz*joy_hole_dx/2])
            rotate([-90, 0, 0])
                cylinder(h = (t - joy_pilot_web) + joy_so_h + eps, d = screw_hole_d);
}

// The only thing left to cut: a slot for the module's five wires, just below the
// PCB's bottom edge so the loom can turn round the board and come back inside.
module joystick_wire_cut() {
    translate([0, back_y + t/2, joy_cz - joy_pcb_w/2 - 3])
        rotate([90, 0, 0])
            linear_extrude(height = t + 4, center = true)
                offset(r = 1.5)
                    square([joy_wire_w - 3, joy_wire_h - 3], center = true);
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
//
// !!! THE PILOT IS BORED FROM BELOW, NOT VIA screw_boss() !!!  The speaker's ear
// sits against the boss's BOTTOM face and its screw comes UP from inside the cage,
// so the hole must open downward. screw_boss() bores from the local +Z end, which
// here is buried inside the top wall - on the exported cage all four pilots were
// SEALED internal voids with a 1mm solid cap right where the screw enters (found
// by raycast: axis hits at z72/73, i.e. plastic across the mouth). The bore depth
// leaves a 1mm cap up in the wall so the cage's top face stays closed.
spk_boss_h = 6;
module top_boss() {
    // extend 'embed' up into the top wall so it fuses to the shell
    translate([0, 0, top_z - t - spk_boss_h])
        difference() {
            cylinder(h = spk_boss_h + embed, d = screw_boss_d);
            translate([0, 0, -eps])
                cylinder(h = spk_boss_h + embed - 1 + eps, d = screw_hole_d);
        }
}

module speaker_bosses() {
    for (sx=[-1,1], sy=[-1,1])
        translate([sx*spk_ear_dx/2, spk_cy_off + sy*spk_ear_dy/2, 0])
            top_boss();
}

// ---------------------------------------------------------------------------
// SIDE WALLS (+-X): the three free boards.
//
// They used to be on the back wall. The joystick lives there now, and the two
// cannot share it. The side walls are the right home anyway: the shell's corner
// chamfers only cut the FRONT and BACK corners, so a side face stays full-depth
// through the whole board zone (cf never exceeds 1.92 on this host), and at
// cage_d 88 there are 84mm of usable Y for boards that are all under 54mm long.
//
// KEY RULE, UNCHANGED: the OPEN BASE is the service side, so anything needing
// external access points DOWN at it - the ESP32's USB-C and the DFPlayer's SD slot.
//
//   LEFT  wall (-X): ESP32, portrait (53.2 up Z, 28.4 across Y), USB-C edge DOWN.
//   RIGHT wall (+X): RTC, on its 3 real holes.
//   BACK  wall (+Y): joystick OUTSIDE (see above); DFPlayer lower-right and the USB
//                    exit lower-left inside.
//
// Boards without holes (ESP32, DFPlayer) are trapped by a screwed CROSS-BAR: two
// bosses beyond the board edges and a printed bar over the board. No snap clips.
//
// KEEP-OUT: everything here must stay clear of the OLED, which is 68.63 wide and
// hangs off the front wall - its PCB back sits at cage y-35.02 and its soldered
// header reaches y-27.7. So side-wall boards start at y >= -26. (The old -14 was
// the same rule against a 60mm-deep cage; the extra 28mm of depth all lands here.)
// ---------------------------------------------------------------------------
so_side  = 12;          // board stand-off from a side wall (clears header pins)
so_back  = 12;          // ... and from the back wall (the DFPlayer)
side_x   = W/2 - t;     // inner face of the RIGHT wall (left is -side_x)
side_y0  = -26;         // front edge of the side-wall board zone (clears the OLED)

// A boss standing off a side wall, pointing INWARD. `sx` = -1 left, +1 right.
// Note the sign: rotate([0, -sx*90, 0]) is what sends the boss's +Z toward the
// cage's centre. Getting it backwards points every boss out through the wall, where
// the shell_solid() clip in cage() then deletes it - a silent failure, since the
// render is still manifold and just quietly has no board mounts at all.
module side_boss(sx, h = so_side, pd = screw_hole_d) {
    translate([sx*(side_x + embed), 0, 0])
        rotate([0, -sx*90, 0])       // +Z of the boss -> inward
        difference() {
            cylinder(h = h + embed, d = screw_boss_d);
            translate([0, 0, h + embed - insert_pilot_depth])
                cylinder(h = insert_pilot_depth + eps, d = pd);
        }
}

// Two bosses flanking a board on a side wall, for a screwed retention bar.
// Board centred at (cy, cz) on wall `sx`; `span` is the boss-centre distance.
// Centres are CLAMPED into the usable wall so a boss can never float outside it.
bmargin = screw_boss_d/2 + 1;
module side_retention_bosses(sx, cy, cz, span, vertical=false) {
    for (s=[-1,1]) {
        by = vertical ? cy : cy + s*span/2;
        bz = vertical ? cz + s*span/2 : cz;
        cby = max(-D/2 + t + bmargin, min(D/2 - t - bmargin, by));
        cbz = max(t + bmargin,        min(H - t - bmargin,   bz));
        translate([0, cby, cbz]) side_boss(sx);
    }
}

// ---- ESP32: LEFT wall, portrait, USB-C down --------------------------------
// 53.2 up Z x 28.4 across Y.
esp_cy = side_y0 + esp_h/2;            // hug the front of the board zone (-11.8)
// THE HEIGHT IS THE WHOLE POINT OF THE 200mm HOST. Budget, bottom up:
//     cover ledge          6.0
//     clearance            2.0
//     straight USB-C plug 16.0     <- this is what never fitted before
//     board (portrait)    53.2
//                        =77.2  against 78.0 of interior (H - t)
// So esp_cz 50 puts the board at cage Z23.4..76.6, its USB-C mouth at
// Z50 - 26.6 - 1.5 = 21.9 (usb_slot_z 22) and the plug body ends at ~Z6, right on
// top of the ledge instead of running out through the base cover into the table.
// The top retention boss is clamped to Z74 by side_retention_bosses(); the speaker's
// ear bosses hang down to Z72 at |X|31.8, y -2.6/18.6, clear of it in Y.
esp_cz = 50;                           // 53.2 tall -> cage Z23.4..76.6
// The boss span the bar must be drilled to is the span the bosses ACTUALLY get
// after side_retention_bosses() clamps them into the usable wall band. On this
// host the TOP boss is clamped (esp_cz + 24.6 = 74.6 -> 74), so the as-built span
// is 48.6, not 49.2 - a bar drilled at 49.2 has one hole 0.6mm off its boss, and
// an M3 in a 3.2 clearance hole only forgives ~0.2. Both the mount and the bar
// derive from the same clamped numbers so they cannot disagree again.
esp_span    = esp_w - 4;                                    // wanted span (49.2)
esp_boss_lo = max(t + bmargin,     esp_cz - esp_span/2);    // 25.4 (unclamped)
esp_boss_hi = min(H - t - bmargin, esp_cz + esp_span/2);    // 74.0 (clamped!)
module esp32_mount() {
    side_retention_bosses(-1, esp_cy, esp_cz, esp_span, vertical=true);
}

// ---- RTC: RIGHT wall, its 3 measured holes ---------------------------------
// 38 up Z x 22 across Y. Battery holder faces INTO the cavity so the cell can be
// changed with the cage out; the standoff only has to clear the back-side pins.
rtc_cy = side_y0 + rtc_h/2;
rtc_cz = 40;                           // 38 tall -> cage Z21..59, clear of the ledge
module rtc_mount() {
    holes = [[rtc_hole1_x, rtc_hole1_y],
             [rtc_hole2_x, rtc_hole2_y],
             [rtc_hole3_x, rtc_hole3_y]];
    // rtc_hole*_x runs along the board's 38mm axis -> cage Z; _y along 22 -> cage Y
    // M2 pilot: the RTC's own holes are Ø2.3, which an M3 cannot pass.
    for (h = holes)
        translate([0, rtc_cy + (h[1] - rtc_h/2), rtc_cz + (h[0] - rtc_w/2)])
            side_boss(1, pd = screw_hole_d_m2);
}

// ---- DFPlayer: BACK wall, lower-right, SD slot down ------------------------
// 20.7 up Z (SD edge at the bottom, reachable through the base) x 20.2 across X.
// Retention bosses run HORIZONTALLY. Nothing sits on the back wall's inner face at
// this height any more - the joystick's plinth is gone - so the only neighbours are
// the USB exit slot on the left half and the joystick's wire slot at Z26.5, x0.
dfp_cx = 18;
dfp_cz = cover_ledge_h + 2 + dfp_w/2;  // 20.7 tall -> cage Z8..28.7
dfp_span = dfp_h + 8;                  // boss span flanking the 20.2mm width (28.2)
module dfp_mount() {
    for (s=[-1,1])
        translate([dfp_cx + s*dfp_span/2, 0, dfp_cz]) back_boss(so_back);
}

// ---- USB-C exit slot on the BACK wall --------------------------------------
// The ESP32's USB-C points DOWN; the cable turns in the board-to-wall gap and
// exits here, low on the back and below the joystick plinth. Position and size
// live in dimensions.scad because panda.scad has to cut the matching hole through
// the rump - it previously had NO hole at all, so the cable vented into 15.5mm of
// solid body. Sized to a panel-mount USB-C flange so a fixed port can be fitted
// later without a redesign; two flanking bosses are left for its screws.
module usb_exit_cut() {
    translate([usb_slot_x, back_y + t/2, usb_slot_z])
        rotate([90, 0, 0])
            linear_extrude(height = t + 4, center = true)
                offset(r = 1.5)
                    square([usb_flange_w - 3, usb_flange_h - 3], center = true);
}
// Future panel-mount screw bosses (harmless now; give the retrofit somewhere to
// land). Commented into the build so they print - they don't obstruct anything.
module usb_panelmount_bosses() {
    for (s=[-1,1])
        translate([usb_slot_x + s*usb_screw_dx/2, 0, usb_slot_z])
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

// Both bars are drilled to the span their bosses ACTUALLY have:
//  * ESP32: the clamped span (the top boss is pulled down to Z74, see esp_boss_hi)
//  * DFPlayer: dfp_span, the same variable dfp_mount() places the bosses with.
//    (This was retention_bar(dfp_w + 8) - the module's LENGTH, 20.7 - while the
//    bosses flank its 20.2mm WIDTH at dfp_h + 8. The 0.5mm mismatch is more than
//    an M3 in a 3.2 hole can absorb, so the second screw never started.)
module esp32_bar() { retention_bar(esp_boss_hi - esp_boss_lo, esp_t); }
module dfp_bar()   { retention_bar(dfp_span, dfp_t); }

// The JOYSTICK RETENTION FRAME that used to live here is gone. It existed only to
// clamp the KY-023 into a pocket, because its own mounting holes fell on the gimbal
// bore. With the module on the OUTSIDE of the back wall there is no bore, so its
// four holes are usable and it simply bolts to joystick_standoffs().

// ---------------------------------------------------------------------------
// BASE COVER (separate printed part) - the cage had no bottom at all.
//
// The base is the hatch the cage enters through, so it has to be open during
// assembly, but nothing ever closed it afterwards: on the first print the
// electronics face the table through a 71 x 56 hole and the panda's whole
// underside is an open box.
//
// The cover fills panda Z0..cage_z0 - exactly the gap between the flange's
// underside and the ground. Fitted last, removed first for service.
//
// Its outline is the UNION of the flange's core rim and the shell's own Z0 cross
// section. Neither alone is enough: the flange is pulled IN at the front
// (front_pull, because the belly has not come forward yet at panda Z7) so it stops
// short of the cage's front wall, while the shell section stops short of the
// flange's outward rim at the sides and back. The magnet EARS are deliberately left
// uncovered - those faces have to meet the body's magnets metal-to-metal.
//
// !!! IT IS NOT A FLAT PLATE ANY MORE !!!  cage_z0 is 7 on this host, and the
// sculpt's base is domed: at panda Z2 its silhouette has already tucked back to
// Y40.3 at X0 and Y28.7 at |X|34, while the outline above reaches panda Y42.8. A
// 7mm prism of it would stand up to 14mm proud of the belly at the bottom rear of
// the feet - the panda would look like it was standing on a slab. So the extrusion
// is INTERSECTED with the sculpt (eroded by fit_gap so it still drops in), which
// makes the cover's outer surface the panda's own base. Print it FLAT FACE DOWN,
// dome up: the top face is flat, the underside is the shallow dome.
// ---------------------------------------------------------------------------
module base_cover_2d() {
    offset(delta = -cover_inset) union() {
        // flange core rim (no ears)
        hull() for (sx = [-1, 1]) {
            translate([sx*(flange_xw - corner_r), front_yf + corner_r])
                circle(r = corner_r);
            translate([sx*(flange_xw - corner_r), 0]) circle(r = corner_r);
            translate([sx*(back_xw - corner_r), back_yb - corner_r])
                circle(r = corner_r);
        }
        // the cage's own footprint, so the back of the opening is covered too.
        // prof_fyb matters here: row 0 sets the front face back 2.22mm.
        shell_section(shell_prof[0][1], shell_prof[0][2], 0,
                      prof_fyb(shell_prof[0]));
    }
}

module base_cover() {
    difference() {
        intersection() {
            linear_extrude(cover_t) base_cover_2d();
            // The sculpt, mapped into the cover's own frame. NOTE THE Z: unlike the
            // cage, the cover is not lifted to cage_z0 - its TOP face is, so its
            // local Z0 is panda Z (cage_z0 - cover_t), which is 0. Getting this
            // wrong lands the clip on panda Z7..14, where the body is wide enough to
            // swallow the whole outline, and the intersection silently does nothing.
            rotate([0, 0, 180]) translate([0, -cage_yc, -(cage_z0 - cover_t)])
                skin_scaled(fit_gap);
        }
        for (p = cover_screws)
            translate([p[0], p[1], -eps])
                cylinder(h = cover_t + 2*eps, d = screw_clear_d);
        // microSD access, under the DFPlayer on the BACK wall. The card slides out
        // downward at the board plane, so the slot is centred there (not halfway to
        // the wall - at back_y - so_back/2 the slot ran off the cover's back edge,
        // which the base's rear chamfer pulls in to y30).
        translate([dfp_cx, back_y - so_back, -eps])
            linear_extrude(cover_t + 2*eps)
                offset(r = 2) square([cover_sd_w - 4, cover_sd_l - 4], center = true);
        // finger notch on the front edge
        translate([0, front_yf, cover_t/2])
            cube([cover_finger_w, 8, cover_t + 2*eps], center = true);
    }
}

// The LEDGE the cover screws into: a ring hugging the inside of the shell walls at
// the very bottom of the cage. Fused to the wall along its whole length (unlike a
// free-standing boss, which the open flange gives nothing to stand on), and it
// stiffens the base opening. Pilot holes are bored DOWN from its underside.
module cover_ledge() {
    difference() {
        intersection() {
            shell_solid(t, cover_ledge_h);                 // inside the walls
            translate([0, 0, -eps]) cylinder(h = cover_ledge_h + eps, r = 500);
        }
        // hollow out the middle, leaving cover_ledge_w against each wall
        translate([0, 0, -eps])
            shell_solid(t + cover_ledge_w, cover_ledge_h + 2*eps);
        // screw pilots, bored up from the base
        for (p = cover_screws)
            translate([p[0], p[1], -eps])
                cylinder(h = insert_pilot_depth, d = screw_hole_d);
    }
}

// ---------------------------------------------------------------------------
// JOYSTICK STALK CAP (separate printed part).
// Replaces the stock 26mm rubber thumb-cap. Two jobs: keep the panel hole small,
// and SPAN THE RUMP.
//
// It has to be a stalk, not a disc. The socket is deeper than the 5.95mm shaft, so
// the cap bottoms on the gimbal's shoulder - at panda Y-29.76 - and the rump skin
// is at Y-41.35, i.e. 11.6mm further out. An 8mm disc (what this was) would sit
// 3.6mm inside the body where no thumb can reach it. So: a joy_cap_barrel_d stalk
// of joy_cap_stalk, then a joy_slim_cap_d dome standing joy_cap_dome proud of the
// rump. The rump bore then only has to clear the 8.6mm stalk plus its 2.25mm swing,
// not the 16mm dome - so the dome overhangs the hole like a real thumbstick and
// hides its edge.
//
// The socket is a KEYED OVAL matching the stock shaft (4.0 across the round, 3.0
// across two flats), which press-fits AND stops the cap rotating. A drop of CA
// locks it - with 5.95mm of engagement carrying a 15mm stalk, glue it.
// Print socket-down (dome up) with a brim, or socket-up with no supports.
// ---------------------------------------------------------------------------
cap_wall   = 2.0;    // wall around the socket
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
            // socket barrel: a keyed oval so the wall stays even around the socket
            linear_extrude(sock_depth)
                oval2d(sock_w + 2*cap_wall, sock_d + 2*cap_wall);
            // then TAPER down to joy_cap_tip_d for the rest of the run. The taper
            // is what lets the rump bore be 14mm instead of 17 while the dome stays
            // 16mm, so the dome still overhangs the hole instead of dropping in.
            hull() {
                translate([0, 0, sock_depth - 0.1])
                    linear_extrude(0.1) circle(d = joy_cap_barrel_d);
                translate([0, 0, joy_cap_stalk - 0.1])
                    linear_extrude(0.1) circle(d = joy_cap_tip_d);
            }
            // flare into the dome, starting right at the skin
            translate([0, 0, joy_cap_stalk])
                cylinder(h = 1.2, d1 = joy_cap_tip_d, d2 = d);
            // domed thumb pad, standing proud of the rump
            translate([0, 0, joy_cap_stalk + 1.2])
                hull() {
                    linear_extrude(0.1) circle(d = d);
                    translate([0, 0, joy_cap_dome])
                        scale([1, 1, 0.5]) sphere(d = d - 1);
                }
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

// Separate cap for the 217.4mm uniformly enlarged body. The original joy_cap()
// stays available for the 200mm body and already-printed parts. Socket dimensions
// remain identical; the thinner neck clears the fixed 14mm bore at 11deg tilt.
module joy_cap_scaled_body() {
    sock_d = joy_shaft_d + 2*sock_clr;
    sock_w = joy_shaft_w + 2*sock_clr;
    sock_depth = joy_shaft_len + 0.5;
    neck_d = joy_scaled_cap_neck_d;
    taper_end = joy_scaled_cap_taper_end;
    stalk = joy_scaled_cap_stalk;
    d = joy_slim_cap_d;
    difference() {
        union() {
            linear_extrude(sock_depth)
                oval2d(sock_w + 2*cap_wall, sock_d + 2*cap_wall);
            hull() {
                translate([0, 0, sock_depth - 0.1])
                    cylinder(h = 0.1, d = joy_cap_barrel_d);
                translate([0, 0, taper_end - 0.1])
                    cylinder(h = 0.1, d = neck_d);
            }
            translate([0, 0, taper_end])
                cylinder(h = stalk - taper_end, d = neck_d);
            translate([0, 0, stalk])
                cylinder(h = 1.2, d1 = neck_d, d2 = d);
            translate([0, 0, stalk + 1.2]) hull() {
                cylinder(h = 0.1, d = d);
                translate([0, 0, joy_cap_dome])
                    scale([1, 1, 0.5]) sphere(d = d - 1);
            }
        }
        translate([0, 0, -eps])
            linear_extrude(sock_depth) oval2d(sock_w, sock_d);
        translate([0, 0, -eps])
            linear_extrude(1.0) oval2d(sock_w + 1.2, sock_d + 1.2);
    }
}

// ---------------------------------------------------------------------------
// ASSEMBLY
// ---------------------------------------------------------------------------
// The body cavity is clipped to an inward-eroded skin (panda.scad) to keep a solid
// belly wall at the arm-fold. Clip the cage's UPPER shell to the same eroded skin so
// it stays inside that thicker wall and still slides in. The eroded skin lives in the
// PANDA frame; map it into the cage frame by undoing the placement transform
// (translate([0,cage_yc,cage_z0]) rotate 180). Everything below cage_clip_z (the base
// flange, boards, magnets) is kept untouched.
cage_clip_z = cav_clip_z - cage_z0;   // cage-frame Z; below this we never clip.
                                      // Derived so it cannot drift from the body's
                                      // clip line (panda cav_clip_z).
module cage_upper_clip() {
    union() {
        translate([-300, -300, -300]) cube([600, 600, 300 + cage_clip_z]);
        rotate([0, 0, 180]) translate([0, -cage_yc, -cage_z0]) skin_inset();
    }
}
module cage() {
    difference() {
      intersection() {
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
            cover_ledge();          // what the base cover screws into
            // The joystick's standoffs are the ONE set that must NOT be clipped to
            // the shell: they stand on the back wall's OUTER face by design, so the
            // clip below would delete them outright.
            joystick_standoffs();
            // Every other wall-mounted boss IS clipped to the outer shell, so none
            // can protrude past a wall or float outside it (a boss in the cavity is
            // fully inside shell_solid(0), so it is kept; only stray material
            // outside the outer surface is trimmed). This is the safety net that
            // guarantees "no screw holes outside the box".
            intersection() {
                union() {
                    oled_standoffs();
                    speaker_bosses();
                    esp32_mount();
                    rtc_mount();
                    dfp_mount();
                    usb_panelmount_bosses();
                }
                shell_solid(0, H);
            }
        }
        cage_upper_clip();
      }
        oled_window_cut();
        joystick_wire_cut();
        joystick_pilot_cuts();   // deepen the outer standoffs' pilots into the wall
        speaker_throat_cut();
        magnet_pockets();
        usb_exit_cut();
    }
}

// ---------------------------------------------------------------------------
// PART SELECTOR - set `part` to export/preview individual printable pieces.
//   "cage"      the main cage body
//   "cover"     base cover - closes the cage's open underside
//   "esp32_bar" ESP32 retention bar
//   "dfp_bar"   DFPlayer retention bar
//   "joy_cap"   historical 200mm-body joystick cap
//   "joy_cap_scaled_body" longer cap for the current 217.4mm body
//   "all"       everything, small parts laid beside the cage (preview only)
// (there is no "joy_frame" any more - the KY-023 bolts straight to the back wall's
//  outer standoffs through its own four holes.)
// ---------------------------------------------------------------------------
part = "cage";

if      (part == "cage")      cage();
else if (part == "cover")     base_cover();
else if (part == "esp32_bar") esp32_bar();
else if (part == "dfp_bar")   dfp_bar();
else if (part == "joy_cap")   joy_cap();
else if (part == "joy_cap_scaled_body") joy_cap_scaled_body();
else if (part == "all") {
    cage();
    translate([0, -D - 30, 0]) base_cover();
    translate([-W, -D, 0]) esp32_bar();
    translate([-W, -D-15, 0]) dfp_bar();
    translate([-W, -D-60, 0]) joy_cap_scaled_body();
}
