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
//
// The opening is the lit area (55 x 28) + fit_gap with GENEROUSLY ROUNDED CORNERS
// (oled_corner_r). Mesh scan of the belly: the feet start at X+-28 / Z<=39 and the
// folded paws come inward to X+-20..22 over Z44..58. A plain rectangle speared its
// bottom corners into the feet and its side edges into the paws. Rounding the
// corners hard (keeping the full 55x28 straight-edge span, so no clock pixels are
// lost - the corners of the lit area are blank) lifts the corners clear of the feet
// and the upper paw tips; the remaining side overlap with the paws is unavoidable
// (they sit in front of the outer screen edge) but is now a clean rounded cut.
//
// MOUTH BEVEL (oled_bevel_*): the sculpted screen plaque is only ~40mm wide but the
// OLED's lit area is 55.4, so the window HAS to cut through the folded paws - their
// tips sit right in front of the screen's outer 8mm. Raycast of the sculpt along the
// window outline: the plaque face is at Y~53.4 while the paw tips reach Y 62.95, so
// a plain prism sliced them with a ~10mm-deep vertical wall and a knife-sharp
// crescent edge (plus a razor fin where the plaque's bezel groove was clipped).
// The fix is a countersink that only bites where the skin BULGES FORWARD: the cut
// keeps the exact aperture behind oled_bevel_y0 (=58, behind every part of the
// plaque, so no pixels are lost) and flares outward from there, reaching
// oled_bevel_c at oled_bevel_y1. The flare is therefore inert over the plaque, the
// belly and the feet (all behind Y58) and turns the paw slice into a ~40 deg bevel.
// The bevel is also clipped to Z >= oled_bevel_z0 so it only ever touches the PAWS.
// Without that clip it reached the FEET too: the window's bottom corners pass within
// ~2mm of the legs, whose fronts bulge to Y 64..67.7, so the flare scooped up to 5mm
// out of each shin. At Z40 nothing within reach of the flare is in front of Y58 (the
// belly there is at Y~51-52), so the clip edge itself is invisible.
oled_corner_r  = 8;
oled_bevel_y0  = 58;   // bevel starts here; behind this the aperture is exact
oled_bevel_y1  = 65;   // ... fully open by here (past the belly's front peak ~67)
oled_bevel_c   = 5;    // outward offset at y1 -> ~35 deg wall on the paw tips
oled_bevel_z0  = 40;   // only bevel above this Z (paws yes, feet/legs no)
// The aperture outline: a w x h box with its corners rounded hard INWARD, so the
// straight-edge spans stay the full w and h (no pixels lost - the lit area's corners
// are blank). `g` grows it outward for the bevel.
module oled_outline(w, h, g = 0) {
    offset(delta = g)
        offset(r = oled_corner_r) offset(delta = -oled_corner_r)
            square([w, h], center = true);
}
module panda_oled_cut() {
    w = oled_active_w + fit_gap;            // 55.4 - full lit width kept at mid-height
    h = oled_active_h + fit_gap;            // 28.4 - full lit height kept at mid-width
    // NB screen_cz IS the lit-area centre already (dev_oled_pz); do NOT add
    // oled_active_dy here. That offset only converts PCB centre <-> lit centre and
    // is applied on the CAGE side (cage.scad's oled_cz / az). Adding it here too
    // lifted the whole window 3.1mm above the actual screen, which both misaligned
    // the aperture and ran its top corner arc straight along the armpit crease at
    // Z~63, leaving a razor lip that broke into two pin-holes.
    translate([oled_active_dx, 0, screen_cz]) {
        // 1. the aperture itself: exact size, starting OUTSIDE the belly and running
        //    back through the body. rotate([90,0,0]) makes linear_extrude (+Z) point
        //    in -Y, i.e. INTO the body. This must span the full depth on its own: the
        //    bevel below is clipped in Z, so it cannot be relied on to open the mouth.
        translate([0, belly_face_y, 0])
            rotate([90, 0, 0])
                linear_extrude(height = cut_depth)
                    oled_outline(w, h);
        // 2. the mouth bevel: a linear flare from the aperture at y0 out to +c at y1,
        //    then straight on out past the belly. Both outlines are convex, so hull()
        //    gives exactly the tapered prism. Clipped to Z >= oled_bevel_z0 (panda
        //    frame) so it shapes the paw tips and leaves the legs alone.
        intersection() {
            union() {
                hull() {
                    translate([0, oled_bevel_y0, 0]) rotate([90, 0, 0])
                        linear_extrude(0.01) oled_outline(w, h);
                    translate([0, oled_bevel_y1, 0]) rotate([90, 0, 0])
                        linear_extrude(0.01) oled_outline(w, h, oled_bevel_c);
                }
                translate([0, belly_face_y, 0]) rotate([90, 0, 0])
                    linear_extrude(belly_face_y - oled_bevel_y1)
                        oled_outline(w, h, oled_bevel_c);
            }
            translate([-100, 0, oled_bevel_z0 - screen_cz]) cube([200, 200, 200]);
        }
    }
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

// Head resonator: HOLLOW the head so the speaker chamber can actually resonate.
// Mesh scan of the head this session: skin X +-51, back Y~-29, crown ~Z150, face
// front Y~62-68 (nose tip 75). An ELLIPSOID void centred (0, 10, 114) with radii
// (38, 30, 28) leaves >=8mm wall everywhere (verified: chamber-minus-skin renders
// empty - no breach of face, ears or crown) and OVERLAPS the neck chimney top
// (Z118) so the void is continuous: speaker -> chimney -> head chamber -> vents.
head_c = [0, 10, 114];
head_r = [38, 30, 28];
module panda_head_cavity() {
    translate(head_c) scale(head_r) sphere(r = 1);
}

// Head vents: the speaker grille sits in the STIPPLED INNER DISH of each ear (the
// sculpted "inner ear"), venting the head resonator so sound emits FROM THE EARS.
// An earlier version drilled 2x3 holes on the ear's outer-lower CORNER, which read
// as damage rather than a grille; the dish is the only surface on the ear that is
// meant to look perforated.
//
// Mesh survey of the sculpt (a density + front/back surface scan of the 500k mesh,
// run SEPARATELY PER EAR because the stipple is randomised per side, then the two
// masks were intersected so one hole layout is valid on BOTH ears):
//   * the inner dish is a RECESS ~1.3mm behind the ear's rim: its surface lies at
//     Y 19.8..21.7 where the surrounding rim is at Y ~22.0. It is identifiable both
//     by that step and by its stipple (5-10x the triangle density of smooth skin).
//   * shape: a TILTED OVAL, centre (X 40.1, Z 146.7), major axis -46.2 deg in the
//     XZ plane (top tilts inboard), ~20mm long x ~13.8mm wide.
//   * stock behind it: the ear's rear skin is at Y 8.6..11.6, so ~10-11.5mm to work
//     in. CAVEAT: the stipple patch is a SEPARATE OVERLAPPING SHELL in the sculpt,
//     so it also emits rear-facing triangles at Y~21 - only rear-facing geometry
//     below Y 15 is the ear's real back skin.
//
// The vent is therefore a real grille rather than a few blind pokes:
//   13 bores (hex 4/5/4, d2.4 @ 3.8 pitch, the grid rotated onto the dish's major
//   axis) -> a shared PLENUM milled just under the skin -> 3 ducts that tunnel
//   inboard and down into the head void (which tops out at Z142, X+-14).
// Open areas are matched: grille 58.8mm^2 vs duct throat ~54.6mm^2 (the 3 ducts
// overlap into one ~12x5 stadium throat).
// Verified: >=1.75mm of stippled skin in front of the plenum, >=1.99mm to the ear's
// rear skin, >=1.5mm of wall around every duct along its whole run, and all three
// ducts terminate INSIDE panda_head_cavity().
ear_cx      = 40.13;   // inner-dish centre, panda X (right ear; left is mirrored)
ear_cz      = 146.73;  // inner-dish centre, panda Z
ear_ang     = -46.2;   // dish major axis, degrees in the XZ plane
ear_hole_d  = 2.4;     // grille hole diameter
ear_pitch   = 3.8;     // hex pitch -> 1.4mm webs between holes
ear_pl_y1   = 18.0;    // plenum FRONT face (leaves >=1.75mm of stippled skin)
ear_pl_y0   = 13.5;    // plenum REAR face  (leaves >=1.99mm to the ear's back skin)
ear_pl_r    = 1.6;     // plenum overhang beyond the hole-centre hull
ear_duct_d  = 5.0;     // duct bore
ear_duct_y  = 15.8;    // ducts leave the plenum at its mid-depth
ear_duct_y2 = 10.0;    // ... and meet the head void at this Y (the void's mid-Y)
// duct [X,Z] start (inside the plenum footprint) -> [X,Z] end (inside the head void)
ear_ducts   = [[[34, 148  ], [10, 132]],
               [[37, 144.5], [12, 129]],
               [[40, 141  ], [14, 126]]];

// Hex 4/5/4 cluster in the dish's own (u,v) frame; u runs along the major axis.
// Rows +-1 are offset by half a pitch and one hole shorter, which is what makes the
// cluster's outline echo the oval instead of squaring off inside it.
ear_holes = [ for (i = [-1, 0, 1])
                  each [ for (j = [-2 : (i == 0 ? 2 : 1)])
                             [ j*ear_pitch + (i == 0 ? 0 : ear_pitch/2),
                               i*ear_pitch*sin(60) ] ] ];

module cyl_between(p1, p2, d) {
    v  = p2 - p1;
    L  = norm(v);
    az = atan2(v[1], v[0]);
    pol = acos(v[2] / L);
    translate(p1)
        rotate([0, 0, az]) rotate([0, pol, 0])
            cylinder(h = L, d = d);
}

// One ear's vent, built for the RIGHT ear (+X); the left is a mirror (the body is
// symmetric in X and the hole layout was solved against BOTH ears' dishes).
module ear_vent() {
    // Dish frame: local (u, Y, v) -> panda (X, Y, Z). rotate([0,-ear_ang,0]) spins
    // the XZ plane onto the dish's major axis and leaves Y - the bore axis - alone.
    translate([ear_cx, 0, ear_cz]) rotate([0, -ear_ang, 0]) {
        // Visible grille: bores from OUTSIDE the dish (Y24) down into the plenum.
        translate([0, 24, 0]) rotate([90, 0, 0])        // extrude -> -Y
            linear_extrude(24 - (ear_pl_y0 + 1))
                for (p = ear_holes)
                    translate(p) circle(d = ear_hole_d, $fn = 24);
        // Plenum: one shallow cavity joining every bore, just under the skin.
        translate([0, ear_pl_y1, 0]) rotate([90, 0, 0])
            linear_extrude(ear_pl_y1 - ear_pl_y0)
                hull() for (p = ear_holes)
                    translate(p) circle(r = ear_pl_r, $fn = 24);
    }
    // Ducts: plenum -> head resonator. In panda coords, NOT the dish frame.
    for (d = ear_ducts)
        cyl_between([d[0][0], ear_duct_y,  d[0][1]],
                    [d[1][0], ear_duct_y2, d[1][1]], ear_duct_d);
}

module panda_head_vents() {
    ear_vent();
    mirror([1, 0, 0]) ear_vent();
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
cav_clear     = 1.0;                 // slide-in gap on the SIDES/BACK (easy insertion)
cav_front_gap = 0.35;                // MUCH tighter gap on the BELLY-FRONT face, so the
                                     // wall over/above the screen stays thick. The old
                                     // uniform 1.0 inflated the cavity into the belly
                                     // skin at the arm-fold -> pin-holes. fyb below pulls
                                     // just the front face back to leave only this gap.
cav_fyb = cav_clear - cav_front_gap; // front-face bias (0.65): front hugs the cage
module panda_cavity() {
    translate([0, cage_yc, cage_z0])
        rotate([0, 0, 180])
            // shell body inflated by cav_clear (negative shrink) on sides/back, but the
            // front face pulled back by cav_fyb; extended below its base into the hatch.
            union() {
                shell_stack(shell_prof, -cav_clear, cav_fyb);
                translate([0, 0, -(cage_z0 + 2)])
                    linear_extrude(cage_z0 + 2 + 0.1)
                        shell_section(shell_prof[0][1], shell_prof[0][2], -cav_clear, cav_fyb);
            }
}

// GUARANTEED belly wall: the arm-fold makes the skin graze the cavity right above
// the screen corners, leaving tangent slivers that no simple gap tweak removes. So
// we CLIP the cavity (above Z=cav_clip_z, i.e. the upper belly only - the base and
// hatch below are untouched) to a copy of the skin scaled inward, so the cavity
// physically cannot come within ~cav_min of the outer surface. The scale-toward-axis
// is a cheap stand-in for a true 3D inward offset; it erodes ~cav_min at the belly
// radius, which is all we need at the pinch. Verified: cage still seats (cage-in-body
// collision render is empty).
cav_min     = 1.4;          // min wall the clip guarantees around the arm-fold
skin_cy     = 15;           // approx body Y axis to scale the skin toward
cav_clip_z  = 50;           // only clip the UPPER belly (leave the base/hatch alone)
module skin_inset() {
    k = 1 - cav_min/34;     // ~cav_min erosion at the ~34mm belly/pinch radius
    translate([0, skin_cy, 0]) scale([k, k, 1]) translate([0, -skin_cy, 0])
        panda_raw();
}
module panda_cavity_safe() {
    difference() {
        panda_cavity();
        // remove any cavity that (above the clip line) sits outside the eroded skin
        difference() {
            translate([-300, -300, cav_clip_z]) cube([600, 600, 400]);
            skin_inset();
        }
    }
}

// ---- Shorten the folded arms so the screen never slices them ----------------
// The sculpted plaque is only ~40mm wide but the OLED's lit area is 55.4, so the
// window's side edges used to cut ~8mm into each paw, leaving a 10mm-deep slice.
// Bevelling that only softened it. Instead SHORTEN the arms: intersect the body
// with a copy of the SCULPT ITSELF shifted outboard by arm_shift. Where the shifted
// copy is less proud than the original the arm is trimmed; where it is more proud
// nothing happens. So each arm's inboard flank retreats by arm_shift wearing its own
// natural end shape, and - because the two surfaces cross at the arm's crest - the
// blend is automatically TANGENTIAL (no crease, no flat facet, no step).
//
// THE SHIFT MUST RUN ALONG THE ARM'S OWN AXIS (outboard AND up), not straight
// outboard. The arm runs diagonally from the shoulder (X-40, Z68) down to the paw
// (X-20, Z50), so sliding it back along that axis slides its flanks ALONG
// THEMSELVES: nothing gets eroded sideways, the armpit crease and the arm/belly
// crease survive, and the tip stays a rounded lobe. arm_shift is 12mm along that
// axis, which pulls the paw clear of the aperture (wall at the window edge drops
// from 9.5mm to 1.5..2.4mm) while still reading as an arm.
//
// Two earlier versions are worth not repeating:
//  * A straight-outboard shift erodes the inboard flank along its whole length and
//    opens an 8mm trench from the shoulder down to the screen.
//  * Fixing that with a floor plane (only trim skin proud of Y54) is worse: where
//    the shifted skin falls below the floor the cut bottoms out FLAT, leaving a
//    plateau up to 9mm wide with a 4mm cliff on its inboard side where the belly
//    drops into the armpit. That plateau is the "pointy beak" above the paw.
// The axis shift needs no such floor - arm_ymin is only a deep guard that nothing
// ever reaches, so there is no artificial flat anywhere on the result.
//
// The zone is a plain box: measured removal is 0 on every face of it (0 outboard of
// X-60, 0 above Z76 where the arm has merged into the shoulder, and below Z38 only
// inside the aperture, which is cut away anyway). The BACK never trims - the copy is
// sampled nearer the centre, where the body is thicker. Only the -X arm is built;
// the +X arm is its mirror.
arm_shift = [-8.9, 0, 8.0];   // 12mm, along the arm's axis (outboard + up)
arm_ymin  = 46;               // deep guard; the trim never reaches it
arm_zone  = [[-60, 38], [-18, 76]];    // [[x0,z0],[x1,z1]] of the trim zone
module arm_trim_pass(shift, ymin, zone) {
    difference() {
        translate([zone[0][0], ymin, zone[0][1]])
            cube([zone[1][0] - zone[0][0], 120, zone[1][1] - zone[0][1]]);
        translate(shift) panda_raw();                 // outboard for the -X arm
    }
}
module arm_trim() {
    arm_trim_pass(arm_shift, arm_ymin, arm_zone);
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

// ---- Base rebate + the body half of the magnet pairs ------------------------
// A counterbore around the hatch that receives the cage's base flange. Before this
// the flange had nowhere to seat - it was the same width as the hatch on the sides,
// so it just slipped in, and its outer ring fouled the body above the hatch (the
// "flange proud spots" in the breach fit-check). Now the flange drops into the
// rebate and lands on its ceiling, which is also where the magnets meet.
//
// Depth = cage_z0 + rim_h, i.e. exactly the flange's top face, so the ceiling IS the
// mating plane. Footprint = base_flange_2d() + fit_gap, shared with cage.scad. The
// cage is placed with translate([0,cage_yc,cage_z0]) rotate 180, so the same spin is
// applied here to put the footprint in panda coordinates.
rebate_h = cage_z0 + rim_h;      // panda Z of the rebate ceiling = flange top (6.2)
module panda_base_rebate() {
    translate([0, cage_yc, -eps])
        rotate([0, 0, 180])
            linear_extrude(rebate_h + eps)
                base_flange_2d(fit_gap);
}

// The body's 4 magnets: pockets in the rebate's CEILING, opening downward, so each
// magnet's face sits flush at rebate_h and meets the flange magnet metal-to-metal.
// Verified by raycast that all four sit in solid body with >=1.5mm of wall: the
// cavity's front face stops at Y 40.35 (front pair is at Y 50) and the cavity is only
// 77mm wide (side pair is at |X| 43).
module panda_magnet_pockets() {
    translate([0, cage_yc, 0])
        rotate([0, 0, 180])
            for (p = mag_pos)
                translate([p[0], p[1], rebate_h - eps])
                    cylinder(h = magnet_t + eps, d = magnet_d - 2*magnet_fit);
}

// ---- Assembly --------------------------------------------------------------
module panda_body() {
    difference() {
        panda_raw();
        panda_cavity_safe();
        panda_head_cavity();
        panda_oled_cut();
        panda_joystick_cut();
        panda_neck_bore();
        panda_head_vents();
        panda_base_hatch();
        panda_base_rebate();
        panda_magnet_pockets();
        arm_trim();
        mirror([1, 0, 0]) arm_trim();
    }
}

panda_body();
