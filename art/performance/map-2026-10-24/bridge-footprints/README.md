# Actual bridge footprints

Shared chainage is not a shared perpendicular cross-section in a station yard.
The old Kollam deck followed QLN_LADDER_LU5 and missed neighbouring QLN_P4.
Each track now supplies its real footprint. Stable ownership clips overlapping
slab area, mitered corners close curve joints, and guardrails clear actual rails.
Piers follow actual centre lines and clear the full road plus its 65 cm shoulder.
Existing landward abutments, water openings and every railway input are unchanged.

- All 115 bridge spans: 17,463 centre/shoulder probes, zero unsupported or height
  failures. Baseline 66b1efa had 1,250 unsupported probes. Independent Shapely
  audit uses actual emitted top triangles, not the planning polygons.
- 11,197 top triangles, no degenerates. Overlapping top area totals 0.00235 m²
  across the route, versus 1,272.7 m² in the previous shared beams.
- 2,679 horizontal guard beams: minimum continuous rail clearance 3.268 m.
  All 416 emitted piers checked against the existing actual road-triangle export;
  zero conflicts. First audit caught shoulders outside the centre-road envelope;
  the final guard and regression cover this.
- 875 full source tests, then 7 focused bridge tests after the final shoulder
  guard and mesh reduction. Four scripts validate in Godot MCP; editor errors 0.
- Five frozen native source views, including the exact QLN reproduction and
  four regional bridge views. Clean stderr; railway time remains zero.
- All 4,893 protected railway/prepared files remain byte-identical. R45 stays live.

Geometry cost is higher because the old shared deck omitted actual track areas.
Isolated 207 whole-edge generation/mesh jobs x3: 745.896 -> 2200.329 ms
in total; 288,648 -> 721,734 vertices across the whole route. The first correct
version had 1,437,192 vertices; removing internal walls and giving guard beams
their own cadence halved that. This measures creation, not per-frame GPU cost or
target RTX 4090 Laptop FPS. Only nearby chunks are loaded. No timetable run.

Reproduce with tools/audit_bridge_decks.gd and tools/maps/audit_bridge_decks.py.
The independent clearance reproduction reuses the ignored bank-road-triangles
export, whose five road finishes were already independently audited. Baseline
script is the geographic_bridges.gd file from 66b1efa. Profile reproduction uses
that saved baseline. Native cases run through tools/capture_village_access.gd.

After release: inspect QLN near 140.73 km from both sides, then the regional
backwater bridges; rails and shoulders should have solid decks, with no railings
across running tracks or piers through adjacent roads.

Remaining visual observation: the wide bank views reveal conspicuous flat
terrain normals/triangular shading. Assess smooth shared vertex normals without
moving tested terrain vertices; preserve the bank/tile topology and clearance.
