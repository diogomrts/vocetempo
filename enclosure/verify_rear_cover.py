"""Verify the enclosed rear without sacrificing the approved insertion void.

Requires numpy, trimesh, manifold3d, scipy and rtree. Export the channel and USB
cutters from panda.scad separately, then run:
  python verify_rear_cover.py stl/panda_body.stl \
    --baseline stl/panda_body_entrance_relief_v3.stl \
    --channel /tmp/channel.stl --usb /tmp/usb.stl

Default: v5 expanded original rump. Add --style cover for the historical v4 cover.

The baseline comparison is additive only and checks that new material is outside
the original sculpt AND outside the complete joystick channel. Rear rays inspect
the formerly open region; rays through the USB opening and the known 14mm cap
bore are excluded. Both openings are checked separately for obstructions.
"""
import argparse
from pathlib import Path

import numpy as np
import trimesh

from verify_entrance import ROOT, box, solid


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("body", type=Path)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--channel", type=Path, required=True)
    parser.add_argument("--usb", type=Path, required=True)
    parser.add_argument("--style", choices=["expanded", "cover"], default="expanded")
    args = parser.parse_args()
    body = trimesh.load_mesh(args.body)
    old = trimesh.load_mesh(args.baseline)
    channel = trimesh.load_mesh(args.channel)
    usb = trimesh.load_mesh(args.usb)
    cap = trimesh.creation.cylinder(radius=7, height=100, sections=48, transform=[
        [1, 0, 0, 0], [0, 0, 1, -30], [0, -1, 0, 50], [0, 0, 0, 1],
    ])
    skin = trimesh.load_mesh(ROOT / "panda/panda_original_without_embosses.stl")
    skin.apply_transform([
        [-212.9096, 0, 0, 0], [0, -212.9096, 0, 9.036],
        [0, 0, 212.9096, 0], [0, 0, 0, 1],
    ])
    current, previous = solid(body), solid(old)
    added = current - previous
    failures = []
    region = (box([-60.1, -74.6, -0.01], [60.1, -19.9, 45.1])
              if args.style == "expanded" else
              box([-42.1, -69.1, -0.01], [42.1, -28.8, 25.1]))

    def check(ok, message):
        print(("PASS " if ok else "FAIL ") + message, flush=True)
        if not ok:
            failures.append(message)

    check(body.is_watertight and body.is_winding_consistent and body.volume > 0,
          "closed, consistently oriented mesh")
    check(len(body.split(only_watertight=False)) == 1, "one connected body")
    for label, value in [
        ("removed original material", abs((previous - current).volume())),
        ("new material inside original sculpt", abs((added ^ solid(skin)).volume())),
        ("complete joystick channel overlap", abs((current ^ solid(channel)).volume())),
        ("USB opening overlap", abs((current ^ solid(usb)).volume())),
        ("joystick cap bore overlap", abs((current ^ solid(cap)).volume())),
        ("change outside lower rear region", abs((added - region).volume())),
    ]:
        check(value < 0.01, f"{label}: {value:.6f} mm^3")
    if args.style == "cover":
        check(np.max(abs(body.bounds - old.bounds)) < 0.01, "overall dimensions unchanged")
    else:
        check(np.max(abs(body.bounds[:, [0, 2]] - old.bounds[:, [0, 2]])) < 0.01
              and abs(body.bounds[1, 1] - old.bounds[1, 1]) < 0.01,
              "width, height, ground plane and front extent unchanged")
        extra_depth = old.bounds[0, 1] - body.bounds[0, 1]
        check(0 < extra_depth < 5.5, f"rump extends backward {extra_depth:.3f} mm")
    print(f"INFO added {added.volume()/1000:.3f} cm^3 outside the original skin", flush=True)

    cage_mesh = trimesh.load_mesh(ROOT / "stl/cage.stl")
    cage_mesh.apply_transform([
        [-1, 0, 0, 0], [0, -1, 0, 1], [0, 0, 1, 7], [0, 0, 0, 1],
    ])
    cage = solid(cage_mesh)
    poses = np.arange(0, 88.01, 0.25)
    maximum = max(abs((added ^ cage.translate([0, 0, -d])).volume()) for d in poses)
    check(maximum < 0.01,
          f"no new cage interference at {len(poses)} positions: {maximum:.6f} mm^3")

    top = 45 if args.style == "expanded" else 25
    x, z = np.meshgrid(np.arange(-24.25, 24.26, 0.5), np.arange(0.25, top, 0.5))
    origins = np.column_stack([x.ravel(), np.full(x.size, -80.1), z.ravel()])
    directions = np.tile([0, 1, 0], (len(origins), 1))
    _, usb_rays, _ = usb.ray.intersects_location(origins, directions)
    origins = np.delete(origins, np.unique(usb_rays), axis=0)
    cap_rays = origins[:, 0]**2 + (origins[:, 2] - 50)**2 <= 7**2
    origins = origins[~cap_rays]
    directions = np.tile([0, 1, 0], (len(origins), 1))
    points, rays, _ = body.ray.intersects_location(origins, directions)
    valid = points[:, 1] < -43.9
    points, rays = points[valid], rays[valid]
    order = np.lexsort((points[:, 1], rays))
    points, rays = points[order], rays[order]
    _, starts, counts = np.unique(rays, return_index=True, return_counts=True)
    starts = starts[counts >= 2]
    missing = len(origins) - len(starts)
    thickness = points[starts + 1, 1] - points[starts, 1]
    check(missing == 0, f"rear opening covered: {missing} missing rays of {len(origins)}")
    minimum = float(thickness.min()) if len(thickness) else 0
    check(minimum >= 1.0, f"rear wall along Y: minimum {minimum:.3f} mm on 0.5 mm grid")
    print("INFO underside intentionally open; existing higher front-corner interference unchanged.", flush=True)
    raise SystemExit(1 if failures else 0)


if __name__ == "__main__":
    main()
