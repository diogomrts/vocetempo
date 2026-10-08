"""Check the local entrance repair against the approved joystick-relief body.

Usage: python verify_entrance.py stl/panda_body.stl \
    --baseline stl/panda_body_joystick_relief_v2.stl

Requires numpy, trimesh and manifold3d. Checks the exported, already-printed cage
at 0.25mm insertion intervals, not just its final seated position. The entrance
must be clear; existing higher corner interference is reported separately and
must not worsen. This does not certify the physical print or electronics fit.
"""
import argparse
from pathlib import Path

import manifold3d as manifold
import numpy as np
import trimesh

ROOT = Path(__file__).resolve().parent


def solid(mesh):
    result = manifold.Manifold(manifold.Mesh(
        np.asarray(mesh.vertices, dtype=np.float32),
        np.asarray(mesh.faces, dtype=np.uint32),
    ))
    if result.status() != manifold.Error.NoError:
        raise ValueError(f"Invalid solid: {result.status()}")
    return result


def box(lo, hi):
    return manifold.Manifold.cube(np.subtract(hi, lo)).translate(lo)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("body", type=Path)
    parser.add_argument("--baseline", type=Path, required=True)
    args = parser.parse_args()
    mesh = trimesh.load_mesh(args.body)
    baseline = solid(trimesh.load_mesh(args.baseline))
    body = solid(mesh)
    cage_mesh = trimesh.load_mesh(ROOT / "stl/cage.stl")
    cage_mesh.apply_transform([
        [-1, 0, 0, 0], [0, -1, 0, 1], [0, 0, 1, 7], [0, 0, 0, 1],
    ])
    cage = solid(cage_mesh)
    failures = []

    def check(ok, message):
        print(("PASS " if ok else "FAIL ") + message, flush=True)
        if not ok:
            failures.append(message)

    check(mesh.is_watertight and mesh.is_winding_consistent and mesh.volume > 0,
          "closed, consistently oriented mesh")
    check(len(mesh.split(only_watertight=False)) == 1, "one connected body")
    removed = baseline - body
    added = (body - baseline).volume()
    check(added < 0.01, f"no added material: {added:.6f} mm^3")
    allowed = box([-38.6, 42, -0.1], [38.6, 46.2, 11.25])
    outside = abs((removed - allowed).volume())
    check(outside < 0.01,
          f"changes confined to front entrance: {outside:.6f} mm^3 outside")
    print(f"INFO removed {removed.volume():.3f} mm^3", flush=True)
    for x, y in [(38, 50), (-38, 50), (44, 17), (-44, 17)]:
        support = manifold.Manifold.cylinder(8, 4.5).translate([x, y, 11.19])
        loss = abs((removed ^ support).volume())
        check(loss < 0.01, f"magnet pocket/support ({x}, {y}) unchanged")

    entrance = box([-100, -100, -1], [100, 100, 12])
    old_entry_max = entry_max = full_max = old_full_max = 0.0
    positions = np.arange(0, 88.01, 0.25)
    for down in positions:
        moving = cage.translate([0, 0, -down])
        hit, old_hit = body ^ moving, baseline ^ moving
        entry_max = max(entry_max, abs((hit ^ entrance).volume()))
        old_entry_max = max(old_entry_max, abs((old_hit ^ entrance).volume()))
        full_max = max(full_max, abs(hit.volume()))
        old_full_max = max(old_full_max, abs(old_hit.volume()))
    check(entry_max < 0.01,
          f"entrance clear at {len(positions)} positions: maximum overlap "
          f"{entry_max:.6f} mm^3 (before {old_entry_max:.3f})")
    seated = abs((body ^ cage).volume())
    check(seated < 0.01, f"seated cage overlap {seated:.6f} mm^3")
    check(full_max <= old_full_max + 0.01, "no worse interference elsewhere")
    print(f"INFO full-body straight insertion still has {full_max:.3f} mm^3 "
          "maximum overlap at the unchanged higher corner ridges. "
          "The local entrance check is not a full insertion certification.", flush=True)
    if failures:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
