"""Compare two sculpt meshes surface-to-surface, in final panda millimetres.

    python compare_mesh.py old.stl new.stl

Both are put through the SAME normalise-and-orient recipe (scale so the model is
panda_h tall, mirror X and Y so the belly faces +Y, centre X on 0, and place the Y
bounding box so its centre lands at Y_MID), then their belly and rump surfaces are
sampled on the same (X, Z) grid and differenced.

This exists because "the same sculpt with the embossed plaques removed" turned out
not to be the same size: the replacement mesh is 2% shorter and 7% shallower in Y
than the original, so nothing derived from the old one carries over untouched.
"""
import struct
import sys

import numpy as np

PANDA_H = 160.0
Y_MID = 17.06          # Y bbox centre the old transform produced; keeps the cage
                       # roughly where it was so the comparison is apples-to-apples


def load(path, panda_h=PANDA_H, y_mid=Y_MID):
    raw = open(path, "rb").read()
    n = struct.unpack("<I", raw[80:84])[0]
    a = np.frombuffer(raw[84:], dtype=np.uint8).reshape(n, 50)
    v = a[:, 12:48].copy().view("<f4").reshape(n, 3, 3).astype(np.float64)
    zs = v[:, :, 2]
    scale = panda_h / (zs.max() - zs.min())
    v *= scale
    v[:, :, 2] -= v[:, :, 2].min()             # feet on Z=0
    v[:, :, 0] *= -1.0
    v[:, :, 1] *= -1.0
    v[:, :, 0] -= (v[:, :, 0].min() + v[:, :, 0].max()) / 2      # centre X
    v[:, :, 1] += y_mid - (v[:, :, 1].min() + v[:, :, 1].max()) / 2
    return v, scale


def surf(tris, x, z):
    """(front_y, back_y) of the surface on the ray through (x, z)."""
    a, b, c = tris[:, 0], tris[:, 1], tris[:, 2]
    lo = np.minimum(np.minimum(a, b), c)
    hi = np.maximum(np.maximum(a, b), c)
    m = (lo[:, 0] <= x) & (hi[:, 0] >= x) & (lo[:, 2] <= z) & (hi[:, 2] >= z)
    if not m.any():
        return None, None
    a, b, c = a[m], b[m], c[m]
    v0, v1 = c - a, b - a
    d00 = v0[:, 0] ** 2 + v0[:, 2] ** 2
    d01 = v0[:, 0] * v1[:, 0] + v0[:, 2] * v1[:, 2]
    d11 = v1[:, 0] ** 2 + v1[:, 2] ** 2
    px, pz = x - a[:, 0], z - a[:, 2]
    d20 = px * v0[:, 0] + pz * v0[:, 2]
    d21 = px * v1[:, 0] + pz * v1[:, 2]
    den = d00 * d11 - d01 * d01
    ok = np.abs(den) > 1e-12
    s = np.where(ok, den, 1.0)
    u = np.where(ok, (d11 * d20 - d01 * d21) / s, -1.0)
    w = np.where(ok, (d00 * d21 - d01 * d20) / s, -1.0)
    hit = ok & (u >= -1e-9) & (w >= -1e-9) & (u + w <= 1 + 1e-9)
    if not hit.any():
        return None, None
    y = a[hit, 1] + u[hit] * v0[hit, 1] + w[hit] * v1[hit, 1]
    return float(y.max()), float(y.min())


if __name__ == "__main__":
    pa, pb = sys.argv[1], sys.argv[2]
    A, sa = load(pa)
    B, sb = load(pb)
    for nm, t, s in (("A " + pa.split("/")[-1], A, sa), ("B " + pb.split("/")[-1], B, sb)):
        print(f"{nm}: {len(t)} tris, scale {s:.3f}, "
              f"X {t[:,:,0].min():7.2f}..{t[:,:,0].max():7.2f}  "
              f"Y {t[:,:,1].min():7.2f}..{t[:,:,1].max():7.2f}  "
              f"Z {t[:,:,2].min():6.2f}..{t[:,:,2].max():6.2f}")

    print("\n         |        BELLY (front Y)        |        RUMP (back Y)")
    print("  Z    X |     A       B     B-A         |     A       B     B-A")
    for z in [10, 20, 30, 40, 46, 50, 56, 62, 70, 80, 100, 120, 140]:
        for x in (0.0, 25.0):
            fa, ba = surf(A, x, z)
            fb, bb = surf(B, x, z)
            f = lambda v: "  --  " if v is None else f"{v:6.2f}"
            d = lambda p, q: "  --  " if (p is None or q is None) else f"{q-p:+6.2f}"
            print(f" {z:4d} {x:4.0f} | {f(fa)}  {f(fb)}  {d(fa,fb)}        |"
                  f" {f(ba)}  {f(bb)}  {d(ba,bb)}")
