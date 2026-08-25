"""Envelope probe: how big a box fits inside the panda at each height?

    python probe_env.py

For each Z it reports the sculpt's half-width at the cage's Y band, the belly
(front) Y on the centreline, and the rump (back) Y - i.e. everything needed to
decide how tall/wide/deep the cage can be and where a control can protrude.
Same load/orientation as probe_skin.py.
"""
import numpy as np

from probe_skin import load
from fit_shell import surface


def half_width(tris, y, z):
    """Largest |X| on the surface at (y, z) - the ray runs along X."""
    a, b, c = tris[:, 0], tris[:, 1], tris[:, 2]
    lo = np.minimum(np.minimum(a, b), c)
    hi = np.maximum(np.maximum(a, b), c)
    m = (lo[:, 1] <= y) & (hi[:, 1] >= y) & (lo[:, 2] <= z) & (hi[:, 2] >= z)
    if not m.any():
        return None
    a, b, c = a[m], b[m], c[m]
    v0, v1 = c - a, b - a
    d00 = v0[:, 1] ** 2 + v0[:, 2] ** 2
    d01 = v0[:, 1] * v1[:, 1] + v0[:, 2] * v1[:, 2]
    d11 = v1[:, 1] ** 2 + v1[:, 2] ** 2
    py, pz = y - a[:, 1], z - a[:, 2]
    d20 = py * v0[:, 1] + pz * v0[:, 2]
    d21 = py * v1[:, 1] + pz * v1[:, 2]
    den = d00 * d11 - d01 * d01
    ok = np.abs(den) > 1e-12
    safe = np.where(ok, den, 1.0)
    u = np.where(ok, (d11 * d20 - d01 * d21) / safe, -1.0)
    v = np.where(ok, (d00 * d21 - d01 * d20) / safe, -1.0)
    hit = ok & (u >= -1e-9) & (v >= -1e-9) & (u + v <= 1 + 1e-9)
    if not hit.any():
        return None
    x = a[hit, 0] + u[hit] * v0[hit, 0] + v[hit] * v1[hit, 0]
    return float(np.abs(x).max())


if __name__ == "__main__":
    tris = load()
    print("  Z   | belly Y @X0 | rump Y @X0 | half-width @Y0 | @Y-15 | @Y+20")
    for z in range(2, 132, 4):
        fy, by, _ = surface(tris, 0.0, z)
        hw0 = half_width(tris, 0.0, z)
        hwb = half_width(tris, -15.0, z)
        hwf = half_width(tris, 20.0, z)
        f = lambda v: "  --  " if v is None else f"{v:6.2f}"
        print(f" {z:4d} | {f(fy)}      | {f(by)}     | {f(hw0)}         "
              f"| {f(hwb)} | {f(hwf)}")
