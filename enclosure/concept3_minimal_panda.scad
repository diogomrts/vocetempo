// ============================================================================
// CONCEPT 3 - "Minimalist geometric panda".
//
// A clean, modern desk-object take: a single rounded wedge body that leans
// back slightly, a spherical head, and simple cylindrical arms holding the
// screen out front like an offering. Fewer, larger forms = a stylised look and
// a very easy print. The screen tilts up toward the user for good viewing.
// ============================================================================

include <dimensions.scad>
include <helpers.scad>

// A leaning teardrop/wedge body: wide seated base tapering up to the neck.
body_w   = 84;
body_d   = 54;
body_h   = 78;

module body() {
    color("white")
    hull() {
        // wide seated base
        translate([0, 0, 12]) scale([1, 1, 0.5]) sphere(r = 40);
        // narrower shoulders, pushed back a touch (lean)
        translate([0, 8, body_h]) scale([0.8, 0.7, 0.4]) sphere(r = 40);
    }
}

head_r  = 32;
head_cz = body_h + head_r*0.4;

module head() {
    color("white") translate([0, 2, head_cz]) sphere(r = head_r);
}

module ears() {
    color("#222")
    for (sx=[-1,1])
        translate([sx*head_r*0.66, 2, head_cz + head_r*0.7]) ear(11, 10);
}

module eye_patches() {
    color("#222")
    for (sx=[-1,1])
        translate([sx*head_r*0.40, 2 - head_r*0.82, head_cz + 2])
            rotate([90,0,0]) scale([1,1.3,1]) sphere(r = head_r*0.26);
}

module nose() {
    color("#222")
    translate([0, 2 - head_r*0.98, head_cz - 12])
        rotate([90,0,0]) scale([1.2,0.8,1]) sphere(r=3.5);
}

// Two cylindrical arms reaching forward, holding a tilted screen tray.
screen_tilt = 18;   // degrees, screen faces up toward the user
screen_cz   = body_h*0.52;
screen_cy   = -body_d*0.75;

module arms() {
    color("white")
    for (sx=[-1,1])
        translate([sx*body_w*0.42, -body_d*0.3, screen_cz + 6])
            rotate([70, 0, 0]) cylinder(h = 34, r = 9);
}

// The tilted screen bezel the arms present.
module screen_tray() {
    translate([0, screen_cy, screen_cz])
        rotate([screen_tilt, 0, 0]) {
            color("white")
            rounded_box(oled_active_w + 16, 10, oled_active_h + 16, 5);
            color("#111")
            translate([0, -6, 0]) rotate([90,0,0]) linear_extrude(2)
                square([oled_active_w, oled_active_h], center=true);
        }
}

module minimal_panda() {
    body(); head(); ears(); eye_patches(); nose();
    arms(); screen_tray();
}

minimal_panda();
