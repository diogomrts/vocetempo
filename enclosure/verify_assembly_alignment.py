"""Verify exported screen, speaker, USB and unchanged-cage integration.

Complements verify_cage.py, verify_joystick_channel.py and verify_uniform_body.py.
Export speaker_void, acoustic_void and speaker_inlet from fitcheck.scad. The
baseline is the frozen v7 body; this checks the v8 speaker-only correction.
Requires numpy, trimesh, manifold3d, scipy and rtree. Measurements are geometric;
physical print tolerances, electronics and acoustic performance are not tested.
"""
import argparse
from pathlib import Path

import numpy as np
import trimesh

from verify_entrance import ROOT, solid


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("body", type=Path)
    for name in ["baseline", "blank", "cage-source", "speaker", "acoustic", "inlet"]:
        p.add_argument("--" + name, type=Path, required=True)
    args = p.parse_args()
    body = trimesh.load_mesh(args.body)
    old = trimesh.load_mesh(args.baseline)
    cage = trimesh.load_mesh(ROOT / "stl/cage.stl")
    b, previous, c = solid(body), solid(old), solid(cage)
    fails = []

    def check(ok, message):
        print(("PASS " if ok else "FAIL ") + message, flush=True)
        if not ok:
            fails.append(message)

    rebuilt_cage = solid(trimesh.load_mesh(args.cage_source))
    delta = abs((c-rebuilt_cage).volume()) + abs((rebuilt_cage-c).volume())
    check(delta < .01, f"current cage source equals already-printed cage: {delta:.6f} mm^3")
    check(np.max(abs(body.bounds-old.bounds)) < .01, "v7 overall size and ground plane unchanged")
    check(body.is_watertight and body.is_winding_consistent and len(body.split()) == 1,
          "body is one closed, consistently oriented solid")
    added, removed = b-previous, previous-b
    check(abs(added.volume()) < .01, f"no added material/obstructions: {abs(added.volume()):.6f} mm^3")
    inlet = solid(trimesh.load_mesh(args.inlet))
    outside = abs((removed-inlet).volume())
    check(outside < .01, f"only speaker inlet changed: {outside:.6f} mm^3 outside inlet")
    # Boolean differences include microscopic float-STL slivers elsewhere; the
    # outside-inlet volume is bounded separately above. Inspect the real repair.
    rm = (removed ^ inlet).to_mesh()
    blank = trimesh.load_mesh(args.blank)
    _, dist, _ = trimesh.proximity.closest_point(blank, np.asarray(rm.vert_properties)[:, :3])
    check(dist.min() > 1, f"speaker correction stays inside outer skin: nearest removed vertex {dist.min():.3f} mm inside")
    print(f"INFO removed {removed.volume():.3f} mm^3 inside speaker transition only.", flush=True)

    # Actual sight rays from the mounted glass plane through both exported shells.
    cage.apply_transform([[-1, 0, 0, 0], [0, -1, 0, 1], [0, 0, 1, 7], [0, 0, 0, 1]])
    x, z = np.meshgrid((np.arange(128)-63.5)*55/128,
                       (np.arange(64)-31.5)*28/64+47.8)
    origins = np.column_stack([x.ravel(), np.full(x.size, 42.23), z.ravel()])
    directions = np.tile([0, 1, 0], (len(origins), 1))
    blocked = body.ray.intersects_any(origins, directions).reshape(64, 128)
    old_blocked = old.ray.intersects_any(origins, directions).reshape(64, 128)
    expected = np.zeros((64, 128), dtype=bool)
    expected[np.ix_([0, 63], [0, 127])] = True
    check(np.array_equal(blocked, expected) and np.array_equal(blocked, old_blocked),
          f"OLED aligned at X0/Z47.8: {8192-blocked.sum()}/8192 pixel centres visible; only 4 original rounded corners masked")
    cage_blocked = cage.ray.intersects_any(origins, directions)
    check(not cage_blocked.any(), "printed cage screen cut clears all 8192 pixel sight lines")

    # Full CAD throat (37.75 x 27.2 including clearance), through the roof.
    throat = solid(trimesh.load_mesh(args.speaker))
    was, now = abs((previous ^ throat).volume()), abs((b ^ throat).volume())
    check(now < .01, f"entire offset speaker aperture clear: {now:.6f} mm^3 (v7 obstruction {was:.3f})")
    acoustic_mesh = trimesh.load_mesh(args.acoustic)
    check(len(acoustic_mesh.split()) == 1, "speaker inlet, chimney, head chamber and both ear ducts form one connected air path")
    obstruction = abs((solid(acoustic_mesh) ^ b).volume())
    check(obstruction < .01, f"connected sound path has no body obstruction: {obstruction:.6f} mm^3")
    # Each vent must reach the exterior, not terminate as a blind internal hole.
    scale = 1.087
    angle = np.deg2rad(46.2)
    holes = []
    for sx in [-1, 1]:
        for row in [-1, 0, 1]:
            for col in range(-2, 3 if row == 0 else 2):
                u = col*3.8 + (0 if row == 0 else 1.9)
                v = row*3.8*np.sin(np.deg2rad(60))
                x = sx*(51.4 + u*np.cos(angle)+v*np.sin(angle))*scale
                z = (182.9-u*np.sin(angle)+v*np.cos(angle))*scale
                holes.append([x, 6*scale, z])
    origins = np.asarray(holes)
    directions = np.tile([0, -1, 0], (len(origins), 1))
    points, rays, _ = body.ray.intersects_location(origins, directions)
    blocked_rays = np.unique(rays[points[:, 1] > -6.8*scale+0.001])
    check(len(blocked_rays) == 0 and len(holes) == 26,
          f"all 26 ear vent centres open from outside into their plenums: {len(blocked_rays)} blocked")

    # Rear USB access through both shells, using a conservative inner rectangle.
    x, z = np.meshgrid(np.arange(11.8, 26.81, .5), np.arange(24.5, 33.51, .5))
    origins = np.column_stack([x.ravel(), np.full(x.size, -40), z.ravel()])
    directions = np.tile([0, -1, 0], (len(origins), 1))
    for label, mesh in [("body", body), ("printed cage", cage)]:
        blocked = mesh.ray.intersects_any(origins, directions)
        check(not blocked.any(), f"USB slot aligned through {label}: {blocked.sum()}/{len(origins)} blocked access rays")

    print("INFO run companion cage, joystick and uniform-body checks for mounting pilots, insertion, magnets and cap tilt.", flush=True)
    raise SystemExit(1 if fails else 0)


if __name__ == "__main__":
    main()
