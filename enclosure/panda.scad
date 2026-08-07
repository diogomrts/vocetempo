// ============================================================================
// Vocetempo - the PANDA BODY (hollowed host for the electronics cage).
//
// Imports the original sculpt (panda/panda_original.stl - NEVER edited in
// place), scales it to ~160mm tall, hollows the interior, and cuts the
// functional openings. The sculpt was clearly designed for this: it already
// has an embossed screen rectangle and a round knob on the belly, and a big
// round head - we cut real openings through those features.
//
// Coordinate frame (after scale): feet on Z=0, upright. The BELLY/FACE is +Y
// (it bulges to +Y; the back at -Y is smooth). +X right.
//
// The electronics cage (cage.scad) enters from the BASE and its front face sits
// just behind the belly. This file only shapes the BODY; cage.scad is separate.
// ============================================================================

include <dimensions.scad>
include <helpers.scad>

// ---- Import + scale --------------------------------------------------------
// STL is in normalized units (~0.96 tall); scale to panda_h mm.
// Full-res original mesh (500k tris). Requires OpenSCAD's MANIFOLD backend
// (--backend=Manifold, OpenSCAD 2023+); the old CGAL backend can't boolean this
// in reasonable time. No decimation - full detail preserved.
panda_stl = "panda/panda_original.stl";

module panda_raw() {
    scale(panda_scale) import(panda_stl, convexity = 10);
}

// ---- Opening placements (belly is +Y) --------------------------------------
// Placements come from dimensions.scad (single source of truth). Mesh analysis
// this session: sculpted screen plaque centres at panda Z~40, knob at panda Z~20
// (~20mm apart). The 28mm-tall OLED window + slim-cap joystick need >=28mm centre
// spacing, so we spread them symmetrically about the feature midpoint (Z30) ->
// OLED window panda Z44 (dev_oled_pz), joystick panda Z16 (dev_joy_pz). Each still
// lands on its sculpted feature.
// Cut solids START OUTSIDE the belly (+Y) and extrude back (-Y) through the body.
belly_face_y   = 72;             // outside the belly (peak ~67) so cuts punch through
screen_cz      = dev_oled_pz;    // OLED window centre (panda Z, on the screen plaque)
knob_cz        = dev_joy_pz;     // joystick centre (panda Z, on the knob)
cut_depth      = 80;             // how far a cut solid reaches back from the surface

// OLED window: cut the lit-area rectangle through the belly. The cut solid
// starts OUTSIDE the belly (+Y) and extrudes back (-Y) through the body.
module panda_oled_cut() {
    // rotate([90,0,0]) makes linear_extrude (+Z) point in -Y, i.e. INTO the body,
    // starting just outside the belly at +Y=belly_face_y.
    translate([oled_active_dx, belly_face_y, screen_cz + oled_active_dy])
        rotate([90, 0, 0])                  // extrude -> -Y (into the body)
            linear_extrude(height = cut_depth)
                offset(r = 2)
                    square([oled_active_w + fit_gap, oled_active_h + fit_gap],
                           center = true);
}

// Joystick opening: sized to the SLIM PRINTED CAP (joy_panel_open ~20mm), not
// the stock 26mm cap. A gentle cone (flare out a touch toward the belly) clears
// the small d-pad swing. Much tidier than the stock-cap cone.
module panda_joystick_cut() {
    r_belly = joy_panel_open/2 + fit_gap;
    r_deep  = joy_panel_open/2;
    translate([0, belly_face_y, knob_cz])
        rotate([90, 0, 0])                 // cone axis -> -Y
            cylinder(h = cut_depth, r1 = r_belly, r2 = r_deep);
}

// Speaker sound path: a bore up the NECK from the body cavity into the head, so
// sound reaches the head resonator. Vent holes in the head let it out.
neck_z = 108;             // approx neck height where body meets head
module panda_neck_bore() {
    translate([0, 8, neck_z])
        cylinder(h = 40, d = 34, center = true);   // generous throat
}

// Head vents: a few small holes low on the face/chin so head sound escapes.
module panda_head_vents() {
    for (a = [-30, -10, 10, 30])
        rotate([0, 0, 0])
        translate([a*0.9, belly_face_y + 2, 118])
            rotate([90,0,0]) cylinder(h = 20, d = 3);
}

// ---- Hollowing -------------------------------------------------------------
// The body only needs to be hollow WHERE THE CAGE SITS - not a uniform thin
// shell (scaling the mesh down breaks thin features like the ears). So the
// cavity is a rounded prism sized to the cage + wiring clearance.
//
// CRITICAL FIX (this session - the "shoulder holes"): the old cavity was a tall
// box (cage_h+6, reaching panda Z~94) at full 81mm width the whole way up. Above
// the belly peak (~Z35) the torso NARROWS and the folded arms leave a thin-walled
// ARMPIT gap (chest surface recedes to Y~-15..-36 there). A full-width/full-height
// box punched through that thin armpit wall -> orange holes at the shoulders, and
// its front-top corner also pierced the chest below the chin.
//
// FIX: a TAPERED cavity - full size low down (houses the wide OLED + boards), then
// tapering NARROWER and shallower toward the top so the walls stay inside the
// narrowing torso and never reach the armpit gaps. Verified hole-free by render.
// The OLED PCB's two TOP corners (bare PCB, header is on the bottom edge) clip the
// tapered top by ~2mm and get a small chamfer at assembly (see docs/ASSEMBLY).
// The speaker still reaches the head via the neck bore, so the cavity needn't go
// higher than the cage.
cav_clear   = 3;          // clearance around the cage inside the cavity
cav_z_lo    = -1;         // start just below the base plane (open hatch)
cav_z_mid   = 46;         // full-width up to here (clears OLED lit area + boards)
cav_z_hi    = 64;         // tapered top (~OLED PCB top; below the armpit thin wall)
cav_lo_hw   = (cage_w + 2*cav_clear)/2;   // lower half-width (X) ~40.5
cav_lo_dep  = cage_d + 2*cav_clear;       // lower depth  (Y)  ~44
cav_up_hw   = 31;         // upper half-width (X) - armpit-safe [render-tuned]
cav_up_dep  = 31;         // upper depth (Y) - armpit-safe      [render-tuned]
cav_cy      = 2;          // cavity Y centre (cage sits slightly forward)
module panda_cavity() {
    // hull a wide lower slab into a narrower upper slab -> smooth inward taper.
    hull() {
        translate([0, cav_cy, cav_z_lo])
            linear_extrude(cav_z_mid - cav_z_lo)
                offset(r = 4) square([2*cav_lo_hw - 8, cav_lo_dep - 8], center = true);
        translate([0, cav_cy, cav_z_hi - 0.1])
            linear_extrude(0.1)
                offset(r = 4) square([2*cav_up_hw - 8, cav_up_dep - 8], center = true);
    }
}

// ---- Base hatch: open the underside so the cage slides in ------------------
module panda_base_hatch() {
    // rectangular opening in the base matching the cage footprint + clearance
    translate([0, 0, -eps])
        linear_extrude(height = cage_z0 + 2)
            offset(r = 2)
                square([cage_w + 2, cage_d + 2], center = true);
}
eps = 0.01;

// ---- Assembly --------------------------------------------------------------
module panda_body() {
    difference() {
        panda_raw();
        panda_cavity();
        panda_oled_cut();
        panda_joystick_cut();
        panda_neck_bore();
        panda_base_hatch();
    }
}

panda_body();
