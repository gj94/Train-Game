# Road mouths and railway clearance — 24 October 2026

Render-only road work. Track geometry, simulation, prepared timetables and all
4,893 protected files are unchanged. No timetable rehearsal was run.

- Clip a low road's full ribbon away from the railway when it runs within 20
  degrees of the track. A 3.15 m envelope includes the ballast/verge and short
  curved-track chord allowance. True crossings, underpasses and flyovers remain.
- Check terrain-draped triangles after projection: their edges can rise above
  the centreline used by the original clearance test.
- Keep short same-level crossing mouths connected to trimmed parallel roads.
  Five connections caught by the first geometry audit were repaired; the final
  junction result matches the baseline 2,169 paired junctions / 14,976 probes,
  maximum height difference 6.148 mm, three unchanged one-sided centres.
- Remove shoulders and paint from another same-level carriageway's mouth.
  A worker-local spatial index also covers adjacent tile edges. Unsupported
  point metadata, tunnel ways and unprofiled bridges cannot erase road finishes.

Validation: 887 full source tests, then 51 final focused road tests; 23 Python
tests (including independent audit rejection cases). Godot validates six scripts.
Full 4,305-tile export: **5,474,690 triangles**, all five road material kinds,
shoulders and paint. Station/building/water/OHE checks and 696 piers pass;
19,922 road supports pass. The independent parallel-road audit checks 48,229
near-level intersections and identifies 1,788 legitimate crossing-mouth
fragments; no unresolved overlap remains. It uses actual emitted crossroads,
per-segment bends and flat track end caps; round caps falsely extended rails
beyond buffer stops. Folded source miters are repaired for Shapely union.

Three frozen native source views, at 143.7, 146.2 and 184.3 km, complete without
renderer errors. The offending road w1024795790 is clear of QLN_DEPOT_RD_LEAD.
Some overlapping road-material dust masks remain visible at junctions; this
pass does not claim complete carriageway-material ownership or cosmetic parity.

Isolated interleaved 90-tile x3 CPU comparison, using the previous road builder
from 8bb8db8 with the same current terrain/profile/clearance index:

| Metric, aggregate mean per repetition | Before | After |
|---|---:|---:|
| Road generation | 14,568.815 ms | 18,367.173 ms |
| Mesh finishing | 990.531 ms | 979.701 ms |
| Indexed vertices | 2,318,522 | 2,271,724 |

Generation costs 26.07% more; vertices fall 2.02%. This is worker CPU creation
cost, **not** GPU FPS or an RTX 4090 Laptop measurement. Expensive post-projection
checks and crossing-apron queries are restricted to nearby parallel rails.

Road profiles were regenerated to refresh input hashes only: all 32,863 rows,
exclusions and OHE coordinates are identical. The 1,806-input export gate passes.
Reproduce with tools/check_road_render_geometry.gd --all and the road surface,
support, junction and parallel-road Python auditors. The committed JSONs contain
the complete results. Native captures use capture_village_access.gd and cases.json.

After release: inspect the parallel road at 143.7 km, the raised junction at
146.2 km and the ground junction at 184.3 km. Drive through nearby track bends;
look for asphalt on ballast, severed road mouths, continuous stripes across
crossroads, and changes to grade-separated road barriers. Railway operation is
unchanged. R45 remains available until the overnight pass and release checks end.
