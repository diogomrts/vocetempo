// ============================================================================
// Vocetempo - the PANDA BODY (hollowed host for the electronics cage).
//
// Imports the sculpt (panda/panda_original_without_embosses.stl - NEVER edited in
// place), scales it to 200mm tall, hollows the interior, and cuts the
// functional openings. This host is the DE-EMBOSSED variant: the sculpted screen
// plaque and belly knob have been shaved off, so the belly is a clean curved
// surface and the openings are placed by measurement rather than by feature.
//
// Coordinate frame (AFTER the reorientation below): feet on Z=0, upright, the
// BELLY/FACE (eyes, nose, embossed screen plaque + round joystick knob, and the
// folded arms) is at +Y; the smooth back is at -Y. +X right.
//
// !!! ORIENTATION FIX !!!  In the RAW sculpt the belly/face is actually at -Y and
// the smooth back at +Y (verified by a +Y marker landing on the smooth back).
// Earlier code assumed "belly = +Y" and cut the screen/joystick openings on the
// smooth BACK by mistake. panda_raw() now reorients the sculpt (180 deg about Z +
// a Y shift) so the belly lands at +Y, matching the rest of the code.
//
// The electronics cage (cage.scad) enters from the BASE and its front face sits
// just behind the belly. This file only shapes the BODY; cage.scad is separate.
// ============================================================================

include <dimensions.scad>
include <helpers.scad>

// ---- Import + scale + REORIENT ---------------------------------------------
// STL is in normalized units (~0.94 tall); scale to panda_h mm.
// Full-res mesh (500k tris). Requires OpenSCAD's MANIFOLD backend
// (--backend=Manifold, OpenSCAD 2023+); the old CGAL backend can't boolean this
// in reasonable time. No decimation - full detail preserved.
//
// THE TRANSFORM IS DERIVED, NOT HAND-FITTED. panda_scale / panda_y_off /
// panda_x_off come from probe_skin.scad_transform(), which reads the mesh and
// returns the scale that makes it panda_h tall plus the offsets that centre X and
// centre the Y bounding box on 0. The old recipe was a hard-coded scale(166.7) and
// translate([0,26,0]) fitted by eye to panda_original.stl, and it does not transfer:
// this mesh is 2% shorter and 7% shallower in Y. Deriving it means swapping the
// sculpt again only changes those constants, not the recipe. Every python tool in
// this directory reproduces exactly this frame, so their numbers are directly usable
// here. Keep the transform in ONE place - anything that imports the raw sculpt must
// go through panda_raw().
//
// panda_premade lets you drop in a re-sculpted mesh instead: export it in FINAL
// PANDA COORDINATES - millimetres, feet on Z=0, centred on X, belly at +Y - save it
// alongside the original (never overwrite the source meshes), point panda_stl_mm at
// it and set panda_premade = true. It is then imported as-is, with no scale or
// reorient, so every dimension in this file still applies.
panda_stl     = "panda/panda_original_without_embosses.stl";  // normalized units
panda_stl_mm  = "panda/panda_resculpt.stl";   // optional drop-in, already in mm
panda_premade = false;

module panda_raw() {
    if (panda_premade)
        import(panda_stl_mm, convexity = 10);
    else
        translate([panda_x_off, panda_y_off, 0]) rotate([0, 0, 180])
            scale(panda_scale) import(panda_stl, convexity = 10);
}

// ---- Opening placements (belly is +Y, rump is -Y) ---------------------------
// Placements come from dimensions.scad (single source of truth).
//
// THE BELLY CARRIES ONLY THE SCREEN; the joystick is on the RUMP.
belly_face_y   = 80;             // outside the belly (peak 69.1) so cuts punch through
rump_face_y    = -80;            // outside the back (deepest -69.1), same idea
screen_cz      = dev_oled_pz;    // OLED window centre (panda Z)
cut_depth      = 100;            // how far a cut solid reaches back from the surface

// OLED window: cut the FULL lit-area rectangle through the belly. The cut solid
// starts OUTSIDE the belly (+Y) and extrudes back (-Y) through the body.
//
// This window is the whole 55.4 x 28.4 lit area, because the requirement is that
// every one of the 128x64 pixels is visible. The sculpt's folded paws stand in
// front of it and are cut through; on the 200mm host the paws are 25% further
// apart, so the bite is far smaller than it was at 160mm. dimensions.scad's window
// block has the measurements, the corner-radius table, and every alternative that
// was built and rejected; read it before changing anything here.
//
// oled_win_r is small (2mm) ON PURPOSE: it trades corner pixels against the feet.
// At r=2 just 4 of 8192 lit pixels are hidden and the corner icons stay on screen.
// At the old r=8 the feet were untouched but 236 pixels and both corner icons were
// lost.
//
module oled_outline(w, h, r, g = 0) {
    offset(delta = g)
        offset(r = r) offset(delta = -r)
            square([w, h], center = true);
}
module panda_oled_cut() {
    // NB screen_cz IS the lit-area centre already (dev_oled_pz); do NOT add
    // oled_active_dy here. That offset only converts PCB centre <-> lit centre and
    // is applied on the CAGE side (cage.scad's oled_cz / az). Adding it here too
    // lifted the whole window 3.1mm above the actual screen, which both misaligned
    // the aperture and ran its top corner arc straight along the armpit crease at
    // Z~63, leaving a razor lip that broke into two pin-holes.
    // The cut starts OUTSIDE the belly and runs back through the body;
    // rotate([90,0,0]) makes linear_extrude (+Z) point in -Y, i.e. INTO the body.
    translate([oled_active_dx, 0, screen_cz])
        translate([0, belly_face_y, 0])
            rotate([90, 0, 0])
                linear_extrude(height = cut_depth)
                    oled_outline(oled_win_w, oled_win_h, oled_win_r);
}

// ---- JOYSTICK, on the RUMP -------------------------------------------------
// The module bolts to standoffs on the OUTSIDE of the cage's back wall, so the whole
// assembly - standoff, PCB, gimbal - lives in the rump. The rump is 25.7mm of solid
// body here (cage back face at panda Y-43, skin at Y-68.71), and the assembly is
// 14.68mm of that, so there is ~11mm left for the cap stalk.
//
// TWO CUTS, both on the back (-Y), plus the bore:
//
//  1. BORE for the printed stalk cap: joy_rump_bore_d through to the skin. Small on
//     purpose - it only has to clear the 6.5mm tapered stalk plus its 3.3mm swing,
//     so the cap's 16mm dome overhangs the hole and hides its edge.
//  2. INSERTION CHANNEL + POCKET, as one STEPPED prism running from the base plane
//     up past the module. The cage enters from below, so the whole assembly has to
//     travel up the inside of the rump to reach its position - the pocket IS the top
//     of the channel. It is stepped in Y because the two parts have very different
//     widths: the PCB is 32.3 across X but only 3mm deep, while the gimbal is 23.4
//     across X and 11.8 deep. Cutting the deep part at the PCB's width would eat
//     another 12mm of rump for nothing.
//
// THE CHANNEL DELIBERATELY NOTCHES THROUGH THE SKIN over panda Z2..6: the rump
// surface at |X|14 is only at Y-48.19 (Z2), -54.58 (Z4) and -57.73 (Z6), so reaching
// Y-58.5 there breaks out - 8.5mm deep at Z2, tapering to nothing by Z6. It leaves a
// ~28 x 6mm notch at the very bottom rear, on the table side, which is the cheapest
// place on the model to spend it. The alternative - clipping the channel to the skin
// - just makes the cage un-insertable.
joy_gimbal_y   = -58.5;                    // deepest the gimbal reaches (+ margin)
// Back of the PCB + standoffs + margin. The stack is wall -43, standoff -45,
// PCB back -45.92 - so the old -46.0 left 0.08mm of margin, i.e. none at FDM
// tolerances, and the deep step's rounded corner (r=2) actually bulged INTO the
// -46 plane by 0.5 near |X|13, right where the upper standoffs sweep past.
joy_pcb_y      = -46.5;
joy_chan_w     = joy_body_w2 + 4;          // deep step: gimbal 23.40 + clearance
joy_pocket_w   = joy_pcb_h + 4;            // shallow step: PCB 32.30 across X
joy_chan_front = cage_yc - (cage_d/2 - sled_wall);   // inner face of the back wall
joy_chan_top   = dev_joy_pz + joy_pcb_w/2 + 2;       // above the PCB's top edge
// THE BENT HEADER needs its own step. The 5-pin header leaves a SHORT edge of the
// PCB, raised joy_pin_raise off the component face and bent to run parallel to the
// board - so it rides BEHIND the PCB plane (rump side, past joy_pcb_y) but BESIDE
// the gimbal, outside the deep step's 27.4mm width: x out to 16.15 + 5.2 = 21.35,
// y down to -45.92 - 6 = -51.9. Neither existing step covers that corner, so the
// mounted module could not pass the channel at all. The step is SYMMETRIC in X so
// the module can be fitted pins-left or pins-right, and stops at joy_pin_top
// because nothing sweeps above the header row. Skin check (rump raycast table,
// 2026-08-24): at |X|22.9 the skin is at Y-55.1 by Z6 and deeper above, so a
// -53 step keeps >=2.1mm of wall everywhere above the base notch, which widens
// from ~28mm to ~46mm over panda Z2..5 - still on the table side, unseen.
joy_pins_y     = -53;                        // back of the bent row + margin
joy_pin_chan_w = joy_pcb_h + 2*(joy_pin_ext + 1.5);  // 45.7, pins either side
joy_pin_top    = dev_joy_pz + joy_pin_row/2 + 2;     // above the header row (58.35)

module panda_joystick_cut() {
    // 1. cap bore, from outside the rump inward
    translate([0, rump_face_y, dev_joy_pz])
        rotate([-90, 0, 0])               // extrude +Y, i.e. into the body
            cylinder(h = cut_depth, d = joy_rump_bore_d);
    // 2a. deep step: gimbal width, from joy_gimbal_y forward to the PCB plane
    translate([0, (joy_gimbal_y + joy_pcb_y)/2, -1])
        linear_extrude(joy_chan_top + 1)
            offset(r = 2)
                square([joy_chan_w - 4, (joy_pcb_y - joy_gimbal_y) - 4],
                       center = true);
    // 2b. shallow step: PCB width, from the PCB plane forward into the cavity
    translate([0, (joy_pcb_y + joy_chan_front)/2, -1])
        linear_extrude(joy_chan_top + 1)
            offset(r = 2)
                square([joy_pocket_w - 4, (joy_chan_front - joy_pcb_y) - 4],
                       center = true);
    // 2c. pin step: clears the bent 5-pin header, which rides behind the PCB
    //     plane but beside the gimbal (see the joy_pins_y block above).
    translate([0, (joy_pins_y + joy_pcb_y)/2, -1])
        linear_extrude(joy_pin_top + 1)
            offset(r = 2)
                square([joy_pin_chan_w - 4, (joy_pcb_y - joy_pins_y) - 4],
                       center = true);
}

// ---- USB-C charge exit, also on the RUMP -----------------------------------
// The cage cuts a matching slot in its own back wall (usb_exit_cut in cage.scad);
// this is the hole through the body that it has to line up with. It did not exist:
// panda.scad had no USB geometry at all, so the cable ran into ~15.5mm of solid
// rump. Both sides now read usb_slot_* from dimensions.scad.
//
// The cage is placed with rotate([0,0,180]), so its -X lands at panda +X: the slot
// is at cage x-19.3 = panda x+19.3. It flares outward so the cable can turn without
// being pinched on the exit edge.
usb_px = -usb_slot_x;                     // cage -> panda X (the 180deg spin)
usb_pz = usb_slot_z + cage_z0;            // cage Z -> panda Z
usb_y0 = cage_yc - (cage_d/2 - sled_wall);   // inner face of the cage's back wall
module panda_usb_cut() {
    // Start at the cage's back wall and run out past the skin. On this host the rump
    // is 25.7mm deep, so the old hard-coded 30mm run from Y-20 stopped 19mm short of
    // the surface and left the cable vented into solid body again.
    translate([usb_px, usb_y0, usb_pz])
        rotate([90, 0, 0])                // extrude -Y, out through the rump
            linear_extrude(abs(rump_face_y - usb_y0), scale = 1.35)
                offset(r = 2)
                    square([usb_flange_w - 3, usb_flange_h - 3], center = true);
}

// Speaker sound path: a CHIMNEY rising from the cavity top, through the neck, into
// the head resonator. The speaker sits on the cage TOP (panda Z cage_z0+cage_h = 87)
// firing UP; this channel carries the sound past the neck into the hollow head.
//
// CRITICAL: it must OVERLAP both ends or the void is not continuous and an unbroken
// plug of body blocks the sound (that was the original bug - a 34mm cylinder that
// floated between the cavity and the head, confirmed in a section render). sp_z0 75
// starts below the cavity top (panda Z87) and sp_z1 135 ends well inside
// panda_head_cavity(), which spans panda Z112.5..182.5.
// Centred at Y=sp_cy (the cage centre) and kept narrow enough (48x34) to stay inside
// the neck without breaching the leaning chest/chin.
sp_cy  = cage_yc;         // chimney Y centre = cage centre (speaker fires up centred)
sp_hw  = 24;              // chimney half-width (X) -> 48 wide (> grille 37.35)
sp_dep = 17;              // chimney half-depth (Y) -> 34 deep (> grille 26.80)
sp_z0  = 75;              // start BELOW the cavity top (overlap -> continuous void)
sp_z1  = 135;             // top, up inside the hollow head
module panda_neck_bore() {
    translate([0, sp_cy, sp_z0])
        linear_extrude(sp_z1 - sp_z0)
            offset(r = 4) square([2*sp_hw - 8, 2*sp_dep - 8], center = true);
}

// Head resonator: HOLLOW the head so the speaker chamber can actually resonate.
// Mesh scan of the head at 200mm: half-width peaks at 63.5 around Z130, the face
// front runs Y68.6 at Z135 down to Y45 at Z165, the back Y-65, crown ~Z196. An
// ELLIPSOID void centred (0, -5, 147.5) with radii (45, 37.5, 35) leaves >=15.6mm
// of wall at every point of its surface (raycast, 1152 samples - no breach of face,
// ears or crown) and OVERLAPS the neck chimney top (Z135) so the void is
// continuous: speaker -> chimney -> head chamber -> ear vents.
head_c = [0, -5.0, 147.5];
head_r = [45.0, 37.5, 35.0];
module panda_head_cavity() {
    translate(head_c) scale(head_r) sphere(r = 1);
}

// Head vents: the speaker grille sits in the STIPPLED INNER DISH of each ear (the
// sculpted "inner ear"), venting the head resonator so sound emits FROM THE EARS.
// An earlier version drilled 2x3 holes on the ear's outer-lower CORNER, which read
// as damage rather than a grille; the dish is the only surface on the ear that is
// meant to look perforated.
//
// Mesh survey at 200mm (density + front/back surface scan of the 500k mesh):
//   * the inner dish is a shallow RECESS on the ear's +Y face, identifiable by its
//     stipple (several times the triangle density of smooth skin).
//   * shape: a TILTED OVAL, centre (X 51.4, Z 182.9), major axis -46.2 deg in the
//     XZ plane (top tilts inboard). The angle does not scale with the host.
//   * stock behind it: over the grille's footprint the dish surface runs Y -0.39
//     (nearest) to +1.90 and the ear's rear skin Y -11.49 (nearest) to -15.28, so
//     there are 11-15mm to work in.
//
// !!! THE Y NUMBERS DO NOT SCALE WITH THE HOST !!!  ear_cx / ear_cz do (they are
// 1.25x their 160mm values), but every Y here is measured in the panda frame, and
// that frame MOVED when the transform stopped being hand-fitted (panda_y_off 26 ->
// 9.036). The old plenum at Y 13.5..18.0 is 20mm outside this mesh. Re-measure, do
// not rescale.
//
// The vent is a real grille rather than a few blind pokes:
//   13 bores (hex 4/5/4, d2.4 @ 3.8 pitch, the grid rotated onto the dish's major
//   axis) -> a shared PLENUM milled just under the skin -> 3 ducts that tunnel
//   inboard and down into the head void.
// The grille itself does NOT scale with the host - hole size and pitch are acoustic
// and print-driven - so on the bigger ear it simply sits in the middle of the dish
// with more untouched stipple round it. The duct START points are likewise kept at
// their original offsets from the dish centre; scaling them by 1.25 walks the lowest
// one off the edge of the plenum it is supposed to open into.
// Open areas are matched: grille 58.8mm^2 vs duct throat ~54.6mm^2 (the 3 ducts
// overlap into one ~12x5 stadium throat).
// Verified: >=1.8mm of stippled skin in front of the plenum, >=3.7mm to the ear's
// rear skin, >=4.5mm of wall around every duct along its whole run, and all three
// ducts terminate INSIDE panda_head_cavity().
ear_cx      = 51.4;    // inner-dish centre, panda X (right ear; left is mirrored)
ear_cz      = 182.9;   // inner-dish centre, panda Z
ear_ang     = -46.2;   // dish major axis, degrees in the XZ plane
ear_hole_d  = 2.4;     // grille hole diameter
ear_pitch   = 3.8;     // hex pitch -> 1.4mm webs between holes
ear_out_y   = 6.0;     // bores start here, safely outside the dish (skin is at ~0)
ear_pl_y1   = -2.2;    // plenum FRONT face (leaves >=1.81mm of stippled skin)
ear_pl_y0   = -7.8;    // plenum REAR face  (leaves >=3.69mm to the ear's back skin)
ear_pl_r    = 1.6;     // plenum overhang beyond the hole-centre hull
ear_duct_d  = 5.0;     // duct bore
ear_duct_y  = -5.0;    // ducts leave the plenum at its mid-depth
ear_duct_y2 = head_c[1];  // ... and meet the head void at its mid-Y
// duct [X,Z] start (inside the plenum footprint) -> [X,Z] end (inside the head void)
ear_ducts   = [[[45.27, 184.17], [13, 165]],
               [[48.27, 180.67], [15, 161]],
               [[51.27, 177.17], [18, 157]]];

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
        // Visible grille: bores from OUTSIDE the dish down into the plenum.
        translate([0, ear_out_y, 0]) rotate([90, 0, 0])        // extrude -> -Y
            linear_extrude(ear_out_y - (ear_pl_y0 + 1))
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
// cav_clear / cav_front_gap / cav_fyb are in dimensions.scad (cage.scad needs them).
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
// cav_min / cav_clip_z / skin_cy / skin_r are in dimensions.scad.
//
// skin_scaled(e): the sculpt eroded by ~e at the belly radius, by scaling X/Y toward
// the body axis. A cheap stand-in for a true 3D inward offset, which is all the
// pinch needs. Z is untouched, so at the base - where the surface is nearly
// horizontal - the erosion is zero and a part clipped to it finishes flush.
module skin_scaled(e) {
    k = 1 - e/skin_r;
    translate([0, skin_cy, 0]) scale([k, k, 1]) translate([0, -skin_cy, 0])
        panda_raw();
}
module skin_inset() { skin_scaled(cav_min); }
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

// ---- The folded arms: DELIBERATELY UNTOUCHED --------------------------------
// The arms are folded across the belly and, at screen height, they ARE the body's
// flank - the front profile climbs smoothly from the flank to the paw crest with no
// crease, so there is no hidden belly behind them. They are left exactly as
// sculpted, and the OLED window simply cuts through whatever stands in front of it
// (see panda_oled_cut(); on the 200mm host the paws are 25% further apart, so the
// bite is much smaller than the 8.1mm per paw it was at 160).
//
// DO NOT try to make room for a wider window here. All of these were built,
// measured and abandoned (at 160mm - the conflict is milder now but the conclusions
// about deforming the sculpt still hold):
//  * Bevelling/countersinking the window (oled_bevel_*): flared the outline outward
//    wherever the skin bulged, leaving two flat "wings" beside the screen ending in
//    a hard crescent line.
//  * A rolling-ball trim (arm_trim(): a box minus a chain of hulled spheres centred
//    on the plaque's face plane). Tangent-continuous and facet-free, but it still
//    rolled the sculpted paw tip off into a spherical dome and planed the crest.
//  * Intersecting with a copy of the sculpt shifted along the arm axis: the shifted
//    copy samples the belly BELOW the arm, so past ~12mm it erodes a diagonal swath
//    across the whole belly and breaks out of its own zone at Z38.
//  * Deforming the mesh upstream in Blender (panda_arms.py): swinging each arm
//    outboard about the body axis DID free the paws cleanly. But there are only
//    2.6mm of surface between the paw's underside (Z42) and the top of the feet
//    (Z39.4), so the swing's taper has to collapse ~12mm of movement across it. Put
//    the taper above the feet and it tears a serrated ridge across the belly (900+
//    inverted triangles); run it through the feet and it shears their tops into
//    POINTY TIPS. ~30 envelope configurations were swept, plus a biharmonic
//    (thin-plate) solve with the paw as a handle and the feet pinned - the solve was
//    20x WORSE, because the sculpt's triangulation (21:1 edge lengths, 19% negative
//    cotangent weights) is far too irregular for a Laplacian method. The best result
//    still rotated the legs 13mm and visibly widened the stance.
// It is a hard geometric conflict, not a tuning problem. Sizing the window to the
// plaque dissolves it, which is what this file now does.

// ---- Base hatch: open the underside so the cage slides in ------------------
// It is the CAGE'S OWN BASE CROSS-SECTION extruded down to the ground, inflated by
// the same cav_clear/cav_fyb the cavity uses, not a plain rectangle. That matters
// here: a cage_d+2 rectangle reaches panda Y46, which is 3mm further forward than
// the cage's base actually is (shell_prof row 0 sets it back 2.22), and every one of
// those millimetres is cut out of a belly that at panda Z2 has only reached Y40.3.
module panda_base_hatch() {
    translate([0, cage_yc, cage_z0])
        rotate([0, 0, 180])
            translate([0, 0, -(cage_z0 + 2)])
                linear_extrude(cage_z0 + 2 + eps)
                    shell_section(shell_prof[0][1], shell_prof[0][2],
                                  -cav_clear, cav_fyb + prof_fyb(shell_prof[0]));
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
rebate_h = cage_z0 + rim_h;      // panda Z of the rebate ceiling = flange top (11.2)
module panda_base_rebate() {
    translate([0, cage_yc, -eps])
        rotate([0, 0, 180])
            linear_extrude(rebate_h + eps)
                base_flange_2d(fit_gap);
}

// The body's 4 magnets: pockets in the rebate's CEILING, opening downward, so each
// magnet's face sits flush at rebate_h and meets the flange magnet metal-to-metal.
// Verified by raycast (odd-crossing test, not a convex approximation) that all four
// sit in solid body over panda Z11.2..15.7 with >=4mm of body all round: the front
// pair at panda (+-38, 50) is inside the feet, the side pair at (+-44, 17) is in the
// side collar, and the hatch only reaches |X|38.5 / Y -44..46.
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
        panda_usb_cut();
        panda_neck_bore();
        panda_head_vents();
        panda_base_hatch();
        panda_base_rebate();
        panda_magnet_pockets();
    }
}

// ---- NO COLOUR SPLIT ---------------------------------------------------------
// There used to be a `colored_3mf` mode here that carved the classic black/white
// panda markings out of the body with boxes, spheres and prisms, and exported them
// as two shells for a multi-material slicer. It is REMOVED, and should not come
// back in that form.
//
// The reason is that the markings are not describable by primitives. The sculpt's
// eye patches, arm/shoulder yoke and leg boundaries are curved features that follow
// the surface; every attempt to approximate them by intersecting the body with
// analytic solids produced boundaries that cut across the sculpted shapes instead of
// along them - straight lines where the arm meets the chest, patches that either
// spilled past the sculpted almond or shrank to the pupil depending on how the
// curved face happened to slice the solid. It looked wrong in a way no amount of
// tuning the numbers fixes, and the numbers had to be re-guessed on every host
// change because they were pure eyeballing.
//
// If a two-colour print is wanted, do it where the information actually exists:
//   * paint or vinyl the markings after printing, or
//   * split the mesh in a sculpting tool (Blender vertex groups / face maps by hand)
//     and export that as the coloured source, or
//   * ask the sculptor for a mesh already split into black and white shells.
// All three carry the real outlines. Do not re-derive them from bounding boxes.
panda_body();
