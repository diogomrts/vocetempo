"""Check the exported cage against what every component actually needs.

    openscad -o /tmp/cage.stl --export-format binstl -D 'part="cage"' cage.scad
    python verify_cage.py /tmp/cage.stl

Ray-casts the exported mesh and asserts the things that went wrong on the first
test print, so they cannot silently come back:

  1. all four OLED bosses stand on FULL-DEPTH flat wall (the top pair were 0.69mm
     dimples in a chamfer),
  2. nothing in the shell intrudes into the OLED PCB's envelope,
  3. the joystick's four standoffs stand proud of the back wall's OUTER face, and
     its wire slot is open through that wall,
  4. the base opening is open (the hatch has to pass the whole cage),
  5. the base-cover ledge has material under every screw position,
  6. the side-wall bosses stop where the boards mount.

Values come from dimensions.scad; keep them in step if you edit it.
"""
import struct
import sys

import numpy as np

# --- from dimensions.scad -----------------------------------------------------
W, H, D, T = 75.0, 80.0, 88.0, 2.0
OLED_PCB_W, OLED_PCB_H = 68.63, 46.60
OLED_HDX, OLED_HDY = 64.3, 43.0
DEV_OLED_PZ, CAGE_Z0, ACTIVE_DY = 47.8, 7.0, 3.1
SO_H_OLED = 7.0
DEV_JOY_PZ = 50.0
JOY_PCB_W, JOY_PCB_H = 26.70, 32.30       # sideways: _h across X, _w up Z
JOY_HDX, JOY_HDZ = 26.0, 19.85            # sideways: hole pitch across X / up Z
                                          # (26.0 = the long-axis pitch; corrected
                                          #  2026-08-24 from the misread 19.80)
JOY_SO_H = 2.0
JOY_WIRE_W, JOY_WIRE_H = 16.0, 5.0
SO_SIDE = 12.0
COVER_LEDGE_H = 6.0
ESP_CZ, RTC_CZ, SIDE_Y0 = 50.0, 40.0, -26.0
ESP_H, ESP_W, RTC_H, RTC_W = 28.40, 53.20, 22.0, 38.0
COVER_SCREWS = [(33, 0), (-33, 0), (25, -38.5), (-25, -38.5), (25, 40), (-25, 40)]

OLED_CZ = DEV_OLED_PZ - CAGE_Z0 - ACTIVE_DY      # 37.7
JOY_CZ = DEV_JOY_PZ - CAGE_Z0                    # 43.0
FRONT_Y, BACK_Y, BACK_YO = -D / 2, D / 2 - T, D / 2

fails = []


def check(ok, msg):
    print(("   ok  " if ok else "  FAIL ") + msg)
    if not ok:
        fails.append(msg)


def load(path):
    raw = open(path, "rb").read()
    n = struct.unpack("<I", raw[80:84])[0]
    a = np.frombuffer(raw[84:], dtype=np.uint8).reshape(n, 50)
    return a[:, 12:48].copy().view("<f4").reshape(n, 3, 3).astype(np.float64)


def cast(tris, axis, u, v):
    """All surface coordinates along `axis` on the ray through the other two.

    axis 0/1/2 = X/Y/Z; (u, v) are the remaining two coordinates in order.
    """
    i, j = [k for k in (0, 1, 2) if k != axis]
    a, b, c = tris[:, 0], tris[:, 1], tris[:, 2]
    lo = np.minimum(np.minimum(a, b), c)
    hi = np.maximum(np.maximum(a, b), c)
    m = (lo[:, i] <= u) & (hi[:, i] >= u) & (lo[:, j] <= v) & (hi[:, j] >= v)
    if not m.any():
        return np.array([])
    a, b, c = a[m], b[m], c[m]
    v0, v1 = c - a, b - a
    d00 = v0[:, i] ** 2 + v0[:, j] ** 2
    d01 = v0[:, i] * v1[:, i] + v0[:, j] * v1[:, j]
    d11 = v1[:, i] ** 2 + v1[:, j] ** 2
    pu, pv = u - a[:, i], v - a[:, j]
    d20 = pu * v0[:, i] + pv * v0[:, j]
    d21 = pu * v1[:, i] + pv * v1[:, j]
    den = d00 * d11 - d01 * d01
    ok = np.abs(den) > 1e-12
    s = np.where(ok, den, 1.0)
    bu = np.where(ok, (d11 * d20 - d01 * d21) / s, -1.0)
    bv = np.where(ok, (d00 * d21 - d01 * d20) / s, -1.0)
    hit = ok & (bu >= -1e-9) & (bv >= -1e-9) & (bu + bv <= 1 + 1e-9)
    if not hit.any():
        return np.array([])
    return a[hit, axis] + bu[hit] * v0[hit, axis] + bv[hit] * v1[hit, axis]


def solid_at(tris, axis, u, v, lo, hi):
    """Is there any surface along `axis` between lo and hi on that ray?"""
    h = cast(tris, axis, u, v)
    return bool(((h >= lo) & (h <= hi)).any())


def frontmost(tris, x, z):
    h = cast(tris, 1, x, z)
    return None if h.size == 0 else float(h.min())


if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/cage.stl"
    tris = load(path)
    bb = [(tris[:, :, k].min(), tris[:, :, k].max()) for k in (0, 1, 2)]
    print(f"{len(tris)} facets   X {bb[0][0]:.2f}..{bb[0][1]:.2f}   "
          f"Y {bb[1][0]:.2f}..{bb[1][1]:.2f}   Z {bb[2][0]:.2f}..{bb[2][1]:.2f}\n")
    check(abs(bb[2][1] - H) < 0.01, f"cage height {bb[2][1]:.2f} == {H}")

    # 1. OLED bosses on flat wall -------------------------------------------
    print("-- OLED bosses (PCB face must be at y "
          f"{FRONT_Y + T + SO_H_OLED:.2f}) --")
    for sz in (-1, 1):
        z = OLED_CZ + sz * OLED_HDY / 2
        for sx in (-1, 1):
            x = sx * OLED_HDX / 2
            fy = frontmost(tris, x, z)
            check(fy is not None and abs(fy - FRONT_Y) < 0.05,
                  f"boss x{x:+7.2f} cageZ{z:6.2f}: wall front {fy:.2f}"
                  f" (want {FRONT_Y:.2f} - full flat wall)")

    # 2. OLED envelope clear -------------------------------------------------
    # The OLED occupies y = pcb_face .. pcb_face + PCB + header. Anything the shell
    # puts in that band, inside the PCB's outline, fouls the screen. Look only at
    # that band - further back is the cavity and legitimately full of other parts.
    print("\n-- OLED envelope (PCB + its 6.32mm header must be unobstructed) --")
    pcb_face = FRONT_Y + T + SO_H_OLED
    pcb_back = pcb_face + 0.98 + 6.32
    worst = (None, 0.0)
    for x in np.arange(-OLED_PCB_W / 2, OLED_PCB_W / 2 + 0.01, 2.0):
        for z in np.arange(OLED_CZ - OLED_PCB_H / 2, OLED_CZ + OLED_PCB_H / 2 + 0.01, 2.0):
            if abs(abs(x) - OLED_HDX / 2) < 3.5 and \
               min(abs(z - (OLED_CZ - OLED_HDY / 2)),
                   abs(z - (OLED_CZ + OLED_HDY / 2))) < 3.5:
                continue                      # that is the boss itself
            h = cast(tris, 1, x, z)
            inside = h[(h > pcb_face + 0.05) & (h < pcb_back - 0.05)]
            if inside.size:
                d = float(inside.max() - pcb_face)
                if d > worst[1]:
                    worst = ((round(x, 1), round(z, 1)), d)
    check(worst[0] is None,
          "nothing intrudes into the OLED's y-band "
          f"({pcb_face:.2f}..{pcb_back:.2f})"
          + (f" - worst {worst[1]:.2f}mm at {worst[0]}" if worst[0] else ""))

    # 3. joystick standoffs on the back wall's OUTER face --------------------
    print("\n-- joystick standoffs, OUTSIDE the back wall (cage Z"
          f"{JOY_CZ:.1f}) --")
    want_top = BACK_YO + JOY_SO_H
    for sx in (-1, 1):
        for sz in (-1, 1):
            x = sx * JOY_HDX / 2
            z = JOY_CZ + sz * JOY_HDZ / 2
            # 2mm off the boss axis: down the middle you only see the screw pilot
            h = cast(tris, 1, x + 2.0, z)
            near = h[np.abs(h - want_top) < 0.3]
            check(near.size > 0,
                  f"standoff x{x:+6.2f} cageZ{z:6.2f}: face at y{want_top:.2f}"
                  f" (found {np.round(np.unique(np.round(h, 1)), 1)})")
    check(not solid_at(tris, 1, 0, JOY_CZ - JOY_PCB_W / 2 - 3,
                       BACK_Y - 0.5, BACK_YO + 0.5),
          "wire slot is open through the back wall")
    # nothing may stand INSIDE the back wall behind the joystick any more
    h = cast(tris, 1, 0.0, JOY_CZ)
    check(not ((h > BACK_YO - 30) & (h < BACK_Y - 0.05)).any(),
          "no plinth/pocket left on the inner face behind the joystick")

    # 3b. speaker ear-boss pilots open from BELOW ----------------------------
    # The ear screws come UP from inside the cage, so each pilot must open on the
    # boss's bottom face. screw_boss() bores from the buried (+wall) end; before
    # top_boss() bored its own hole from below, all four pilots were sealed
    # internal voids with a 1mm cap right across the screw's entry.
    print("\n-- speaker ear bosses (pilot must be open at the bottom face) --")
    SPK_EAR_DX, SPK_EAR_DY, SPK_CY_OFF = 63.6, 21.2, 8.0
    spk_boss_bot = H - T - 6.0
    for sx in (-1, 1):
        for sy in (-1, 1):
            x, y = sx * SPK_EAR_DX / 2, SPK_CY_OFF + sy * SPK_EAR_DY / 2
            h = cast(tris, 2, x, y)
            sealed = ((h >= spk_boss_bot - 0.05) & (h <= spk_boss_bot + 1.05)).any()
            check(not sealed,
                  f"speaker boss ({x:+5.1f},{y:+5.1f}): pilot open from below"
                  + (f" - plastic at Z{np.unique(np.round(h[(h >= spk_boss_bot - 0.05) & (h <= spk_boss_bot + 1.05)], 2))}"
                     if sealed else ""))

    # 3c. joystick pilots deep enough for an M3x4 ----------------------------
    # back_boss_out()'s own pilot stops at the wall's outer face (the shell union
    # refills anything deeper), leaving 2mm of thread - an M3x4 through the PCB
    # bottoms out 1mm before its head seats. joystick_pilot_cuts() must carry each
    # pilot into the wall to a usable >= 3.3mm.
    print("\n-- joystick pilot depth (want >= 3.3mm; blind, not through) --")
    for sx in (-1, 1):
        for sz in (-1, 1):
            x, z = sx * JOY_HDX / 2, JOY_CZ + sz * JOY_HDZ / 2
            h = cast(tris, 1, x, z)
            mouth = BACK_YO + JOY_SO_H
            # The pilot bottom is the LAST surface before the mouth (the blind
            # face). min() would grab the wall's INNER face at y42 and report a
            # 4mm depth even with no pilot cut at all - a false pass.
            inr = h[(h > BACK_Y + 0.05) & (h < mouth - 0.05)]
            bottom = float(inr.max()) if inr.size else None
            depth = None if bottom is None else mouth - bottom
            check(depth is not None and depth >= 3.3,
                  f"pilot ({x:+5.1f},z{z:5.1f}): usable depth "
                  + (f"{depth:.2f}mm (blind at y{bottom:.2f})" if depth is not None
                     else "NONE - pilot is through or missing"))

    # 4. base opening -------------------------------------------------------
    print("\n-- base hatch --")
    for x, y, lbl in [(0, 10, "centre"), (0, -20, "centre-front"), (20, -10, "front-right")]:
        h = cast(tris, 2, float(x), float(y))
        low = h[(h >= -0.01) & (h <= 5.0)]
        check(low.size == 0,
              f"base is open at ({x},{y}) [{lbl}]"
              + (f" - found floor at Z{np.unique(np.round(low, 2))}" if low.size else ""))

    # 5. cover ledge --------------------------------------------------------
    # Probe 3mm to the side of each screw: straight down the hole there is (by
    # design) no material at all.
    print("\n-- base-cover ledge --")
    for (x, y) in COVER_SCREWS:
        ox = x + (3.0 if abs(y) > 10 else 0.0)
        oy = y + (0.0 if abs(y) > 10 else 3.0)
        h = cast(tris, 2, ox, oy)
        got = h[(h >= -0.01) & (h <= COVER_LEDGE_H + 0.01)]
        check(got.size > 0, f"ledge material beside screw ({x:+5.1f},{y:+6.1f})")

    # 6. side-wall bosses ---------------------------------------------------
    # Probe the actual boss centres, not the board centre.
    print("\n-- side-wall boss tops (should stand SO_SIDE off the inner face) --")
    esp_cy, esp_span = SIDE_Y0 + ESP_H / 2, ESP_W - 4
    rtc_cy = SIDE_Y0 + RTC_H / 2
    bosses = [(-1, esp_cy, ESP_CZ - esp_span / 2, "ESP32 lower"),
              (-1, esp_cy, ESP_CZ + esp_span / 2, "ESP32 upper"),
              (1, rtc_cy + (11 - RTC_H / 2), RTC_CZ + (4 - RTC_W / 2), "RTC far hole")]
    for sx, y, z, lbl in bosses:
        # 2mm off the boss axis: straight down the middle you only see the bottom
        # of the screw pilot, which is insert_pilot_depth further back.
        h = cast(tris, 0, y + 2.0, z)
        want = sx * (W / 2 - T - SO_SIDE)
        near = h[np.abs(h - want) < 0.8]
        check(near.size > 0,
              f"{lbl}: boss face near x{want:+.2f}"
              f" (found {np.round(np.unique(np.round(h, 1)), 1)})")

    print()
    if fails:
        print("FAILED:")
        for f in fails:
            print("   * " + f)
        sys.exit(1)
    print("ALL CHECKS PASSED")
