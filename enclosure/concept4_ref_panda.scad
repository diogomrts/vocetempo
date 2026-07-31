// ============================================================================
// CONCEPT 4 - Organic sitting "waving" panda, based on the MakerWorld
// reference sculpt (Suesser Winkender Panda, 91 x 68 x 98 mm).
//
// This recreates the reference's cuddly seated baby-panda SILHOUETTE using
// smooth hull()-blended blobs rather than a high-poly sculpt: a big round
// head merged into a round belly, one paw raised waving, the other resting,
// seated legs with toe-bean paw pads, ears, angled eye patches with glossy
// eyes, and a little snout. The OLED is set into the belly.
//
// Scaled a touch larger than the reference so the 72 mm OLED fits the tummy.
// Massing model (solid, for look). Colours are preview-only.
// ============================================================================

include <dimensions.scad>
include <helpers.scad>

// Master scale. Reference is ~98 mm tall; we go a bit bigger for the screen.
S = 1.35;

// ---- Core body: head + belly as one smooth blended mass ------------------
belly_r  = 42 * S;                 // belly radius (chubby)
belly_cz = belly_r * 0.90;         // belly centre height (sits near ground)

head_r   = 37 * S;                 // head radius (baby: nearly belly-sized)
head_cz  = belly_cz + belly_r*0.70;// head centre height (short neck overlap)

module core_body() {
    color("white")
    hull() {
        // belly - round and slightly wider than tall for a chubby look
        translate([0, 0, belly_cz]) scale([1.08, 1.0, 0.98]) sphere(belly_r);
        // head - wide and round (not egg-shaped); slightly squashed vertically
        translate([0, 2, head_cz]) scale([1.10, 1.02, 0.92]) sphere(head_r);
    }
}

// ---- Ears: big round black discs sitting on the head corners --------------
module ears() {
    color("#1a1a1a")
    for (sx=[-1,1])
        translate([sx*head_r*0.66, 6, head_cz + head_r*0.60])
            scale([1.05,1,1.05]) sphere(head_r*0.40);
}

// ---- Eye patches: big angled black ovals (the panda signature) ------------
module eye_patches() {
    color("#1a1a1a")
    for (sx=[-1,1])
        translate([sx*head_r*0.40, -head_r*0.72, head_cz + head_r*0.06])
            rotate([90, 0, sx*18])
                scale([1.05, 1.5, 1]) sphere(head_r*0.30);
}

// ---- Glossy eyes sitting in the patches -----------------------------------
module eyes() {
    color("#0a0a0a")
    for (sx=[-1,1])
        translate([sx*head_r*0.40, -head_r*0.92, head_cz + head_r*0.02])
            sphere(head_r*0.15);
}

// ---- Snout + nose + little smile ------------------------------------------
module snout() {
    // muzzle bump
    color("white")
    translate([0, -head_r*0.86, head_cz - head_r*0.30])
        scale([1.3, 0.8, 0.9]) sphere(head_r*0.30);
    // nose
    color("#1a1a1a")
    translate([0, -head_r*1.06, head_cz - head_r*0.20])
        scale([1.3, 0.9, 1]) sphere(head_r*0.11);
}

// ---- A little hair tuft on top (reference has one) ------------------------
module hair_tuft() {
    color("white")
    translate([0, 2, head_cz + head_r*0.98])
        for (a=[-30,-10,10,30])
            rotate([a,0,0]) rotate([0,a/3,0])
                translate([0,0,4]) scale([0.5,0.5,1]) sphere(3.5*S);
}

// ---- Paw pad detail: heel + four toe beans, cut/added onto a foot/hand ----
module paw_pads(r) {
    // big heel pad
    color("white") translate([0,0,r*0.15]) scale([1,1,0.4]) sphere(r*0.45);
    // four toe beans
    color("white")
    for (i=[-1.5,-0.5,0.5,1.5])
        translate([i*r*0.34, -r*0.5, r*0.35]) scale([1,1,0.4]) sphere(r*0.16);
}

// ---- Holding arm: shoulder curving down and in to a paw that grips the
//      screen's lower corner. `sx = -1` is the left arm, `+1` the right, so
//      BOTH paws cradle the clock symmetrically (mirror of each other). ------
module holding_arm(sx) {
    ar = belly_r*0.30;
    color("#1a1a1a")
    hull() {
        // shoulder, up on the side of the belly
        translate([sx*belly_r*0.82, -belly_r*0.42, belly_cz + belly_r*0.34])
            sphere(ar);
        // paw, in near the lower corner of the screen
        translate([sx*belly_r*0.40, -belly_r*0.86, screen_z - belly_r*0.06])
            sphere(ar*0.95);
    }
    // paw gripping the screen corner, pads facing up/forward
    translate([sx*belly_r*0.40, -belly_r*0.92, screen_z - belly_r*0.06]) {
        color("#1a1a1a") scale([1,0.9,1]) sphere(ar*1.05);
        rotate([-80,0,0]) scale([sx,1,1]) paw_pads(ar*1.0);
    }
}

// ---- Seated legs splayed forward, with paw-bean soles ---------------------
module legs() {
    lr = belly_r*0.42;
    for (sx=[-1,1]) {
        color("#1a1a1a")
        translate([sx*belly_r*0.62, -belly_r*0.55, lr*0.75])
            scale([1, 1.5, 1]) sphere(lr);
        // sole facing forward with pads
        translate([sx*belly_r*0.62, -belly_r*1.15, lr*0.7])
            rotate([90,0,0]) paw_pads(lr);
    }
}

// ---- OLED window set into the belly (LOW, clear of the snout) -------------
screen_z = belly_cz - belly_r*0.05;   // sits on the tummy, below the face

module belly_window() {
    translate([0, -belly_r*0.86, screen_z])
        scale([1,3,1]) oled_window(depth = belly_r);
}

module screen_glass() {
    color("#111")
    translate([0, -belly_r*0.84, screen_z])
        rotate([90,0,0]) linear_extrude(2)
            offset(2) square([oled_active_w, oled_active_h], center=true);
}

// ---- Assembly -------------------------------------------------------------
module ref_panda() {
    difference() {
        union() {
            core_body();
            snout();
        }
        belly_window();
    }
    ears();
    eye_patches();
    eyes();
    hair_tuft();
    holding_arm(-1);   // left paw
    holding_arm(1);    // right paw
    legs();
    screen_glass();
}

ref_panda();
