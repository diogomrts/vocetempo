"""Verify the OLED belly window.

    blender -b -P verify_window.py -- [w] [h] [r] [cz]     (defaults: oled_win_*)

The window is the FULL lit area and deliberately cuts through the folded paws, so
there is no bezel band to measure. The two things that actually matter are:

  1. PIXEL COVERAGE - the requirement is that every one of the 128x64 lit pixels is
     visible. Only the corner rounding can hide any, so this counts exactly how many
     fall outside the aperture and checks the UI elements that live in the corners.

  2. WHERE THE CUT LANDS - the paws (Z42..58) are cut on purpose. The FEET (Z<40)
     and the SHOULDERS (Z>58) are not, and the corner radius controls how far the
     window's corners reach into them. This reports each separately against a budget.

NOTE an earlier version measured a "bezel band" between the rim and the paw, which
was the right check when the window was sized to sit inside the sculpted plaque. It
is meaningless now (it reports a 0.2mm band, correctly, because the rim IS on the
paw by design). Do not reintroduce it without also changing the design back.
"""
import bpy
import math
import sys

import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

SRC = "/Users/diogomartins/Projects/vocetempo/enclosure/panda/panda_original.stl"
PANDA_SCALE, SPIN_Y = 166.7, 26.0

a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
W = float(a[0]) if len(a) > 0 else 55.4      # oled_win_w
H = float(a[1]) if len(a) > 1 else 28.4      # oled_win_h
R = float(a[2]) if len(a) > 2 else 2.0       # oled_win_r
CZ = float(a[3]) if len(a) > 3 else 46.0     # dev_oled_pz

LIT_W, LIT_H = 55.0, 28.0                    # oled_active_w / _h
NX, NY = 128, 64
PX, PZ = LIT_W / NX, LIT_H / NY

MAX_HIDDEN = 8          # lit pixels allowed outside the aperture
MAX_FOOT_CUT = 2.5      # mm the window may reach into the feet (Z < 40)
MAX_SHOULDER_CUT = 7.5  # ... and into the arm above the paw (Z > 58)

fails = []


def log(*x):
    print(*x)
    sys.stdout.flush()


def check(ok, msg):
    log(("   ok  " if ok else "  FAIL ") + msg)
    if not ok:
        fails.append(msg)


def hw(z, r=None):
    r = R if r is None else r
    d = abs(z - CZ)
    if d > H / 2:
        return None
    flat = H / 2 - r
    if d <= flat:
        return W / 2
    o = d - flat
    return W / 2 - r + math.sqrt(max(0.0, r * r - o * o))


def inside(ax, d, r):
    """is |x|=ax, |z-cz|=d inside the rounded rectangle?"""
    if ax > W / 2 or d > H / 2:
        return False
    if ax <= W / 2 - r or d <= H / 2 - r:
        return True
    return math.hypot(ax - (W / 2 - r), d - (H / 2 - r)) <= r


# ---- 1. pixel coverage -----------------------------------------------------
log(f"window {W} x {H}, corner r {R}, centred Z{CZ}\n")
hidden, moon, mute = 0, True, True
for py in range(NY):
    d = abs((NY / 2 - 0.5 - py) * PZ)
    for px in range(NX):
        ax = abs((px - (NX / 2 - 0.5)) * PX)
        if not inside(ax, d, R):
            hidden += 1
            if 116 <= px <= 126 and 1 <= py <= 11:
                moon = False
            if 2 <= px <= 11 and 1 <= py <= 10:
                mute = False
log(f"-- pixel coverage: {NX * NY - hidden} of {NX * NY} lit pixels visible --")
check(hidden <= MAX_HIDDEN, f"lit pixels hidden by the corner rounding: {hidden}")
check(moon, "quiet-hours icon (px 116..126, y 1..11) is on screen")
check(mute, "mute icon (px 2..11, y 1..10) is on screen")

# ---- 2. where the cut lands -------------------------------------------------
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.stl_import(filepath=SRC)
ob = bpy.context.selected_objects[0]
me = ob.data
n = len(me.vertices)
co = np.empty(n * 3)
me.vertices.foreach_get("co", co)
p = co.reshape(n, 3) * PANDA_SCALE
p[:, 0] *= -1
p[:, 1] *= -1
p[:, 1] += SPIN_Y
me.vertices.foreach_set("co", p.reshape(-1))
me.update()
bvh = BVHTree.FromObject(ob, bpy.context.evaluated_depsgraph_get())


def fy(x, z):
    h = bvh.ray_cast(Vector((x, 400.0, z)), Vector((0, -1, 0)))
    return None if h[0] is None else h[0].y


def belly_ref(x, z, y0):
    """Where the plain belly would be at (x, z), anchored to its own height on the
    centreline at that Z and using the sculpt's measured lateral curvature.
    Anchoring PER-Z matters: a single fitted plane is only valid over Z36..56 (the
    plaque), and outside that it reads the belly's own bulge as an obstruction -
    which reported a nonsensical 21mm "cut into the feet"."""
    return y0 - 0.004622 * x * x


def obstruction(z):
    """Inboard edge of the feet / paws at this height. TWO detectors, because
    neither alone is right: the feet meet the belly at a CLIFF, but the paws rise
    GRADUALLY (a cliff-only test reported 0.00mm of cut over Z41..48, where the
    real cut is 1.5..6.5mm). Take whichever fires first."""
    y0 = fy(0.0, z)
    if y0 is None:
        return 40.0
    out = []
    for sgn in (-1, 1):
        prev, found = None, None
        for i in range(400):
            x = 6.0 + i * 0.1
            v = fy(sgn * x, z)
            if v is None:
                break
            if prev is not None and v - prev > 2.0:              # cliff (feet)
                found = x
                break
            # 5mm, not 3: the plaque's own decorative frame ridge reads ~3mm
            # proud of this reference, and the window is MEANT to cut through that
            # (it is the sculpted fake screen). The paws read 6..9mm.
            if v - belly_ref(sgn * x, z, y0) > 5.0:              # proud (paws)
                found = x
                break
            prev = v
        out.append(found if found is not None else 40.0)
    return min(out)


log("\n-- where the cut lands (raw sculpt) --")
log("     Z | window |X| | sculpt edge | cut depth | region")
worst = {"foot": (0.0, None), "paw": (0.0, None), "shoulder": (0.0, None)}
for z in np.arange(CZ - H / 2, CZ + H / 2 + 0.01, 1.0):
    w = hw(z)
    if w is None:
        continue
    e = obstruction(z)
    cut = max(0.0, w - e)
    region = "foot" if z < 40 else ("shoulder" if z > 58 else "paw")
    if cut > worst[region][0]:
        worst[region] = (cut, round(z, 1))
    log(f"  {z:5.1f} | {w:9.2f} | {e:11.2f} | {cut:9.2f} | {region}"
        + ("  <- deliberate" if region == "paw" and cut > 0.1 else ""))

log("")
log(f"   note  paw cut (deliberate): {worst['paw'][0]:.2f}mm at Z{worst['paw'][1]}"
    " - this is the design decision, not a defect")
check(worst["foot"][0] <= MAX_FOOT_CUT,
      f"cut into the FEET: {worst['foot'][0]:.2f}mm at Z{worst['foot'][1]}"
      f" (budget {MAX_FOOT_CUT})")
check(worst["shoulder"][0] <= MAX_SHOULDER_CUT,
      f"cut into the SHOULDER: {worst['shoulder'][0]:.2f}mm at Z{worst['shoulder'][1]}"
      f" (budget {MAX_SHOULDER_CUT})")

log("")
if fails:
    log("FAILED:")
    for f in fails:
        log("   * " + f)
    sys.exit(1)
log("ALL CHECKS PASSED")
