// ============================================================================
// CONCEPT 2 - "Rounded-box panda" (print-friendly).
//
// A stouter, boxier sitting panda built from rounded boxes instead of spheres.
// Flat front and back faces make it far easier to print (split front/back
// shell, no big overhangs) and give a large flat belly for the OLED. Short
// arms rest at the sides framing the screen; a rounded head with ears sits on
// top. This trades some cuteness for manufacturability.
// ============================================================================

include <dimensions.scad>
include <helpers.scad>

body_w = 96;    // belly width  (X)
body_d = 46;    // belly depth  (Y)
body_h = 92;    // belly height (Z)
body_cz = body_h/2;

head_w = 70;
head_d = 42;
head_h = 52;
head_cz = body_h + head_h*0.32;

module body() {
    color("white") translate([0,0,body_cz]) rounded_box(body_w, body_d, body_h, 14);
}

module head() {
    color("white") translate([0,0,head_cz]) rounded_box(head_w, head_d, head_h, 16);
}

module ears() {
    color("#222")
    for (sx=[-1,1])
        translate([sx*head_w*0.34, 0, head_cz + head_h*0.42])
            ear(13, 12);
}

module eye_patches() {
    color("#222")
    for (sx=[-1,1])
        translate([sx*head_w*0.24, -head_d*0.46, head_cz + 3])
            rotate([90,0,0]) scale([1,1.4,1]) cylinder(h=4, r=9, center=true);
}

module nose() {
    color("#222")
    translate([0, -head_d*0.5, head_cz - 12])
        rotate([90,0,0]) scale([1.3,0.9,1]) cylinder(h=4, r=4, center=true);
}

// Short arms that rest at the sides, hands meeting near the screen's lower edge.
module arms() {
    color("white")
    for (sx=[-1,1])
        translate([sx*body_w*0.46, -body_d*0.36, body_cz - 4])
            rotate([0,0,sx*-18])
                scale([1,1,1.5]) rounded_box(20, 26, 30, 9);
}

// Feet at the front base.
module legs() {
    color("white")
    for (sx=[-1,1])
        translate([sx*body_w*0.30, -body_d*0.62, 12])
            rotate([90,0,0]) scale([1.3,1,0.7]) cylinder(h=20, r=14, center=true);
}

// OLED window on the belly, framed by the arms.
module belly_with_window() {
    difference() {
        body();
        translate([0, -body_d*0.5, body_cz + 6])
            oled_window(depth = body_d);
    }
}

module screen_glass() {
    color("#111")
    translate([0, -body_d*0.5 + 1, body_cz + 6])
        rotate([90,0,0]) linear_extrude(2)
            offset(2) square([oled_active_w, oled_active_h], center=true);
}

module box_panda() {
    belly_with_window();
    head(); ears(); eye_patches(); nose();
    arms(); legs(); screen_glass();
}

box_panda();
