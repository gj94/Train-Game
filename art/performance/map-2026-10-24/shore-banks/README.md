# Continuous canal banks — 24 October 2026

The former 2 m shore cells interpolated all four perimeters onto the enclosing
8 m cell, including boundaries shared with other fine cells. The 2.5 km canal
view shows the resulting repeated triangular bank notches in `canal-before.png`.
The new shared terrain/road topology uses actual ground samples across fine
neighbours and interpolates only at fine/coarse transitions. A narrow 10 m
shore-distance test selects detail. Outer tile borders retain the existing
coarse contract; this change does not claim a new cross-tile terrain system.

Mapped water polygons now own their surface: overlapping stream centrelines
are clipped away, preserving uncovered lengths and streams through polygon
holes. Unmapped stream ribbons keep their existing geometry. No water datum,
track geometry or simulation is changed.

`terrain-continuity.json` checks 801,774 actual emitted edge comparisons across
60 water-heavy/dry tiles, including fine/coarse joins and unchanged outer-tile
edges. Native final views at 2.5, 9.5 and 184.3 km use frozen railway time zero.
The latter two still show existing shoulder overlaps at junction mouths; those
are separate follow-up work, not evidence that every map defect is resolved.

The isolated, interleaved generation comparisons use this development PC,
not the i9 / RTX 4090 Laptop target. Three repeats:

| Subsystem | Before | After | Change |
| --- | ---: | ---: | ---: |
| Terrain/water, 60 tiles | 20,204 ms | 24,774 ms | +22.62% |
| Terrain/water vertices | 5,255,955 | 6,064,497 | +15.38% |
| Roads, 90 tiles | 47,271 ms | 48,537 ms | +2.68% |
| Roads including mesh finish | 50,564 ms | 51,864 ms | +2.57% |
| Road vertices | 6,881,697 | 6,923,922 | +0.61% |

The additional terrain-generation cost averages 25.4 ms per tile in this
water-heavy selection. Road material surfaces remain 885; no new material or
draw-call category is introduced. A wider 14 m prototype cost more and was
rejected. These are worker-generation measurements, not gameplay FPS claims.

Playtest after release: inspect the canal around route km 2.5 from near-bank
height, then Kumbalam's raised junction at km 9.5 and the road/deck junction
at km 184.3. The numerical audits cover all road finish types. Railway input
hashes and road-profile coordinates are checked separately in this directory.
