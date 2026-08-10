// ============================================================================
// Vocetempo - the PANDA BODY (hollowed host for the electronics cage).
//
// Imports the original sculpt (panda/panda_original.stl - NEVER edited in
// place), scales it to ~160mm tall, hollows the interior, and cuts the
// functional openings. The sculpt was clearly designed for this: it already
// has an embossed screen rectangle and a round knob on the belly, and a big
// round head - we cut real openings through those features.
//
// Coordinate frame (AFTER the reorientation below): feet on Z=0, upright, the
// BELLY/FACE (eyes, nose, embossed screen plaque + round joystick knob, and the
// folded arms) is at +Y; the smooth back is at -Y. +X right.
//
// !!! ORIENTATION FIX !!!  In the RAW sculpt the belly/face is actually at -Y and
// the smooth back at +Y (verified by a +Y marker landing on the smooth back).
// Earlier code assumed "belly = +Y" and cut the screen/joystick openings on the
// smooth BACK by mistake. panda_raw() now reorients the sculpt (180 deg about Z +
// a Y shift) so the belly lands at +Y, matching the rest of the code. The screen
// plaque sits at panda Z~46, the knob at Z~20, both on the +Y belly.
//
// The electronics cage (cage.scad) enters from the BASE and its front face sits
// just behind the belly. This file only shapes the BODY; cage.scad is separate.
// ============================================================================

include <dimensions.scad>
include <helpers.scad>

// ---- Import + scale + REORIENT ---------------------------------------------
// STL is in normalized units (~0.96 tall); scale to panda_h mm.
// Full-res original mesh (500k tris). Requires OpenSCAD's MANIFOLD backend
// (--backend=Manifold, OpenSCAD 2023+); the old CGAL backend can't boolean this
// in reasonable time. No decimation - full detail preserved.
// The rotate+translate reflects the belly from -Y to +Y (about Y=13); the 180deg
// spin also mirrors X, which is harmless (the panda is left-right symmetric and
// the mirrored plaque text is cut away). Keep this transform in ONE place -
// anything that imports the raw sculpt must go through panda_raw().
panda_stl = "panda/panda_original.stl";

module panda_raw() {
    translate([0, 26, 0]) rotate([0, 0, 180])
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

// Speaker sound path: a CHIMNEY rising from the cavity top, through the neck, into
// the head resonator. The speaker sits on the cage TOP (panda Z ~cage_z0+cage_h=80)
// firing UP; this channel carries the sound past the neck (where the wide cavity had
// to stop at Z64 for armpit clearance) into the hollow head.
//
// CRITICAL: the OLD panda_neck_bore (a 34mm cyl at Z88..128) did NOT reach down to
// the cavity (Z64) or the speaker (Z80) - an 8-16mm plug of solid body blocked the
// sound entirely (confirmed in a section render). The chimney below OVERLAPS the
// cavity (starts at sp_z0=55, below cav_z_hi=64) so the void is continuous, and
// rises to sp_z1=118 into the head. Verified connected + breach-free by render.
// Centred at Y=sp_cy (the neck's solid mid-Y) and kept narrow enough (48x34) to stay
// inside the neck without breaching the leaning chest/chin.
sp_cy  = cage_yc;         // chimney Y centre = cage centre (speaker fires up centred)
sp_hw  = 24;              // chimney half-width (X) -> 48 wide (> grille 37.35)
sp_dep = 17;             // chimney half-depth (Y) -> 34 deep (> grille 26.80)
sp_z0  = 55;              // start BELOW the cavity top (overlap -> continuous void)
sp_z1  = 118;             // top, up inside the hollow head
module panda_neck_bore() {
    translate([0, sp_cy, sp_z0])
        linear_extrude(sp_z1 - sp_z0)
            offset(r = 4) square([2*sp_hw - 8, 2*sp_dep - 8], center = true);
}

// Head vents: small holes so the head-chamber sound escapes out the FACE. Aimed at
// the chin/lower-face area (below the nose). The head interior top is ~Z118 (chimney
// top); vents sit around Z108-116 on the face front, angled -Y->out. [UNVERIFIED
// against the exact face surface - tune once the chimney is confirmed.]
head_vent_z = 112;
module panda_head_vents() {
    for (a = [-24, -8, 8, 24])
        translate([a, 40, head_vent_z])
            rotate([90, 0, 0]) cylinder(h = 60, d = 3.2);
}

// ---- Hollowing -------------------------------------------------------------
// The body only needs to be hollow WHERE THE CAGE SITS - not a uniform thin
// shell (scaling the mesh down breaks thin features like the ears).
//
// The cavity is now built from the SAME shell_prof as the cage (dimensions.scad),
// inflated by cav_clear, then placed exactly where the cage lives (spun 180 about
// Z, set at cage_yc / cage_z0). So the cavity is guaranteed to contain the cage
// with a uniform slide-in gap, and - because the cage profile itself was solved
// to clear the panda skin - the cavity stays (just) inside the skin too, instead
// of punching the old "shoulder/armpit" holes. The speaker reaches the head via
// the neck bore, so the cavity needn't go higher than the cage.
cav_clear = 1.0;                     // slide-in gap between cage and cavity walls
module panda_cavity() {
    translate([0, cage_yc, cage_z0])
        rotate([0, 0, 180])
            // shell body inflated by cav_clear (negative shrink), extended a bit
            // BELOW its base so the underside opens into the base hatch.
            union() {
                shell_stack(shell_prof, -cav_clear);
                translate([0, 0, -(cage_z0 + 2)])
                    linear_extrude(cage_z0 + 2 + 0.1)
                        shell_section(shell_prof[0][1], shell_prof[0][2], -cav_clear);
            }
}

// ---- Base hatch: open the underside so the cage slides in ------------------
// Centred at the cage centre (cage_yc) so the DEEP cage drops straight through.
module panda_base_hatch() {
    translate([0, cage_yc, -eps])
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
