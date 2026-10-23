# Road worker optimisation, 24 October 2026

Baseline d500cfe. Cache double-precision terrain plane equations, avoid repeated
per-triangle UV setup, and index road elevation samples and unique split knots
by source way. All split knots remain, including collinear bridge boundaries:
removing those could move piers or change the support grouping.

On the development Radeon 780M PC, 90 road tiles with three interleaved repeats:

| Measurement | Before | After |
| --- | ---: | ---: |
| Generation CPU time | 49,422.664 ms | 47,384.621 ms |
| Including mesh finish | 52,320.611 ms | 50,280.776 ms |
| Vertices | 6,881,697 | 6,881,697 |
| Road material surfaces | 885 | 885 |

Generation improves 4.12%; total creation improves 3.90%. This is worker CPU
creation, not a rendered FPS result or a measurement on the target RTX 4090
Laptop. The preliminary plane/UV-only run improved total creation by 3.84%;
do not add percentages from separate runs. Per-way indices retain references
to the existing immutable segment records and are shared with scenery workers.

Validation:

- 841 full source tests pass; 17 Python road tests pass. Zero stderr errors.
- Exact full-source lookup parity: 27,984 segments, 139,920 height queries and
  27,337 split knots, zero differences.
- All 4,305 tiles exported: 5,428,221 actual top triangles across every road
  material, shoulders and paint. Independent clearance audit passes, including
  13,256 railway crossings and 695 piers.
- 2,169 rendered junction pairs / 14,976 probes pass; greatest height mismatch
  6.148 mm. The same three previously documented unpaired contacts remain.
- All 32,857 road profile elevations, exclusions and support-post positions
  unchanged. Regenerated metadata hashes pass the 1,800-input build gate.
- All 4,893 protected railway/prepared-data files unchanged.
- Three source native views, frozen railway clock 0, retained here. Editor
  validates all six changed scripts and reports zero errors.

No timetable rehearsal or extracted-distribution gameplay run. R45 remains
available. Playtest the Kumbalam 9.5 km junction, raised junction at 146.2 km,
and ground/deck transition at 184.3 km when the follow-up build is released.

The native views expose pre-existing shoulder strips across some junction
mouths. That and the separate support/stream investigation remain subsequent
map work, not regressions fixed by this optimisation.
