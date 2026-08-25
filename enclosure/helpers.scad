// ============================================================================
// Vocetempo enclosure - shared shape helpers.
//
// Small, reusable modules so the concept files stay readable and consistent.
// ============================================================================

include <dimensions.scad>

// A box with all 12 edges rounded, sized (sx, sy, sz), centred on origin.
module rounded_box(sx, sy, sz, r = corner_r) {
    // minkowski rounds by a sphere; keep the inner cube shrunk by 2r.
    minkowski() {
        cube([max(sx - 2*r, 0.1), max(sy - 2*r, 0.1), max(sz - 2*r, 0.1)],
             center = true);
        sphere(r = r);
    }
}

// A squashed sphere (ellipsoid) with radii (rx, ry, rz), centred on origin.
module ellipsoid(rx, ry, rz) {
    scale([rx, ry, rz]) sphere(r = 1);
}

// The classic panda ear: a black disc. Drawn as a short cylinder so it reads
// in a side/ISO view. r = radius, th = thickness.
module ear(r, th) {
    rotate([90, 0, 0]) cylinder(h = th, r = r, center = true);
}

// A window cutout matching the OLED's visible active area, plus a little
// clearance. Extrude it through a wall along +Y. `depth` should exceed the
// wall thickness so the boolean cuts cleanly.
module oled_window(depth = 10) {
    translate([oled_active_dx, 0, oled_active_dy])
        rotate([90, 0, 0])
            translate([0, 0, -depth/2])
                // rounded rectangular window
                linear_extrude(height = depth)
                    offset(r = 1)
                        square([oled_active_w + fit_gap - 2,
                                oled_active_h + fit_gap - 2], center = true);
}

// A simple grille: a hex-ish grid of holes across a circle of diameter d.
// Cuts along +Y (depth through the belly wall).
// NOTE: unused by the current design (the speaker fires up a stadium throat, not
// through a round belly grille). Kept as a utility; pass an explicit `d`.
module speaker_grille(d = spk_grille_l, depth = 10, hole_d = 3, gap = 5) {
    rotate([90, 0, 0])
    translate([0, 0, -depth/2])
    linear_extrude(height = depth)
    intersection() {
        circle(d = d);
        union() {
            for (row = [-4:4]) {
                yoff = row * gap * 0.87;
                xshift = (row % 2 == 0) ? 0 : gap/2;
                for (col = [-4:4])
                    translate([col*gap + xshift, yoff]) circle(d = hole_d);
            }
        }
    }
}

// A screw boss (solid post with a pilot hole) standing up from Z=0 to height h.
// The pilot opens at the TOP (+Z) and keeps a 1mm solid base - so only use this
// where the screw arrives from the boss's +Z side (after any rotation). `pd`
// selects the pilot: screw_hole_d for M3 self-tappers (default), screw_hole_d_m2
// for the boards whose own holes only pass an M2 (OLED, RTC).
module screw_boss(h, pd = screw_hole_d) {
    difference() {
        cylinder(h = h, d = screw_boss_d);
        translate([0, 0, 1]) cylinder(h = h, d = pd);
    }
}

// ---------------------------------------------------------------------------
// SHELL CROSS-SECTION (shared by the cage box and the panda cavity).
//
// A cage_w x cage_d rectangle (front at -Y = -cage_d/2, back at +Y) whose FRONT
// corners are chamfered by `cf` and BACK corners by `cb`. `shrink` insets every
// face inward (used to carve the wall / to inflate the cavity with a negative
// value). See shell_prof in dimensions.scad for how cf/cb vary with height and
// why. Keeping this in ONE place stops the box and the cavity from drifting.
// ---------------------------------------------------------------------------
// fyb (front-Y bias) pulls ONLY the front (belly, -Y) face back toward +Y by fyb,
// independent of `shrink`. The cavity uses it to hug the cage tightly on the belly
// side (thick screen wall) while still inflating the sides/back for slide clearance.
// Default 0 keeps the cage box exactly as before.
module shell_section(cf, cb, shrink = 0, fyb = 0) {
    hw = cage_w/2 - shrink;
    fy = -cage_d/2 + shrink + fyb;    // front (belly) face, -Y (+fyb pulls it back)
    by =  cage_d/2 - shrink;          // back face, +Y
    cfx = min(max(cf - shrink, 0), hw - 1);
    cbx = min(max(cb - shrink, 0), hw - 1);
    polygon([[ hw - cfx, fy], [ hw, fy + cfx],
             [ hw, by - cbx], [ hw - cbx, by],
             [-hw + cbx, by], [-hw, by - cbx],
             [-hw, fy + cfx], [-hw + cfx, fy]]);
}

// ---------------------------------------------------------------------------
// BASE FLANGE FOOTPRINT (shared by the cage's foot and the panda's rebate).
//
// In the CAGE frame. A core rim that follows the panda's base - pulled IN at the
// FRONT (front_pull: over the flange's own Z band the belly has only reached panda
// Y44.4 around |X|27, so there is no room for an outward front rim at all), a full
// outward rim on the SIDES and at the BACK (the rump gives 10mm+ there on this
// host), narrowing at the back corners via back_xw - plus four EARS that reach out
// to the magnet positions. The ears have to be local tabs rather than a wider rim,
// or the flange would poke out of the belly between the feet.
//
// `g` grows the whole outline (the panda uses g = fit_gap so the flange slides into
// its rebate). Keeping this in ONE place is what guarantees the cage's foot and the
// body's rebate cannot drift apart.
// ---------------------------------------------------------------------------
module base_flange_2d(g = 0) {
    offset(delta = g) union() {
        hull() {
            for (sx = [-1, 1]) {
                // front corners (full rim, over the feet)
                translate([sx*(flange_xw - corner_r), front_yf + corner_r])
                    circle(r = corner_r);
                // side mid points (full side rim)
                translate([sx*(flange_xw - corner_r), 0]) circle(r = corner_r);
                // back corners, pulled IN to follow the receding rump
                translate([sx*(back_xw - corner_r), back_yb - corner_r])
                    circle(r = corner_r);
            }
        }
        // magnet ears: a stadium from the flange's edge out to each pocket centre
        for (i = [0 : len(mag_pos) - 1])
            hull() {
                translate(mag_pos[i])      circle(r = mag_ear_r);
                translate(mag_ear_root[i]) circle(r = mag_ear_r);
            }
    }
}

// The full SOLID shell body (filled, not hollow) built by lofting the chamfered
// section between successive profile rows. `shrink` insets it (0 = outer surface,
// wall thickness = inner shrink). Spans Z from profile[0] to the last row.
// Each profile row is [z, cf, cb] or [z, cf, cb, fyb]. The optional 4th column is a
// PER-HEIGHT FRONT SETBACK: it pulls the belly-side face back by that much at that
// height, on top of whatever `fyb` the caller passes.
//
// WHY IT EXISTS. Without it the front is one flat plane, so it has to clear the
// WORST height anywhere on the cage - and the worst height is the arm pinch at the
// very top. That couples cage height to screen depth directly: on the 200mm host, a
// cage tall enough for the ESP32 (top at panda Z86) forces the front plane back to
// Y29.6 and buries the screen ~31mm deep, while a cage short enough to keep the
// front at Y45 cannot fit the ESP32 at all. With a setback the front plate stays
// forward through the OLED's span and steps back only above the arms, which is the
// change that lets both fit at once.
function prof_fyb(row) = len(row) > 3 ? row[3] : 0;

module shell_stack(profile, shrink = 0, fyb = 0) {
    seg_eps = 0.02;
    for (i = [0 : len(profile) - 2]) {
        z0 = profile[i][0];   z1 = profile[i+1][0];
        hull() {
            translate([0, 0, z0]) linear_extrude(seg_eps)
                shell_section(profile[i][1],   profile[i][2],   shrink,
                              fyb + prof_fyb(profile[i]));
            translate([0, 0, z1]) linear_extrude(seg_eps)
                shell_section(profile[i+1][1], profile[i+1][2], shrink,
                              fyb + prof_fyb(profile[i+1]));
        }
    }
}
