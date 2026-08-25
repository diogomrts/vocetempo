"""Solve the cage's shell profile (and its Y placement) against the real sculpt.

    python fit_shell.py                 # report for the current dimensions.scad
    python fit_shell.py --yfront 48     # try a different cage_yfront

WHY THIS EXISTS. shell_prof in dimensions.scad was hand-tuned, and it is wrong in
both directions: it chamfers the FRONT corners away from Z62 upward where the skin
is still 14mm clear (which ate the OLED's two top standoffs - the boss ended up as
a 0.5mm dimple in a diagonal face, i.e. "the screw holes are covered by plastic"),
while the first REAL breach is higher up. This computes the requirement instead of
guessing it.

MODEL. The cage cross-section at height z is a cage_w x cage_d rectangle whose
front corners are cut by cf and back corners by cb (see helpers.scad
shell_section). The front face sits at panda Y = yfront, the back at
yfront - cage_d. A point on the chamfered front at |x| is at

    Yshell(x) = yfront - max(0, |x| - (hw - cf))

and it must stay `margin` inside the skin, Yshell(x) <= S(x, z) - margin, so

    cf >= (yfront + margin - S(x, z)) + hw - |x|      for every |x| <= hw

which is a max over a scan in x. Same algebra on the back with the rear skin.
Everything is in PANDA coordinates (the cage frame is mirrored; dimensions.scad
maps them with panda_Y = cage_yc - cage_y).
"""
import argparse

import numpy as np

from probe_skin import load

HW = 75 / 2.0          # cage_w/2
DEPTH = 88.0           # cage_d
YFRONT = 45.0          # cage_yfront
MARGIN = 1.6           # min body wall the shell must leave (cav_min 1.4 + a hair)


def surface(tris, x, z):
    """(front_y, back_y, hit_count) of the skin on the ray through (x, z) along Y."""
    a, b, c = tris[:, 0], tris[:, 1], tris[:, 2]
    lo = np.minimum(np.minimum(a, b), c)
    hi = np.maximum(np.maximum(a, b), c)
    m = (lo[:, 0] <= x) & (hi[:, 0] >= x) & (lo[:, 2] <= z) & (hi[:, 2] >= z)
    if not m.any():
        return None, None, 0
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
    safe = np.where(ok, den, 1.0)
    u = np.where(ok, (d11 * d20 - d01 * d21) / safe, -1.0)
    v = np.where(ok, (d00 * d21 - d01 * d20) / safe, -1.0)
    hit = ok & (u >= -1e-9) & (v >= -1e-9) & (u + v <= 1 + 1e-9)
    if not hit.any():
        return None, None, 0
    y = a[hit, 1] + u[hit] * v0[hit, 1] + v[hit] * v1[hit, 1]
    return float(y.max()), float(y.min()), int(hit.sum())


def solve(tris, zs, yfront=YFRONT, hw=HW, depth=DEPTH, margin=MARGIN, step=0.5):
    xs = np.arange(0.0, hw + 1e-9, step)
    yback = yfront - depth
    rows = []
    for z in zs:
        cf = cb = 0.0
        cf_at = cb_at = None
        front = {}
        for x in xs:
            fy, by, n = surface(tris, x, z)
            if fy is None:
                # no body at all here: the corner must be cut back to this x
                need_f = need_b = 1e9
            else:
                need_f = yfront + margin - fy
                need_b = by + margin - yback
            front[x] = fy
            if need_f > 0:
                want = min(need_f + hw - x, hw - 1)
                if want > cf:
                    cf, cf_at = want, x
            if need_b > 0:
                want = min(need_b + hw - x, hw - 1)
                if want > cb:
                    cb, cb_at = want, x
        rows.append(dict(z=z, cf=cf, cf_at=cf_at, cb=cb, cb_at=cb_at,
                         y0=front.get(0.0)))
    return rows


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--yfront", type=float, default=YFRONT)
    ap.add_argument("--margin", type=float, default=MARGIN)
    ap.add_argument("--z0", type=float, default=0)
    ap.add_argument("--z1", type=float, default=90)
    ap.add_argument("--dz", type=float, default=2)
    a = ap.parse_args()

    tris = load()
    zs = np.arange(a.z0, a.z1 + 1e-9, a.dz)
    rows = solve(tris, zs, yfront=a.yfront, margin=a.margin)
    print(f"cage front face at panda Y{a.yfront}, back Y{a.yfront - DEPTH}, "
          f"half-width {HW}, min body wall {a.margin}\n")
    print("  pandaZ | cageZ | belly Y @X0 | cf needed (at X) | cb needed (at X)")
    for r in rows:
        y0 = "  --  " if r["y0"] is None else f"{r['y0']:6.2f}"
        cfa = "" if r["cf_at"] is None else f" @{r['cf_at']:.1f}"
        cba = "" if r["cb_at"] is None else f" @{r['cb_at']:.1f}"
        print(f"  {r['z']:6.1f} | {r['z']-2:5.1f} | {y0}      | "
              f"{r['cf']:7.2f}{cfa:>7} | {r['cb']:7.2f}{cba:>7}")


def solve_setback(tris, zs, yfront, depth, hw=HW, margin=MARGIN,
                  x_flat=35.5, step=0.5):
    """Solve [cf, cb, fyb] per height, with a per-height FRONT SETBACK.

    Policy: the front face must stay FLAT out to |x| <= x_flat, because that is what
    the OLED's mounting bosses (|X|32.15) and its 68.63mm PCB need. So first pull the
    whole front face back by however much that flat span demands (fyb), then chamfer
    only the corners beyond it (cf). Everything past x_flat is feature-free, so it is
    cheaper to cut than to move the wall.
    """
    xs_flat = np.arange(0.0, x_flat + 1e-9, step)
    xs_all = np.arange(0.0, hw + 1e-9, step)
    yback = yfront - depth
    rows = []
    for z in zs:
        skin = {}
        for x in xs_all:
            fy, by, _ = surface(tris, x, z)
            skin[x] = (fy, by)
        # 1. setback: how far back must the flat span sit?
        need = [yfront + margin - skin[x][0] for x in xs_flat
                if skin[x][0] is not None]
        fyb = max(0.0, max(need) if need else 0.0)
        front = yfront - fyb
        # 2. corner chamfers against the moved front, and the back as usual
        cf = cb = 0.0
        for x in xs_all:
            fy, by = skin[x]
            nf = 1e9 if fy is None else front + margin - fy
            nb = 1e9 if by is None else by + margin - yback
            if nf > 0:
                cf = max(cf, min(nf + hw - x, hw - 1))
            if nb > 0:
                cb = max(cb, min(nb + hw - x, hw - 1))
        rows.append(dict(z=z, cf=cf, cb=cb, fyb=fyb))
    return rows


def printable(req, dz):
    """Limit how fast a chamfer may SHRINK as Z rises (45 deg), so the section never
    grows faster than a printer can overhang. Growing is free - that is a step in."""
    out = list(req)
    for i in range(1, len(out)):
        out[i] = max(out[i], out[i - 1] - dz)
    return out
