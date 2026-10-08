"""Grow the original rump smoothly, preserving its mesh and all other features.

Historical v5 experiment; the current panda.scad does not use this sculpt.
Regenerate after changing rump_expand_* or the host transform in dimensions.scad
when reproducing v5. Requires numpy and trimesh. The derived sculpt is
in final panda millimetres; the original normalized STL is never overwritten.
Use --check to detect a missing/stale derived sculpt without writing a file.
"""
import argparse
from pathlib import Path
import re

import numpy as np
import trimesh

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "panda/panda_original_without_embosses.stl"
OUTPUT = ROOT / "panda/panda_expanded_rump.stl"


def dimensions():
    text = (ROOT / "dimensions.scad").read_text()
    names = ["panda_scale", "panda_x_off", "panda_y_off"] + [
        "rump_expand_" + suffix for suffix in
        ["back", "down", "z_full", "z_end", "y_start", "y_full", "x_full", "x_end"]
    ]
    return {name: float(re.search(
        rf"(?m)^\s*{name}\s*=\s*([-+\d.]+)\s*;", text
    ).group(1)) for name in names}


def smootherstep(t):
    t = np.clip(t, 0, 1)
    return t*t*t*(t*(6*t - 15) + 10)


def expanded_mesh():
    p = dimensions()
    mesh = trimesh.load_mesh(SOURCE)
    scale = p["panda_scale"]
    mesh.apply_transform([
        [-scale, 0, 0, p["panda_x_off"]],
        [0, -scale, 0, p["panda_y_off"]],
        [0, 0, scale, 0], [0, 0, 0, 1],
    ])
    v = mesh.vertices.copy()
    q = {key.removeprefix("rump_expand_"): value
         for key, value in p.items() if key.startswith("rump_expand_")}
    assert q["z_end"] > q["z_full"] and q["x_end"] > q["x_full"]
    assert q["y_start"] > q["y_full"] and min(q["back"], q["down"]) >= 0
    weight = (
        (1 - smootherstep((v[:, 2] - q["z_full"]) / (q["z_end"] - q["z_full"])))
        * smootherstep((q["y_start"] - v[:, 1]) / (q["y_start"] - q["y_full"]))
        * (1 - smootherstep((abs(v[:, 0]) - q["x_full"]) / (q["x_end"] - q["x_full"])))
    )
    # No X movement; Y/Z displacement fades with continuous first and second
    # derivatives. The analytic map has determinant 1 - back*dw/dy - down*dw/dz
    # >= 1 because both derivatives are non-positive, avoiding a folding warp.
    v[:, 1] -= q["back"] * weight
    v[:, 2] -= q["down"] * weight
    mesh.vertices = v
    assert mesh.is_watertight and mesh.is_winding_consistent
    # Keep the sculpt below ground here. The v5 body clipped it at Z0; clamping
    # individual vertices would instead collapse triangles along the base.
    return mesh


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    data = expanded_mesh().export(file_type="stl")
    if args.check:
        if not OUTPUT.exists() or OUTPUT.read_bytes() != data:
            raise SystemExit("Derived rump is missing/stale: run python expand_rump.py")
        print("PASS derived sculpt matches current source and dimensions")
    else:
        OUTPUT.write_bytes(data)
        print(f"Generated {OUTPUT}")


if __name__ == "__main__":
    main()
