"""Derive EVERY host-dependent constant for the de-embossed sculpt, in one pass.

    python refit.py

The replacement mesh is a different size and shape, so nothing hand-fitted to
panda_original.stl survives. This prints, ready to paste into dimensions.scad /
panda.scad:

  * panda_scale + the Y offset for panda_raw()
  * the largest cage that fits (cage_h, and where the belly pinches above the arms)
  * shell_prof, solved for the chosen cage_w / cage_d / cage_yfront
  * the OLED window Z, and the screen recess it lands at
  * the joystick's rump depth and stalk length
  * the head-resonator ellipsoid, the neck chimney, and the ear dish centres
  * a solid-body check at each magnet position
"""
import numpy as np

from probe_skin import load, scad_transform, front_y
from fit_shell import solve_setback, printable, surface

# THE LANDED ENVELOPE (dimensions.scad). Change these and re-run to re-solve.
#
# cage_d is a real trade, solved rather than guessed: deeper leaves less rump, so the
# joystick's cap stalk is shorter, but it eats the base rim the magnets need. At 88
# the rump is 25.9mm at dev_joy_pz and there is still a real flange; at 100 the rump
# is 13.9 but the hatch reaches within ~5mm of the skin front AND back.
#
# cage_z0 7 is forced by the base: at panda Z2 the belly has only reached Y40.3 at X0
# and Y28.7 at |X|34, so a front wall at Y45 cannot start any lower.
CAGE_W, CAGE_D, CAGE_YFRONT, CAGE_Z0 = 75.0, 88.0, 45.0, 7.0

# CAGE HEIGHT. On the 160mm host this was the blocker: the belly pinched to Y33.19 at
# panda Z72, capping cage_h at 64, against the 61.2mm (ledge 6 + margin 2 + board
# 53.2) a portrait ESP32 needs - and at that height its USB-C mouth landed on the
# cover ledge, so a straight plug was impossible and the panel-mount port became
# mandatory. Two things fixed it: the 200mm host, and shell_prof's fyb column, which
# lets the front plate stay at Y45 through the board zone and step back only above
# the arms. 80 gives 78mm of interior against 77.2 for board + straight plug.
CAGE_H = 80.0
MARGIN = 1.6
X_FLAT = 35.5         # the front must stay FLAT out to here (OLED PCB + bosses)
OLED_PCB_H, OLED_HOLE_DY, OLED_ACTIVE_DY = 46.60, 43.0, 3.1
BOSS_LIM = 5.0        # cf that still leaves the OLED bosses (|X|32.15) on flat wall


def hline(t):
    print("\n" + "=" * 74 + "\n" + t + "\n" + "=" * 74)


def half_width(tris, y, z):
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
    s = np.where(ok, den, 1.0)
    u = np.where(ok, (d11 * d20 - d01 * d21) / s, -1.0)
    w = np.where(ok, (d00 * d21 - d01 * d20) / s, -1.0)
    hit = ok & (u >= -1e-9) & (w >= -1e-9) & (u + w <= 1 + 1e-9)
    if not hit.any():
        return None
    x = a[hit, 0] + u[hit] * v0[hit, 0] + w[hit] * v1[hit, 0]
    return float(np.abs(x).max())


def y_hits(tris, x, z):
    """Every Y crossing on the ray through (x, z)."""
    a, b, c = tris[:, 0], tris[:, 1], tris[:, 2]
    lo = np.minimum(np.minimum(a, b), c)
    hi = np.maximum(np.maximum(a, b), c)
    m = (lo[:, 0] <= x) & (hi[:, 0] >= x) & (lo[:, 2] <= z) & (hi[:, 2] >= z)
    if not m.any():
        return np.array([])
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
    v = np.where(ok, (d00 * d21 - d01 * d20) / s, -1.0)
    hit = ok & (u >= -1e-9) & (v >= -1e-9) & (u + v <= 1 + 1e-9)
    if not hit.any():
        return np.array([])
    return np.sort(a[hit, 1] + u[hit] * v0[hit, 1] + v[hit] * v1[hit, 1])


def solid_at(tris, x, y, z):
    """Is (x, y, z) inside the body? Odd number of Y crossings before y.

    A crossing PARITY test, not `back < y < front`: at the base the feet and the
    belly are separate lobes on the same ray, so the convex version calls the gap
    between them solid and happily puts a magnet in mid-air.
    """
    h = y_hits(tris, x, z)
    return bool(h.size) and int((h < y).sum()) % 2 == 1


t = load()

# ---- 1. the transform ------------------------------------------------------
hline("1. panda_raw() transform")
s, xo, yo = scad_transform()
print(f"panda_scale  = {s:.4f}")
print(f"panda_x_off  = {xo:.3f}   (was implicitly 0; the old mesh was 0.44 off-centre)")
print(f"panda_y_off  = {yo:.3f}   (was 26)")
print(f"resulting bbox: X {t[:,:,0].min():.2f}..{t[:,:,0].max():.2f}  "
      f"Y {t[:,:,1].min():.2f}..{t[:,:,1].max():.2f}  Z 0..{t[:,:,2].max():.2f}")

# ---- 2. how tall can the cage be? -----------------------------------------
hline("2. cage height: where the belly pinches above the arms")
print("  A flat front face at panda Y%.0f needs the belly >= %.1f everywhere." %
      (CAGE_YFRONT, CAGE_YFRONT + MARGIN))
print("  pandaZ | belly@X0 | margin | verdict")
zc = None
for z in range(56, 86, 2):
    y = front_y(t, 0.0, z)
    m = y - (CAGE_YFRONT + MARGIN)
    v = "ok" if m > 0 else "PINCHED - front face cannot reach here"
    if m <= 0 and zc is None:
        zc = z
    print(f"   {z:4d}  |  {y:7.2f} | {m:6.2f} | {v}")
print(f"\n  -> the front face dies at panda Z{zc}; keep the cage top below it.")

# ---- 3. shell_prof --------------------------------------------------------
hline("3. shell_prof  (paste straight into dimensions.scad)")

print(f"assuming cage_z0 {CAGE_Z0}, cage_h {CAGE_H} -> top at panda Z{CAGE_Z0+CAGE_H}")
zs = np.arange(CAGE_Z0, CAGE_Z0 + CAGE_H + 1e-9, 2.0)
rows = solve_setback(t, zs, yfront=CAGE_YFRONT, depth=CAGE_D, margin=MARGIN,
                     x_flat=X_FLAT, step=0.5)
# printable(): a chamfer SHRINKING as Z rises means the cross-section GROWS - an
# overhang - so limit how fast it may shrink to 1mm per 1mm of Z. Growing is free.
cfh = printable([r["cf"] for r in rows], 2.0)
cbh = printable([r["cb"] for r in rows], 2.0)
print("shell_prof = [\n  // z      cf      cb     fyb")
for r, a, b in zip(rows, cfh, cbh):
    print(f"  [{r['z']-CAGE_Z0:5.1f}, {a:6.2f}, {b:6.2f}, {r['fyb']:6.2f}],")
print("];")
flat = [r["z"] - CAGE_Z0 for r, a in zip(rows, cfh) if a <= BOSS_LIM]
print(f"\nOLED-usable band (cf <= {BOSS_LIM}): cage Z {min(flat):.1f}..{max(flat):.1f}"
      f"  = {max(flat)-min(flat):.1f}mm  (need {OLED_PCB_H})")
nofyb = [r["z"] - CAGE_Z0 for r in rows if r["fyb"] <= 0.25]
print(f"front plate at the FULL Y{CAGE_YFRONT:.0f}: cage Z {min(nofyb):.1f}.."
      f"{max(nofyb):.1f} - the OLED has to live inside this")

# ---- 4. OLED placement ----------------------------------------------------
hline("4. OLED placement + screen recess")
top = max(nofyb) - 1.0
pcb_c = top - OLED_PCB_H / 2
win_c = pcb_c + OLED_ACTIVE_DY
print(f"PCB top at cage Z{top:.1f} -> PCB centre cage Z{pcb_c:.1f}"
      f" (spans {pcb_c-OLED_PCB_H/2:.1f}..{top:.1f})")
print(f"bosses at cage Z{pcb_c-OLED_HOLE_DY/2:.1f} and {pcb_c+OLED_HOLE_DY/2:.1f}")
print(f"-> dev_oled_pz = {win_c + CAGE_Z0:.1f}  (panda Z of the lit-window centre)")
for so in (7, 2):
    glass = CAGE_YFRONT - 2 - so + 6.23
    skin = front_y(t, 0.0, win_c + CAGE_Z0)
    print(f"   so_h_oled {so}: glass at panda Y{glass:.2f}, belly {skin:.2f}"
          f" -> recess {skin-glass:.1f}mm")

# ---- 5. joystick on the rump ----------------------------------------------
hline("5. joystick on the rump (standoffs on the back wall's OUTER face)")
back = CAGE_YFRONT - CAGE_D
pcb = back - 2.0                 # 2mm standoff off the outer face
shoulder = pcb - 0.92 - 11.76    # PCB + gimbal body: where the cap bottoms out
print(f"cage back OUTER face at panda Y{back:.1f}"
      f" -> PCB {pcb:.2f}, gimbal top {shoulder:.2f}"
      f" ({back - shoulder:.2f}mm proud of the wall)")
print("  pandaZ | rump@X0 | depth behind the cage | joy_cap_stalk")
best = None
for z in range(20, 70, 4):
    _, b, _ = surface(t, 0.0, z)
    d = back - b
    print(f"   {z:4d}  | {b:7.2f} | {d:20.2f} | {shoulder - b:6.2f}")
    if best is None or d > best[1]:
        best = (z, d)
print(f"\n  deepest at panda Z{best[0]} ({best[1]:.1f}mm)")

# ---- 6. head resonator + neck --------------------------------------------
hline("6. head resonator ellipsoid + neck chimney")
zs_head = [z for z in range(100, 200, 5)]
print("  pandaZ | half-width | belly  | rump   | mid-Y")
for z in zs_head:
    hw = half_width(t, -5.0, z)
    f, b, _ = surface(t, 0.0, z)
    if hw is None or f is None:
        continue
    print(f"   {z:4d}  | {hw:10.2f} | {f:6.2f} | {b:6.2f} | {(f+b)/2:6.2f}")

# ---- 7. ear inner dish, by triangle density ------------------------------
hline("7. ear inner dish (stipple = high triangle density)")
# The stipple is ~4x denser than smooth skin, but it is RANDOMISED, so the single
# densest cell wanders by 8mm between runs and bin sizes. Take the CENTROID of the
# dense region instead, and only count FRONT-FACING triangles - the dish faces +Y,
# and the ear's back skin is just as finely tessellated in places.
cen = t.mean(axis=1)
nrm = np.cross(t[:, 1] - t[:, 0], t[:, 2] - t[:, 0])
ln = np.linalg.norm(nrm, axis=1)
ny = nrm[:, 1] / np.where(ln == 0, 1.0, ln)
m = ((cen[:, 0] > 38) & (cen[:, 0] < 68)
     & (cen[:, 2] > 168) & (cen[:, 2] < 198) & (ny > 0.2))
ear = cen[m]
if len(ear) > 100:
    H, xe, ze = np.histogram2d(ear[:, 0], ear[:, 2], bins=24)
    xc = (xe[:-1] + xe[1:]) / 2
    zc = (ze[:-1] + ze[1:]) / 2
    thr = np.percentile(H, 85)
    ii, jj = np.where(H >= thr)
    w = H[ii, jj]
    cx = float(np.average(xc[ii], weights=w))
    cz = float(np.average(zc[jj], weights=w))
    print(f"right ear: {len(ear)} front-facing tris, densest 15% of cells centred at")
    near = ear[(np.abs(ear[:, 0] - cx) < 8) & (np.abs(ear[:, 2] - cz) < 8)]
    print(f"  dish Y range there: {near[:,1].min():.2f}..{near[:,1].max():.2f}")
    print(f"  -> ear_cx {cx:.2f}, ear_cz {cz:.2f}")
    print("  (ear_ang does NOT scale with the host; nor do ear_hole_d / ear_pitch.")
    print("   Every ear_* Y value must be RE-MEASURED, not rescaled - the panda")
    print("   frame moved when panda_y_off stopped being hand-fitted.)")
else:
    print("  no ear triangles found in the search box - widen it")

# ---- 8. magnets ----------------------------------------------------------
hline("8. magnet positions (cage frame -> panda, must be in solid body)")
cage_yc = CAGE_YFRONT - CAGE_D / 2
rebate_h = CAGE_Z0 + 4.2
mag = [[38, -49], [-38, -49], [44, -16], [-44, -16]]
hatch_y = (cage_yc - (CAGE_D + 2) / 2, cage_yc + (CAGE_D + 2) / 2)
print(f"cage_yc {cage_yc:.1f}, rebate ceiling panda Z{rebate_h:.1f}, "
      f"hatch spans |X|<={(CAGE_W+2)/2:.1f}, Y {hatch_y[0]:.1f}..{hatch_y[1]:.1f}")
print("  'body pocket' = the magnet + 4mm of wall, over panda Z11.2..15.7")
print("  'flange ear'  = the ear that reaches it, over panda Z7.2..11.2")
for p in mag:
    px, py = -p[0], cage_yc - p[1]
    inside_hatch = abs(px) <= (CAGE_W + 2) / 2 and hatch_y[0] <= py <= hatch_y[1]
    pocket = all(solid_at(t, px + dx, py + dy, z)
                 for dx in (-4, 0, 4) for dy in (-4, 0, 4)
                 for z in (rebate_h, rebate_h + 2.25, rebate_h + 4.5))
    ear = all(solid_at(t, px + dx, py + dy, z)
              for dx in (-4.5, 0, 4.5) for dy in (-4.5, 0, 4.5)
              for z in (CAGE_Z0 + 0.2, rebate_h))
    print(f"  cage({p[0]:+4d},{p[1]:+4d}) -> panda({px:+6.1f},{py:+6.1f}) "
          f"| body pocket: {'YES' if pocket else 'NO '} "
          f"| flange ear: {'YES' if ear else 'NO '} "
          f"| outside hatch: {'no  <-- BAD' if inside_hatch else 'yes'}")
