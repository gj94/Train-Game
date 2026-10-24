# Shared waterway bank context

A worker-owned 64-tile cache now provides each tile with real shoreline segments
from its eight neighbours, bounded to a 10 m bank halo. Tile-clipping edges stay
excluded; polygon holes remain real shores. Border water classification uses
source-local neighbouring polygons, preserving water heights and preventing a
half-metre underwater step where an edge point belongs to only one clipped ring.
Only the current tile emits water surfaces. Adjacent workers share no mutable
cache or geometry dictionaries. Cache hits are refreshed before neighbour loads,
so all nine water contexts survive until the border data is assembled.

Expensive second railway projections now run only for samples that can actually
be bank-graded. The immutable actual-formation index uses 64 m query cells instead
of 128 m; its 27 m envelope is unchanged. All railway geometry, signals, physics,
timetable and prepared states remain untouched. Render-only road profiles were
regenerated: all 32,863 rows/exclusions/OHE locations identical, input hashes only.

## Evidence

- 17,680 before/after border probes: maximum 6.9877 m -> 0.0000415 m.
- All 4,305 tiles / 7,918 adjacent borders / 514,670 samples pass at 1 mm
  tolerance; worst 0.0000625 m. These are the actual 8 m outer mesh samples.
- 136 transition tiles / 2,528,740 internal/border comparisons pass. Fine
  shore cells and road projection still share the same terrain topology.
- Actual rail-ground audit: 26,778 centre/shoulder probes; same 271 improved
  cases against pre-formation support, no worsened or remaining exposure.
- All 4,305 tiles exported: 5,547,232 road triangles, all five road finishes,
  13,563 rail crossing probes and 696 piers pass independent Shapely checks.
  19,922 supports pass. 14,976 junction probes pass (max 6.148 mm), same three
  one-sided cases. These road checks permit legitimate low at-grade crossings;
  the separately documented parallel overlap is still next work.
- 868 full source tests, then 16 final focused shore tests after tightening the
  cache eviction guard; 17 Python tests. The full route audit preceded that
  cache-only guard; the new regression covers its exact eviction sequence.
- Two frozen native source views reviewed, at 4.1 km and 129.1 km: bank profiles
  join continuously. These off-corridor terrain views are not a vegetation,
  railway or target-GPU performance showcase. Native stderr is empty.
- Protected manifest: 4,893 files unchanged. No full timetable simulations or
  extracted-distribution gameplay. R45 is still live.

The interleaved 71-tile x3 CPU/vertex result is recorded in generation-summary.
It includes wet/dry tiles and dense bridge transitions, measured in isolation on
the development PC. It is not RTX 4090 Laptop frame-time evidence. Source samples
and representative native PNGs are retained here.

## Next diagnosed case

The remaining native Kollam slit is inside bridge 140725.726–140740.141 m.
Its shared slab is oriented by owner QLN_LADDER_LU5. The platform roads at the
same chainage have substantial longitudinal offsets, which are discarded when
projecting a single perpendicular width onto that diverging owner. Coverage
probe finds only 14/45 QLN_P4 centre/shoulder samples actually supported by the
two slab beams. The earlier ground audit covers approaches, not deck openings.
Read next-qln-deck-coverage/diagnosis and .local/map-2026-10-24/probe-qln-deck-coverage.gd.
Repair deck footprints without moving tracks or filling actual water openings.

After release: inspect the canal banks near 4.1 km and backwaters near 129.1 km;
move across streamed tile edges and inspect roads meeting the same slopes.
