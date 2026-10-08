// Visual comparison only. Uses frozen print exports; does not change any part.
// Original body = v3, before outer scaling, including the approved entrance fix.
// Current body = v8, 108.7% outer sculpt and corrected speaker inlet.
// Both use the EXACT same already-printed cage at its existing placement.
// Render with --backend=Manifold --render --imgsize=1800,850
// --projection=orthogonal --colorscheme=Tomorrow.
// Camera: --camera=0,0,53,90,0,0,520 for section;
//         --camera=0,0,49,90,0,0,520 for front/rear.
// Keep both models in one render: do not fit each model to its own frame.
include <dimensions.scad>
view = "section"; // section, front, rear
before = "stl/panda_body_entrance_relief_v3.stl";
after = "stl/panda_body_uniform_v8.stl";
body_color = [0.78,0.79,0.81];
cage_color = [0.08,0.43,0.65];

module body_mesh(file) { import(file, convexity=12); }
module printed_cage() {
    translate([0,cage_yc,cage_z0]) rotate([0,0,180])
        import("stl/cage.stl", convexity=12);
}
module centre_section() {
    intersection() {
        children();
        translate([-0.15,-150,-1]) cube([0.3,300,121]);
    }
}
module assembly_section(file) {
    rotate([0,0,90]) {
        color(body_color) centre_section() body_mesh(file);
        color(cage_color) centre_section() printed_cage();
    }
}
module exterior(file, back=false) {
    rotate([0,0,back ? 0 : 180]) {
        intersection() {
            color(body_color) body_mesh(file);
            translate([-150,-150,-1]) cube([300,300,106]);
        }
        color(cage_color) printed_cage();
    }
}
if (view == "section") {
    translate([-86,0,0]) assembly_section(before);
    translate([86,0,0]) assembly_section(after);
}
else if (view == "front" || view == "rear") {
    translate([-86,0,0]) exterior(before, view == "rear");
    translate([86,0,0]) exterior(after, view == "rear");
}
