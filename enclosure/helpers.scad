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
module screw_boss(h) {
    difference() {
        cylinder(h = h, d = screw_boss_d);
        translate([0, 0, 1]) cylinder(h = h, d = screw_hole_d);
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

// The full SOLID shell body (filled, not hollow) built by lofting the chamfered
// section between successive profile rows. `shrink` insets it (0 = outer surface,
// wall thickness = inner shrink). Spans Z from profile[0] to the last row.
module shell_stack(profile, shrink = 0, fyb = 0) {
    seg_eps = 0.02;
    for (i = [0 : len(profile) - 2]) {
        z0 = profile[i][0];   z1 = profile[i+1][0];
        hull() {
            translate([0, 0, z0]) linear_extrude(seg_eps)
                shell_section(profile[i][1],   profile[i][2],   shrink, fyb);
            translate([0, 0, z1]) linear_extrude(seg_eps)
                shell_section(profile[i+1][1], profile[i+1][2], shrink, fyb);
        }
    }
}
