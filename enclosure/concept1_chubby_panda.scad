// ============================================================================
// CONCEPT 1 - "Chubby sitting panda" cradling the OLED.
//
// A round, cuddly panda sitting on its bottom. The big belly is the main body
// (holds the electronics); the OLED sits in a recessed window on the belly,
// and two stubby arms/paws curve up in front to "hold" the screen. The head
// sits on top with the two classic black ears. Legs splay forward at the base.
//
// This is a CONCEPT MASSING model - solid shapes to judge the look. It is not
// yet split into printable shells or hollowed; we do that once a concept is
// chosen. Colours are just for preview clarity.
// ============================================================================

include <dimensions.scad>
include <helpers.scad>

// Overall size is driven by needing the OLED (72x40) on the belly with margin.
belly_rx = 55;   // belly half-width
belly_ry = 42;   // belly half-depth
belly_rz = 52;   // belly half-height
belly_cz = belly_rz;         // belly centre height (sits on ground)

head_r   = 34;               // head radius
head_cz  = belly_cz + belly_rz*0.55 + head_r*0.5;  // head centre height

module body() {
    color("white") ellipsoid(belly_rx, belly_ry, belly_rz);
}

module head() {
    color("white")
    translate([0, 0, head_cz]) sphere(r = head_r);
}

module ears() {
    color("#222")
    for (sx = [-1, 1])
        translate([sx * head_r*0.62, 0, head_cz + head_r*0.72])
            ear(head_r*0.34, 10);
}

module eye_patches() {
    color("#222")
    for (sx = [-1, 1])
        translate([sx * head_r*0.42, -head_r*0.80, head_cz + head_r*0.10])
            rotate([90,0,0]) scale([1, 1.35, 1]) sphere(r = head_r*0.24);
}

module nose() {
    color("#222")
    translate([0, -head_r*0.96, head_cz - head_r*0.18])
        rotate([90,0,0]) scale([1.2,0.8,1]) sphere(r = 4);
}

// Two stubby arms that curve up in front of the belly to cradle the screen.
module arms() {
    color("white")
    for (sx = [-1, 1])
        translate([sx * belly_rx*0.72, -belly_ry*0.55, belly_cz + belly_rz*0.15])
            rotate([0, sx*20, 0])
                scale([1, 1.1, 1.6]) sphere(r = 16);
}

// Splayed legs/feet at the front base.
module legs() {
    color("white")
    for (sx = [-1, 1])
        translate([sx * belly_rx*0.5, -belly_ry*0.7, 14])
            rotate([-70, 0, 0]) scale([1.2, 1, 1.8]) sphere(r = 15);
    // black paw pads on the sole
    color("#222")
    for (sx = [-1, 1])
        translate([sx * belly_rx*0.5, -belly_ry*1.15, 12])
            rotate([90,0,0]) scale([1,1,0.4]) sphere(r = 8);
}

// The OLED window recessed into the belly front, positioned where the arms hug.
module oled_pocket() {
    translate([0, -belly_ry*0.62, belly_cz + belly_rz*0.02]) {
        // Screen glass shown as a dark rectangle for preview.
        color("#111")
        translate([0, 0, 0])
            rotate([90,0,0])
                linear_extrude(2)
                    offset(2) square([oled_active_w, oled_active_h], center=true);
    }
}

// Cut the actual window opening through the belly for the render-with-hole view.
module belly_with_window() {
    difference() {
        body();
        // window opening
        translate([0, -belly_ry*0.62, belly_cz + belly_rz*0.02])
            scale([1, 3, 1])   // stretch in Y so it punches through the curve
                oled_window(depth = belly_ry);
    }
}

// ---- Assembly -------------------------------------------------------------
module chubby_panda() {
    belly_with_window();
    head();
    ears();
    eye_patches();
    nose();
    arms();
    legs();
    oled_pocket();
}

chubby_panda();
