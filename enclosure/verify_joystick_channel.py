"""Check the panda's fixed rear channel with the requested extra assembly room.

Run from enclosure/ after exporting panda.scad:
    python verify_joystick_channel.py stl/panda_body.stl
    python verify_joystick_channel.py stl/panda_body.stl --baseline old_body.stl

Dependencies: numpy, trimesh, manifold3d, scipy, rtree.
The swept envelopes include 3mm EXTRA PCB stand-off beyond the recorded 2mm,
the bare shaft, and both bent-header orientations. PCB/gimbal X/Z bounds also
cover either 90-degree in-plane orientation. The larger left-side envelope is
a clearance allowance requested from the physical assembly, not a measured model
of the component. These checks do not certify an unmeasured physical assembly.
"""
import argparse
from pathlib import Path

import numpy as np
import trimesh


ROOT = Path(__file__).resolve().parent


def box(lo, hi):
    lo, hi = np.asarray(lo), np.asarray(hi)
    result = trimesh.creation.box(hi - lo)
    result.apply_translation((hi + lo) / 2)
    return result


def boolean(operation, *meshes):
    return getattr(trimesh.boolean, operation)(
        meshes, engine="manifold", check_volume=False
    )


def volume(mesh):
    return 0.0 if mesh.is_empty else abs(mesh.volume)


def rear_wall_samples(body, skin_path=None):
    """Nearest exterior distance from channel walls on a 0.5 mm X/Z grid.

    Z25 is above the enlarged underside entrance and its taper. Only the known
    USB/cap openings are excluded. Elsewhere, a missing outer hit is a failure,
    so an accidental breakthrough cannot silently disappear from the samples.
    This is a geometric check, not a strength simulation.
    """
    if skin_path is None:
        skin = trimesh.load_mesh(ROOT / "panda/panda_original_without_embosses.stl")
        skin.apply_transform(np.array([
            [-212.9096, 0, 0, 0], [0, -212.9096, 0, 9.036],
            [0, 0, 212.9096, 0], [0, 0, 0, 1],
        ]))
    else:
        # A derived outer sculpt is already in final panda millimetres.
        skin = trimesh.load_mesh(skin_path)
    x, z = np.meshgrid(np.arange(-22.75, 23, 0.5), np.arange(25, 75.36, 0.5))
    origins = np.column_stack([x.ravel(), np.full(x.size, -80), z.ravel()])
    cap = origins[:, 0]**2 + (origins[:, 2] - 50)**2 <= 7.5**2
    usb = (abs(origins[:, 0] - 19.3) < 15) & (abs(origins[:, 2] - 29) < 10)
    origins = origins[~(cap | usb)]
    directions = np.tile([0, 1, 0], (len(origins), 1))
    points, rays, _ = body.ray.intersects_location(origins, directions)
    selected = points[:, 1] < -41
    points, rays = points[selected], rays[selected]
    order = np.lexsort((points[:, 1], rays))
    points, rays = points[order], rays[order]
    _, starts, counts = np.unique(rays, return_index=True, return_counts=True)
    starts = starts[counts >= 2]
    outer, inner = points[starts], points[starts + 1]
    _, outer_distance, _ = trimesh.proximity.closest_point(skin, outer)
    missing = len(origins) - int(np.count_nonzero(outer_distance < 0.03))
    inner = inner[outer_distance < 0.03]
    if len(inner) == 0:
        raise AssertionError("No intact rear wall found on the sampling grid")
    _, distances, _ = trimesh.proximity.closest_point(skin, inner)
    index = np.argmin(distances)
    return float(distances[index]), inner[index], len(distances), missing


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("body", type=Path)
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--skin", type=Path, help="outer sculpt in final panda mm (e.g. fitcheck body_blank)")
    args = parser.parse_args()
    body = trimesh.load_mesh(args.body)
    failures = []

    def check(ok, message):
        print(("PASS " if ok else "FAIL ") + message, flush=True)
        if not ok:
            failures.append(message)

    check(body.is_watertight and body.is_winding_consistent and body.volume > 0,
          "closed mesh with consistent face orientation and positive volume")
    check(len(body.split(only_watertight=False)) == 1, "one connected body")
    cage = trimesh.load_mesh(ROOT / "stl/cage.stl")
    cage.apply_transform(np.array([
        [-1, 0, 0, 0], [0, -1, 0, 1], [0, 0, 1, 7], [0, 0, 0, 1],
    ]))
    collision = volume(boolean("intersection", body, cage))
    check(collision < 0.01, f"printed cage overlap: {collision:.6f} mm^3")

    # Swept to the seated position with 3mm more PCB spacing than the source.
    # Square X/Z envelopes cover both in-plane orientations with 0.5mm margin.
    # Rear-left is panda -X (the same left seen in the bottom view).
    envelopes = {
        "PCB + extra gap": ([-16.65, -48.92, -100], [16.65, -48, 66.65]),
        "gimbal + extra gap": ([-12.2, -60.68, -100], [12.2, -48.92, 62.2]),
        "bare shaft + extra gap": ([-2, -66.63, -100], [2, -60.68, 52]),
        "right header + extra gap": ([16.15, -54.92, -100], [21.35, -48.92, 56.35]),
        "left header + extra gap": ([-21.35, -54.92, -100], [-16.15, -48.92, 56.35]),
        "deep rear-left side allowance": ([-21.35, -63.5, -100], [-12, -48, 56.35]),
    }
    for name, (lo, hi) in envelopes.items():
        collision = volume(boolean("intersection", body, box(lo, hi)))
        check(collision < 0.01, f"{name} insertion overlap: {collision:.6f} mm^3")

    thickness, point, count, missing = rear_wall_samples(body, args.skin)
    check(missing == 0, f"no unintended rear openings above entrance: {missing} missing samples")
    check(thickness >= 1.0,
          f"rear wall above entrance: minimum {thickness:.3f} mm at "
          f"{np.round(point, 2).tolist()}, {count} samples (openings excluded)")

    if args.baseline:
        old = trimesh.load_mesh(args.baseline)
        added = volume(boolean("difference", body, old))
        check(added < 0.01, f"no new obstructions: added volume {added:.6f} mm^3")
        removed = boolean("difference", old, body)
        region = box([-23, -67.5, -1], [23, -40.9, 75.4])
        outside = volume(boolean("difference", removed, region))
        # Float32 STL and different Manifold versions produce microscopic slivers
        # on existing shared surfaces; 0.5 mm^3 is <0.00004% of this body.
        check(outside < 0.5,
              f"relief stays in channel: {outside:.6f} mm^3 numerical difference outside")
        print(f"Removed material: {volume(removed) / 1000:.2f} cm^3", flush=True)

    raise SystemExit(1 if failures else 0)


if __name__ == "__main__":
    main()
