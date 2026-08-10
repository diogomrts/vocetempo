// ============================================================================
// Fit-check: the electronics CAGE seated inside the hollowed PANDA body.
//
// This is the real integration test - it places the cage exactly where it lives
// in the panda and lets you confirm:
//   * the OLED/joystick on the cage FRONT sit just behind the belly openings,
//   * the speaker on the cage TOP lines up with the neck chimney,
//   * the cage stays INSIDE the body (no shell poking through - see the
//     `breach` mode, which shows only the cage material OUTSIDE the panda).
//
// PLACEMENT (single source of truth in dimensions.scad): the cage's own frame has
// the OLED front at -Y, so in the panda it is spun 180 about Z, then translated to
// the cage centre (cage_yc) and lifted to cage_z0:
//     translate([0, cage_yc, cage_z0]) rotate([0,0,180]) cage();
//
// Modes (set `mode`):
//   "ghost"  panda translucent + cage solid (default; see alignment)
//   "section" X=0 cross-section of both (see the sound path + recesses)
//   "breach" ONLY the cage material sticking OUT of the panda (should be ~nothing)
//
// Render (Manifold backend required for the 500k-tri panda):
//   openscad --backend=Manifold -o previews/fitcheck.png --imgsize=700,900 \
//     --camera=0,0,0,68,0,25,0 --viewall --autocenter --projection=perspective \
//     --colorscheme=Tomorrow fitcheck.scad
// ============================================================================

include <dimensions.scad>
use <panda.scad>
use <cage.scad>

mode = "ghost";

module placed_cage() {
    translate([0, cage_yc, cage_z0]) rotate([0, 0, 180]) cage();
}

if (mode == "ghost") {
    color([0.60, 0.70, 0.85, 0.30]) panda_body();
    color([1, 0.55, 0.10]) placed_cage();
}
else if (mode == "section") {
    intersection() {
        union() {
            color([0.60, 0.70, 0.85]) panda_body();
            color([1, 0.55, 0.10]) placed_cage();
        }
        translate([-100, -200, -20]) cube([100, 400, 400]);   // keep X < 0
    }
}
else if (mode == "breach") {
    // cage material OUTSIDE the panda solid = a fit problem. Ideally empty.
    // Use the REORIENTED raw sculpt (panda_raw), same as panda.scad, so the belly
    // is at +Y - otherwise this test would check against the wrong side.
    difference() {
        placed_cage();
        panda_raw();
    }
}
