"""Probe the panda sculpt's BELLY skin: front-most Y at any (X, Z).

    python probe_skin.py                      # the standard tables
    python probe_skin.py x0 x1 ... -- z0 z1   # custom grid

Loads the sculpt panda.scad builds from, applies the SAME scale/orientation, and for
each (X, Z) returns the largest Y on the surface - i.e. how far the belly bulges
forward at that point. The cage's front wall has to live behind this, and the OLED
window / joystick opening have to reach through it.

Pure numpy, no trimesh: a point-in-triangle test in the XZ projection, then take
max Y of the hit triangles' interpolated plane.
"""
import os
import sys
import struct

import numpy as np

# Which sculpt to analyse. Override with PANDA_STL=... to compare hosts:
#   PANDA_STL=panda/panda_original.stl python fit_shell.py
#
# These defaults ARE what panda.scad builds from - the de-embossed mesh at 200mm.
# Keep them in step with panda_stl / panda_h in dimensions.scad, or every number
# these tools print will belong to a different panda than the one being cut.
SRC = os.environ.get("PANDA_STL", "panda/panda_original_without_embosses.stl")
PANDA_H = 200.0          # target height, = panda_h in dimensions.scad

# ORIENTATION RULE (must match panda_raw() in panda.scad exactly):
#   1. scale so the model is PANDA_H tall
#   2. feet on Z = 0
#   3. mirror X and Y, so the belly/face lands at +Y (the raw sculpt has it at -Y)
#   4. centre X on 0
#   5. place the Y bounding box so its CENTRE lands on Y = 0
#
# Steps 1, 4 and 5 are new. The old recipe hard-coded `scale(166.7)` and
# `translate([0,26,0])`, which were fitted by hand to panda_original.stl - they do
# not transfer, because panda_original_without_embosses.stl is NOT the same size:
# it is 2% shorter and 7% shallower in Y (raw Z span 0.93937 vs 0.95893, Y span
# 0.64892 vs 0.70079), and its X is symmetric where the old mesh was 0.44mm
# off-centre. Deriving the transform from the mesh means swapping the sculpt again
# only changes the two constants this prints, not the recipe.
def load(path=SRC, panda_h=PANDA_H):
    raw = open(path, "rb").read()
    n = struct.unpack("<I", raw[80:84])[0]
    assert 84 + n * 50 == len(raw), "not a binary STL of that many triangles"
    a = np.frombuffer(raw[84:], dtype=np.uint8).reshape(n, 50)
    v = a[:, 12:48].copy().view("<f4").reshape(n, 3, 3).astype(np.float64)
    v *= panda_h / (v[:, :, 2].max() - v[:, :, 2].min())
    v[:, :, 2] -= v[:, :, 2].min()
    v[:, :, 0] *= -1.0
    v[:, :, 1] *= -1.0
    v[:, :, 0] -= (v[:, :, 0].min() + v[:, :, 0].max()) / 2
    v[:, :, 1] -= (v[:, :, 1].min() + v[:, :, 1].max()) / 2
    return v


def scad_transform(path=SRC, panda_h=PANDA_H):
    """The (scale, x_off, y_off) that reproduces load()'s frame in OpenSCAD, for
    `translate([x_off, y_off, 0]) rotate([0,0,180]) scale(scale) import(path)`."""
    raw = open(path, "rb").read()
    n = struct.unpack("<I", raw[80:84])[0]
    a = np.frombuffer(raw[84:], dtype=np.uint8).reshape(n, 50)
    v = a[:, 12:48].copy().view("<f4").reshape(n, 3, 3).astype(np.float64)
    scale = panda_h / (v[:, :, 2].max() - v[:, :, 2].min())
    # rotate 180 about Z negates X and Y, so the post-rotation extents are:
    xs = -scale * v[:, :, 0]
    ys = -scale * v[:, :, 1]
    return (scale,
            -(xs.min() + xs.max()) / 2,
            -(ys.min() + ys.max()) / 2)


def front_y(tris, x, z):
    """Largest Y on the surface at (x, z), or None if the ray misses."""
    a, b, c = tris[:, 0], tris[:, 1], tris[:, 2]
    # bounding-box reject in the XZ plane first (cheap)
    lo = np.minimum(np.minimum(a, b), c)
    hi = np.maximum(np.maximum(a, b), c)
    m = ((lo[:, 0] <= x) & (hi[:, 0] >= x) & (lo[:, 2] <= z) & (hi[:, 2] >= z))
    if not m.any():
        return None
    a, b, c = a[m], b[m], c[m]
    # barycentric in XZ
    v0 = c - a
    v1 = b - a
    d00 = v0[:, 0] * v0[:, 0] + v0[:, 2] * v0[:, 2]
    d01 = v0[:, 0] * v1[:, 0] + v0[:, 2] * v1[:, 2]
    d11 = v1[:, 0] * v1[:, 0] + v1[:, 2] * v1[:, 2]
    px, pz = x - a[:, 0], z - a[:, 2]
    d20 = px * v0[:, 0] + pz * v0[:, 2]
    d21 = px * v1[:, 0] + pz * v1[:, 2]
    den = d00 * d11 - d01 * d01
    ok = np.abs(den) > 1e-12
    u = np.where(ok, (d11 * d20 - d01 * d21) / np.where(ok, den, 1), -1)
    v = np.where(ok, (d00 * d21 - d01 * d20) / np.where(ok, den, 1), -1)
    hit = ok & (u >= -1e-9) & (v >= -1e-9) & (u + v <= 1 + 1e-9)
    if not hit.any():
        return None
    y = a[hit, 1] + u[hit] * v0[hit, 1] + v[hit] * v1[hit, 1]
    return float(y.max())


def table(tris, xs, zs, title):
    print(f"\n== {title} ==")
    print("   Z  | " + " | ".join(f"X{x:>+6.1f}" for x in xs))
    for z in zs:
        row = []
        for x in xs:
            y = front_y(tris, x, z)
            row.append("   --  " if y is None else f"{y:7.2f}")
        print(f"{z:5.1f} | " + " | ".join(row))


if __name__ == "__main__":
    tris = load()
    print(f"loaded {len(tris)} triangles; "
          f"bounds X {tris[:,:,0].min():.1f}..{tris[:,:,0].max():.1f}  "
          f"Y {tris[:,:,1].min():.1f}..{tris[:,:,1].max():.1f}  "
          f"Z {tris[:,:,2].min():.1f}..{tris[:,:,2].max():.1f}")
    # X columns that matter: centre, window edge, OLED hole, OLED PCB corner,
    # cage side wall.
    xs = [0, 13.9, 27.7, 32.2, 34.3, 37.5]
    zs = list(range(0, 90, 2))
    table(tris, xs, zs, "belly skin: front-most Y at (X, Z)  [cage front wall is at Y45]")
