"""Find the smallest panda height that lets the components pack comfortably.

    python scale_sweep.py

The parts do NOT scale - a 2.42" OLED is 68.63 x 46.60 whatever size the panda is -
so growing the host is a way of buying back the clearances the de-embossed sculpt
took away. This is the table that chose 200mm. It reports, per candidate height, the
numbers that actually gate the design:

  plate band  contiguous run where the front face sits at the FULL cage_yfront (no
              setback), because that is the only wall the OLED can mount on
  ESP32       cover ledge + a straight USB-C plug + the 53.2mm board, portrait
  recess      belly skin minus the OLED's glass front - how deep the screen sits
  rump        depth behind the cage's back wall, which sets the joystick stalk

IT MODELS THE FOUR-COLUMN shell_prof (fit_shell.solve_setback), not a single flat
front plane. That distinction is the whole design: with one plane the front has to
clear the arm pinch at the very top, which couples cage height to screen depth and
makes every host below ~210mm look impossible.
"""
import numpy as np

from probe_skin import load, front_y
from fit_shell import solve_setback, surface

CAGE_W, CAGE_D, CAGE_Z0, CAGE_H, MARGIN = 75.0, 88.0, 7.0, 80.0, 1.6
X_FLAT = 35.5
OLED_PCB_H, SO_H_OLED = 46.60, 7.0
ESP_NEED = 6.0 + 16.0 + 53.20 + 2.0        # ledge + straight plug + board + margin
FLAT_LIM = 0.25       # fyb this small still counts as "the full front plate"


def band(rows, z0):
    """Longest contiguous run with fyb <= FLAT_LIM, in cage Z."""
    ok = [r["z"] - z0 for r in rows if r["fyb"] <= FLAT_LIM]
    if not ok:
        return 0.0, None, None
    best, run = (0.0, None, None), [ok[0]]
    step = (rows[1]["z"] - rows[0]["z"]) * 1.01
    for a, b in zip(ok, ok[1:]):
        if b - a <= step:
            run.append(b)
        else:
            if run[-1] - run[0] > best[0]:
                best = (run[-1] - run[0], run[0], run[-1])
            run = [b]
    if run[-1] - run[0] > best[0]:
        best = (run[-1] - run[0], run[0], run[-1])
    return best


if __name__ == "__main__":
    print(f"ESP32 portrait needs {ESP_NEED:.1f}mm of interior height "
          f"(ledge 6 + plug 16 + board 53.2 + margin 2)")
    print("The BOX does not scale: it has to be CAGE_H tall whatever the host, or")
    print("the ESP32 does not go in. Everything that does scale - where the cage's")
    print("front and base sit, how deep it is - is scaled from the landed 200mm")
    print("design, and the question is simply whether the sculpt can then hold it.\n")
    hdr = ("panda_h | yfront | cage_d | plate band (cage Z) | top setback | recess | "
           "rump")
    print(hdr + "\n" + "-" * len(hdr))
    for ph in (160, 180, 190, 200, 210):
        k = ph / 200.0
        yf, z0, depth = 45.0 * k, CAGE_Z0 * k, CAGE_D * k
        t = load(panda_h=float(ph))
        cage_h = CAGE_H
        zs = np.arange(z0, z0 + cage_h + 1e-9, 2.0)
        rows = solve_setback(t, zs, yfront=yf, depth=depth, margin=MARGIN,
                             x_flat=X_FLAT, step=1.0)
        h, lo, hi = band(rows, z0)
        # the OLED's window centre if its PCB is hung from the top of the plate band
        wz = z0 + (hi if hi is not None else 0) - 1 - OLED_PCB_H / 2 + 3.1
        glass = yf - 2 - SO_H_OLED + 6.23
        skin = front_y(t, 0.0, wz)
        rec = (skin - glass) if skin else float("nan")
        _, rb, _ = surface(t, 0.0, z0 + cage_h * 0.55)
        rump = (yf - depth) - rb
        top_fyb = rows[-1]["fyb"]
        print(f"  {ph:5d} | {yf:6.1f} | {depth:6.1f} | "
              f"{(lo or 0):5.1f}..{(hi or 0):5.1f} = {h:5.1f}"
              f"{'  ' if h >= OLED_PCB_H else ' !'}| "
              f"{top_fyb:8.1f}"
              f"{'   ' if depth - top_fyb >= 35 else ' ! '}| "
              f"{rec:6.1f} | {rump:5.1f}")
    print(f"\ncage_h is fixed at {CAGE_H:.0f} (interior {CAGE_H-2:.0f} vs the "
          f"{ESP_NEED:.1f} an ESP32 + straight plug needs).")
    print("! after the plate band = shorter than the OLED's 46.6mm PCB, so the "
          "screen cannot mount.")
    print("! after the top setback = less than 35mm of depth left at the top, so "
          "the speaker cannot.")
