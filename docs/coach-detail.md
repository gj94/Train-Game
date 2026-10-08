# Detailed ICF and LHB coaches

The seven classes in each family now use the user's detailed v02 masters from
`gj94/transport-fever-3-mods`, checkpoint
`e209ff54ff5cd00bb0761761bdbe124cac6bf7cd` on
`backup/coach-detail-overnight`. The source marks this as WIP: coach geometry and
portable exchange checks are complete, while its high-sample gallery is still
being finished. This port uses the actual Blender masters, not preview images.

The fourteen coach masters retain 13,682,319 evaluated source triangles
(6,256,163 ICF and 7,426,156 LHB). Each family includes 1A, 2A, 3A, 2S, CC, SL
and GS. ICF retains the selected
conventional screw-coupled, self-generating branch, class-specific window
arrangements and underfloor equipment. LHB retains its detailed FIAT bogies,
CBC equipment, recessed roof HVAC, class-specific upholstery and service areas.
The game's selectable fleet remains WAP-7 + ICF, WAP-7 + LHB, VB8 and VB16.

Every visible source mesh, curve and text object under the vehicle root is
evaluated into the closest-detail mesh. Fixed parts merge within their rigid
mechanism; wheels and brake discs turn with axles, and fixed brake/suspension
parts stay with the bogie. Materials retain authored colours, procedural finish
inputs and original marking pixels through the existing graph translator.
Extra source coordinates remain full precision. Real-time noise, transparency,
lighting and reflections differ from Blender Cycles; this is not pixel-identical
path tracing.

Performance uses engine-generated distance LODs, interior distance visibility,
shared materials and separate simplified shadow geometry. Those shadow meshes
never replace the visible close-up master. No raw photo references, source
gallery images or authoring scripts are shipped as game assets.

Vehicle pitch, wheelbase and wheel diameter match the existing simulation
datums, preserving axle/joint sound timing. Couplers, doors, shutters and
interior fittings are visual/static; dynamic coupler tension/compression and
operating coach doors are not implemented. ICF source screw links depict their
authored hanging state; WAP-7 transition hardware is not a certified coupling
model.

## Rebuild and verify

`tools/coach_v02_sources.json` pins source paths and Git blob hashes. Download
with `tools/fetch_port_sources.mjs` to `.local/coach-v02-source`, then run
`tools/blender/port_tf3_assets.py` in background Blender with selected `icf_*`
and `lhb_*` IDs. The existing WAP-7 and VB pins remain separate. The converter
never saves over source masters and disables their embedded scripts.

The material compiler stages shader definitions in `.local/<id>-materials.json`;
install them with Godot MCP, then rescan/import. Close the editor, run
`python tools/configure_coach_imports.py`, then import again. This disables mesh
compression so authored material coordinates stay full precision, enables marking
mipmaps and disables name-suffix processing. In particular, `_alpha` in the LHB
glass material is an authored identifier, not a Godot import instruction.

Checks: `tools/check_coach_port.py` verifies glTF geometry, shader presence, texture hashes,
mechanical datums and capacities; `tools/blender/check_coach_sources.py` performs
a separate read-only census of every visible source object and evaluated triangle.
Native asset checks exercise train articulation and audio geometry on straight
and curved track. `tools/check_coach_detail.gd` reviews all fourteen classes through
the actual adapter in exterior, aisle and seat views. `tools/check_coach_traffic.gd`
exercises the seven-train Kerala scene, first/middle/last coach controls and audio
axle geometry, and records native frame times. Run these two with a graphics device;
they save review images under `.local/`. Required simulation tests remain
`tests/run_tests.gd`.
Pass `-- --vb-ec` to the native detail check to review the three updated VB EC
masters in the same way.

Playtest: F9 selects ICF or LHB. V enters a passenger view; PgUp/PgDn walks
through the seven classes, Home switches aisle/seat and arrow keys change bays.
Inspect 1A privacy walls, 2A curtains, folded sleeper berths, CC chairs, GS benches,
window openings, exterior class lettering and underframe running gear. Alt+1/2/3
still selects the first, middle or trailing passenger coach on a traffic service.
