# Grounded pond banks and stream ribbons

Southern pond a1522434304 near 230.55 km had mapped water at 51.5 m above
formation-ground heights near 46.84 m. Dry banks now rise toward the existing
water datum outside a protected, gradually blended 16–28 m rail corridor.
Confined pond edges receive grounded retaining faces. Real shorelines are used;
tile clipping boundaries never become walls. Adjacent roads and stations stay
clear, including roads in neighbouring tiles.

Stream ribbons now project onto the actual fine/coarse terrain triangles.
Eight-metre pieces bound projection work on long diagonal source ways. Bends
retain their width; covered waterways and duplicate centrelines inside mapped
water polygons remain omitted.

## Validation

- 902 full source tests; after the final road guard, seven pond/stream and 51
  road tests pass. 23 Python tests pass. Four edited scripts validate in Godot.
- 27,231 actual railway-ground samples and 56 station centres: exactly unchanged.
- All 4,305 tiles / 7,918 boundaries / 514,670 probes: maximum height disagreement
  0.0624 mm, no failures. 137 detailed terrain tiles / 2,540,255 internal/border
  comparisons: no cracks above tolerance.
- All 5,475,344 final road triangles exported. Exact record comparison identifies
  12,454 unchanged records and 179 changed records across 134 tiles. Independent
  clearance audit checks all 202,821 changed triangles and 539 affected supports.
  Remaining geometry retains the preceding full-route audit. All five road
  material kinds remain covered.
- Parallel-road audit includes the changed tiles' surrounding crossroads:
  2,882,667 triangles, 29,363 near-level intersections, 826 legitimate crossing
  aprons, zero conflicts. The earlier isolated changed-road audit lacked these
  crossroad meshes and is superseded by this contextual check.
- All 2,169 junction pairs / 14,976 probes retain the 6.148 mm maximum height
  difference and three pre-existing single-sided centre probes.
- Final 10,501 pond faces: minimum independent rail clearance 5.076 m; no road
  intersections. The audit caught one road-blocking face in the first version;
  the final guard and regression test prevent that.
- 24,781 vegetation instances: no wet roots or >10 cm grounding errors; worst
  numerical discrepancy 0.0000038 m.
- Three final frozen native source views complete with clean renderer/cleanup
  output. No full timetable or extracted-distribution gameplay rerun.

Generation timings are in generation-summary.json, measured in an isolated
71-tile, three-repeat comparison with the preceding implementation. They are
worker CPU measurements, not GPU FPS on the RTX 4090 Laptop target.
Generation rises 19,533.251 → 20,947.069 ms (+7.24%); indexed vertices rise
479,903 → 501,970 (+4.60%). No invalid normals. The much larger preceding
reduction from smooth terrain normals is retained.

Playtest the pond/stream banks at 220.8/230.6 km and bridge area at QLN 140.7 km.
Water-body outlines still follow mapped geometry, with abrupt corners in places;
this correction addresses hanging surfaces and clearance, not hydrological
simulation or a surveyed reconstruction of every pond.
