"""Verify the OLED window on the FINAL CUT body: the rim must land on flat plaque,
with the sculpted frame intact all the way round, and never on a paw or a foot.

blender -b -P verify_window.py -- <cut_body.stl>
"""
import bpy, sys, math
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

STL = sys.argv[sys.argv.index("--") + 1]
WIN_W, WIN_H, WIN_R, CZ = 36.0, 21.0, 3.0, 46.0
# plaque reference surface, fitted on the raw sculpt (see dimensions.scad)
def ref(x, z):
    return 60.207 - 0.14885 * z - 0.004622 * x * x

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.stl_import(filepath=STL)
ob = bpy.context.selected_objects[0]
bvh = BVHTree.FromObject(ob, bpy.context.evaluated_depsgraph_get())

def fy(x, z):
    h = bvh.ray_cast(Vector((x, 400.0, z)), Vector((0, -1, 0)))
    return None if h[0] is None else h[0].y

def log(*a):
    print(*a); sys.stdout.flush()

def hw(z):
    d = abs(z - CZ)
    if d > WIN_H / 2: return None
    flat = WIN_H / 2 - WIN_R
    if d <= flat: return WIN_W / 2
    o = d - flat
    return WIN_W / 2 - WIN_R + math.sqrt(max(0.0, WIN_R * WIN_R - o * o))

log("Window rim check. 'rim dev' = how far the surface at the rim sits above the")
log("flat plaque (>0.8 means the rim is up on the frame or a paw - BAD).")
log("'frame at' = how far outboard of the rim the sculpted frame starts rising.\n")
log("     Z | win hw | -X rim dev | +X rim dev | -X frame at | +X frame at")
worst_dev, worst_frame = -9.0, 99.0
for z in np.arange(36.0, 56.51, 0.5):
    w = hw(z)
    if w is None: continue
    row, devs, frames = "", [], []
    for sgn in (-1, 1):
        # just OUTSIDE the hole: step out until we get a hit
        d = None
        for i in range(40):
            v = fy(sgn * (w + 0.05 + i * 0.05), z)
            if v is not None:
                d = v - ref(sgn * (w + 0.05 + i * 0.05), z); break
        devs.append(d)
        # where does the frame start rising?
        fr = None
        for i in range(120):
            xx = w + 0.1 + i * 0.05
            v = fy(sgn * xx, z)
            if v is not None and v - ref(sgn * xx, z) > 0.8:
                fr = xx - w; break
        frames.append(fr)
    dd = [x for x in devs if x is not None]
    ff = [x for x in frames if x is not None]
    if dd: worst_dev = max(worst_dev, max(dd))
    if ff: worst_frame = min(worst_frame, min(ff))
    f = lambda v: "   --  " if v is None else f"{v:+7.2f}"
    log(f"  {z:5.1f} | {w:6.2f} | {f(devs[0])}    | {f(devs[1])}    |"
        f" {f(frames[0])}     | {f(frames[1])}")
log(f"\nworst rim deviation from the flat plaque: {worst_dev:+.2f}mm  "
    f"({'OK - rim is on flat plaque' if worst_dev < 0.8 else 'FAIL'})")
log(f"closest the frame comes to the rim:      {worst_frame:.2f}mm  "
    f"({'OK - frame intact all round' if worst_frame > 0.05 else 'FAIL - rim eats the frame'})")

log("\nTop / bottom rim, along X:")
log("       X | bottom rim dev | top rim dev")
for x in (-16, -12, -8, -4, 0, 4, 8, 12, 16):
    out = []
    for sgn, z0 in ((-1, CZ - WIN_H / 2), (1, CZ + WIN_H / 2)):
        d = None
        for i in range(40):
            zz = z0 + sgn * (0.05 + i * 0.05)
            v = fy(x, zz)
            if v is not None:
                d = v - ref(x, zz); break
        out.append(d)
    f = lambda v: "     --  " if v is None else f"{v:+9.2f}"
    log(f"  {x:6d} | {f(out[0])}      | {f(out[1])}")
log("\nDONE")
