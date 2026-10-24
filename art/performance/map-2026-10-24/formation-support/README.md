# Ground beneath existing railway formations — 24 October 2026

No railway coordinates, operating geometry, simulation or prepared timetable
data changed. Actual terminal roads now participate in the render ground index.
Near bridge ends, actual track segments replace an inaccurate projection onto
the decimated route reference. Water carving respects non-bridge formations;
real bridge openings retain their water bed. Small 2 m terrain patches cover
abutment transitions. Short landward concrete supports close the interpolation
wedge where a terrain grid cannot represent a vertical bridge-end boundary.

Supports are clipped outside every real bridge interval, including adjacent
openings. Their full footprints are checked against road gradients; supports
that would obstruct a lower road are omitted. Section ownership means one wall
can support several parallel tracks, so the independent ground audit checks
actual wall footprints rather than only matching track IDs.

Validation:

- 26,778 centre/shoulder samples: 271 improved, none worsened, none remaining
  below the soil skirt by more than the audit tolerance. This is a sampled
  route check, not a claim that every metre of every bridge is perfect.
- 216 emitted landward supports / 43 road overlaps pass independent Shapely
  checks. All bridge openings remain outside the support footprints.
- Full 4,305-tile road export: 5,545,611 triangles, all finishes, 13,563 rail
  checks, 696 piers and 19,922 road supports pass clearance checks. 14,976
  junction probes pass; max 6.148 mm, same three one-sided cases.
- 136 bridge-transition terrain tiles: internal fine/coarse edges agree
  within 0.000002 m. 63 tiles expose pre-existing waterway border mismatches;
  17,680 before/after border probes show no newly worsened seams. The worst
  old/new mismatch is 6.988 m. **These seams remain next-pass work.**
- 860 full source tests passed before the final road-gradient clearance
  refinement; all 12 formation tests passed after it. 17 Python road tests
  pass. Eight scripts validate in the editor; editor reports zero errors.
- 4,893 protected files unchanged. Render-only road profiles regenerated:
  32,857 -> 32,863 segments across 43 changed ways; 1,802-input gate current.

The interleaved CPU test compares a329f51 with the final terrain implementation,
using separate old/new geographic adapters. 71 tiles (60 wet/dry samples plus
11 additional dense bridge-transition tiles), three repeats: terrain/water
generation 52,215 -> 67,305 ms (+28.90%); vertices +5.44%. About 70.8 ms extra
generation per tested tile, on the development PC. The actual formation index
took 197 ms to install versus 9 ms for the old index in the static audit and
is shared by workers. These are generation costs, not RTX 4090 Laptop FPS.
Review this cost while fixing shared bank context; no new material category.

Seven final frozen native views show the repaired formation locations. TVC's
boundary wall obscures the underlying track ground. A separate existing
bridge-edge slit remains visible left of the QLN focal point, inside the
bridge area; retain that as a follow-up case rather than claiming it repaired.

**Release blocker discovered in native validation:** the busy QLN view exceeds
Godot's instance-shader buffer. It reproduces in a fresh isolated QLN run.
The diagnostic counts 4,090 extreme-detail parameters and 420 door-opening
parameters across 23,524 geometry nodes. The errors are preserved here and in
.local; do not describe these native runs as error-free. Resolve this rendering
limit before publishing the overnight release. Railway time remained zero.

Reproduce the static comparison with
`python tools/maps/prepare_formation_audit_baseline.py`, then headless
`tools/audit_formation_support.gd`. The `.local` baseline copies deliberately
freeze the dependencies changed in this increment, against protected route
data. Native case positions and exact output measurements are included here.

Playtest after release: ERS and NCJ terminal extensions, KZTW bridge exit near
242.5 km, NYY approach near 224.6 km, AMY near 172.1 km and QLN at 140.742 km.
R45 remains live during further work; this increment is not a new release.
