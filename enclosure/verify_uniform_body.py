"""Validate a uniformly scaled body against the existing, unscaled printed hardware.

Export body_blank and hardware_void with fitcheck.scad, and the new cap with
cage.scad part="joy_cap_scaled_body". Requires numpy, trimesh and manifold3d.
This checks modeled geometry, not print tolerances, material strength or measured
hardware. In particular, the known higher corner interference is reported.
"""
import argparse
from pathlib import Path

import numpy as np
import trimesh

from verify_entrance import ROOT, box, solid


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("body", type=Path)
    p.add_argument("--scale", type=float, required=True)
    p.add_argument("--channel", type=Path, required=True)
    p.add_argument("--usb", type=Path, required=True)
    p.add_argument("--blank", type=Path, required=True)
    p.add_argument("--hardware-void", type=Path, required=True)
    p.add_argument("--cap", type=Path, required=True)
    p.add_argument("--baseline", type=Path, required=True)
    args = p.parse_args()
    mesh = trimesh.load_mesh(args.body)
    blank_mesh = trimesh.load_mesh(args.blank)
    cap_mesh = trimesh.load_mesh(args.cap)
    body, blank = solid(mesh), solid(blank_mesh)
    old = solid(trimesh.load_mesh(args.baseline))
    failures = []

    def check(ok, message):
        print(("PASS " if ok else "FAIL ") + message, flush=True)
        if not ok:
            failures.append(message)

    for label, m in [("body", mesh), ("cap", cap_mesh)]:
        check(m.is_watertight and m.is_winding_consistent and m.volume > 0,
              f"{label}: closed mesh with consistent orientation")
        check(len(m.split(only_watertight=False)) == 1, f"{label}: one connected solid")
    reference = trimesh.load_mesh(ROOT / "panda/panda_original_without_embosses.stl")
    reference.apply_transform([
        [-212.9096, 0, 0, 0], [0, -212.9096, 0, 9.036],
        [0, 0, 212.9096, 0], [0, 0, 0, 1],
    ])
    reference.apply_scale(args.scale)
    expected = solid(reference)
    discrepancy = abs((blank - expected).volume()) + abs((expected - blank).volume())
    check(discrepancy < .1, f"outer blank is exactly {args.scale*100:g}% original sculpt: {discrepancy:.6f} mm^3 difference")
    check(np.max(abs(mesh.bounds - reference.bounds)) < .01,
          f"body dimensions {np.round(mesh.extents, 3).tolist()} mm (X/Y/Z), feet at Z0")
    check(abs((body - blank).volume()) < .01, "no patch or bulge outside the uniformly scaled sculpt")
    obstruction = abs((body ^ solid(trimesh.load_mesh(args.hardware_void))).volume())
    check(obstruction < .01, f"all fixed hardware cutters clear: {obstruction:.6f} mm^3 overlap")
    for x, y in [(38, 50), (-38, 50), (44, 17), (-44, 17)]:
        region = box([x - 4.5, y - 4.5, 11.19], [x + 4.5, y + 4.5, 19.2])
        loss = abs(((old - body) ^ region).volume())
        check(loss < .01, f"existing magnet seat/support ({x},{y}) retained: {loss:.6f} mm^3 lost")

    # Check channel-to-original-skin distance down to the flange-seat height,
    # not just the easier upper wall. Below Z11.2 is the open underside entrance.
    channel = trimesh.load_mesh(args.channel)
    x, z = np.meshgrid(np.arange(-22.875, 22.88, .25),
                       np.r_[11.2, np.arange(11.25, 75.36, .5)])
    origins = np.column_stack([x.ravel(), np.full(x.size, -100), z.ravel()])
    edge_x = np.arange(-22.89, 22.9, .05)
    origins = np.vstack([origins, np.column_stack([
        edge_x, np.full(len(edge_x), -100), np.full(len(edge_x), 11.2)])])
    directions = np.tile([0, 1, 0], (len(origins), 1))
    usb = trimesh.load_mesh(args.usb)
    port = usb.ray.intersects_any(origins, directions)
    port |= origins[:, 0]**2 + (origins[:, 2]-50)**2 <= 7.25**2
    origins, directions = origins[~port], directions[~port]
    points, rays, _ = channel.ray.intersects_location(origins, directions)
    order = np.lexsort((points[:, 1], rays))
    points, rays = points[order], rays[order]
    _, first = np.unique(rays, return_index=True)
    points = points[first]
    distances = []
    for start in range(0, len(points), 1000):
        chunk = points[start:start+1000]
        nearest, dist, triangles = trimesh.proximity.closest_point(reference, chunk)
        outward = np.einsum("ij,ij->i", chunk-nearest, reference.face_normals[triangles]) > 1e-7
        distances.extend(np.where(outward, -dist, dist))
    distances = np.asarray(distances)
    i = int(np.argmin(distances))
    check(distances[i] >= 1.0,
          f"minimum channel wall above flange seat: {distances[i]:.6f} mm at "
          f"{np.round(points[i], 3).tolist()}, {len(points)} samples (intended ports excluded)")

    cage_mesh = trimesh.load_mesh(ROOT / "stl/cage.stl")
    cage_mesh.apply_transform([
        [-1, 0, 0, 0], [0, -1, 0, 1], [0, 0, 1, 7], [0, 0, 0, 1],
    ])
    cage = solid(cage_mesh)
    entry = box([-100, -100, -1], [100, 100, 12])
    entry_max = full_max = old_max = 0.0
    positions = np.arange(0, 88.01, .25)
    for down in positions:
        moving = cage.translate([0, 0, -down])
        hit = body ^ moving
        entry_max = max(entry_max, abs((hit ^ entry).volume()))
        full_max = max(full_max, abs(hit.volume()))
        old_max = max(old_max, abs((old ^ moving).volume()))
    check(abs((body ^ cage).volume()) < .01, "existing cage seats without overlap")
    check(entry_max < .01, f"feet entrance clear at {len(positions)} poses: {entry_max:.6f} mm^3")
    check(full_max <= old_max + .01, f"higher corner overlap unchanged: {full_max:.6f} mm^3 (previous {old_max:.6f})")

    # Shoulder and pivot from the measured joystick model. Test nominal PCB gap
    # and +3mm, both oval-socket orientations, 0..11deg, every 15deg azimuth.
    cap_max = margin_max = 0.0
    count = 0
    for extra_gap in [0, 3]:
        for socket_turn in [0, 90]:
            cap = cap_mesh.copy()
            cap.apply_transform(trimesh.transformations.rotation_matrix(np.deg2rad(socket_turn), [0, 0, 1]))
            padded = cap.copy()
            padded.apply_scale([1.10, 1.10, 1])
            placement = np.array([
                [1, 0, 0, 0], [0, 0, -1, -57.68-extra_gap],
                [0, 1, 0, 50], [0, 0, 0, 1],
            ])
            cap.apply_transform(placement)
            padded.apply_transform(placement)
            for angle in range(12):
                for az in range(0, 360, 15):
                    axis = [np.cos(np.deg2rad(az)), 0, np.sin(np.deg2rad(az))]
                    transform = trimesh.transformations.rotation_matrix(
                        np.deg2rad(angle), axis, [0, -51.9-extra_gap, 50])
                    for source, pad in [(cap, False), (padded, True)]:
                        moved = source.copy()
                        moved.apply_transform(transform)
                        overlap = abs((body ^ solid(moved)).volume())
                        if pad:
                            margin_max = max(margin_max, overlap)
                        else:
                            cap_max = max(cap_max, overlap)
                    count += 1
    check(cap_max < .01, f"long cap tilt clear in {count} poses: {cap_max:.6f} mm^3 maximum overlap")
    check(margin_max < .01, f"cap still clears with 10% radial enlargement: {margin_max:.6f} mm^3 overlap")
    print(f"INFO {mesh.extents[2]:.1f}mm print height required. Use the matching scaled-body cap; the original 11mm cap is too short.", flush=True)
    print("INFO underside stays open; original higher corner interference remains. Physical fit and cap strength are not certified.", flush=True)
    raise SystemExit(1 if failures else 0)


if __name__ == "__main__":
    main()
