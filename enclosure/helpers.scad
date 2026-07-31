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
module speaker_grille(d = spk_grille_d, depth = 10, hole_d = 3, gap = 5) {
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
