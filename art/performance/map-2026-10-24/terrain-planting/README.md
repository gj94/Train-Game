# Terrain lighting and vegetation rooting

Smooth shared terrain normals preserve all tested ground positions and triangle
counts. Four fine-bank triangles per repeat now use consistent upward winding.
The temporary helper releases at the end of each build; a regression test guards
against the callable/owner reference cycle found in the first native run.

71 tiles, three interleaved isolated repeats: generation 18,040.862 → 19,362.765 ms
(+7.33% worker CPU); indexed vertices 1,468,765 → 479,903 (-67.33%). Raw vertices
2,667,579 unchanged. No position mismatches or invalid normals. This is not GPU
FPS or a target-laptop benchmark.

Vegetation seats on the actual fine/coarse triangle planes and excludes mapped
water, including root footprints and border water. Baseline 24 tiles / 24,783
plants: 197 root errors above 10 cm, maximum 1.861 m, eight wet placements.
After: 24,781 plants, no errors above 10 cm, maximum 0.0000038 m, no wet placements.

896 full source tests pass; six scripts validate in the editor. Three frozen
native views complete with clean stderr and resource cleanup. Road profile rows,
exclusions and OHE coordinates are identical; only source hashes refreshed.

Playtest: look along grass/palm roots at 220.8 and 230.6 km; inspect smooth earth
banks at QLN 140.7 km. These captures still show the separately documented
southern pond-height defect; that is the next correction, not a claimed fix here.
