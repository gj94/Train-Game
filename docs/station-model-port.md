# Station model ports

## R15 coastal collection — 9 October 2026

Pinned source: [coastal station collection, 089dbecca](https://github.com/gj94/transport-fever-3-mods/tree/089dbecca1d6209cc8dd35a2b431f4ec4063a490/coastal_station_collection).
All 53 newly published Blender masters were fetched with Git blob verification;
split masters additionally pass their part and whole-file SHA-256 checks. The
52 active route stations now use 51 station-specific building/interior assemblies
and Viranialur's photographed open shelters. Tirunettur's historical assembly is
retained as an asset, without inventing an active stop or a surveyed placement.
ERS/TVC/NCJ keep their previous rich-v02 assemblies below.

The active additions retain **1,394,944 evaluated triangles**, original metric
dimensions, roof profiles, structural details, room furnishings, signs, UVs,
normals and packed sign images. The 3,849 exported source objects use 137 spatial
batches, generated distance
LODs and separate simplified shadows; nearby visible geometry is not decimated.
The renderer applies source-graph material translations, including procedural
noise, brick patterns and bump. These are realtime approximations, not identical
Cycles shading. We use packed masters rather than the older GLBs with missing
fallback colours described in the source's material-correction notice.

Buildings are rigidly rotated and translated beside an outer platform; slopes
do not tilt, stretch or mirror the models. Source floor levels align with the
game platform floor. Foundations support the complete assembly, with additional
infill under southern plinths, verandas and toilet annexes. Viranialur keeps the
complete shelters belonging to its one reported platform, with an outer apron
to accommodate their original width. Its source's second, unverified platform
body and associated shelters are not introduced into the operating layout.
PNPR maps to the existing PUPR route ID and TVCS to NEM, retaining save identity.
An immutable footprint index excludes generic buildings and vegetation from
station buildings/forecourts. Road surfaces cannot cross the new building
footprints, and the ground is lowered locally when it would bury a plinth.

Scope is **station architecture and attached interiors/access**, not replacement
of the operating yards. Source platforms, track meshes, OHE, static signals,
most platform shelters/furniture, remote yard service buildings and surrounding
terrain remain in the complete local masters. The game continues to generate
those from its CSV-based layout and geographic stream. There is no station-room
walking/navigation implementation in this port. Mixed-date photographs and
inferred room layouts remain the source's disclosed reconstructions.

Provenance per asset lists source revision/hash, selected collections and object
names, actual exported objects, triangle totals, buffer hashes, dimensions and
placement metadata. Source notices, reference notes and font licences ship in
`station-notices/coastal/`. The masters stay under
`.local/coastal-station-source/`; no downloaded authoring script is executed.

Reproduce all 53 assets (or append `-- KUMM TUVR NYY` for selected stations):

```powershell
node tools/fetch_port_sources.mjs tools/coastal_station_sources.json .local/coastal-station-source
& .local/blender/blender-5.2.1-windows-x64/blender.exe --background --factory-startup --disable-autoexec --threads 3 --python tools/blender/port_coastal_stations.py
```

`tools/check_coastal_stations.gd` checks all 52 active mappings, exact imported
triangle counts, material overrides, rigid scale and building/track clearance,
and captures representative native views. `tools/check_coastal_route.gd` checks
the actual streamed stations at Kumbalam, Turavur, Kollam, Neyyattinkara and
Viranialur. Use the dispatcher station visitor and external free camera to
inspect their facades, platform sides and raised-floor foundations.

## Earlier ERS, TVC and Nagercoil assemblies

Source: [the user's station gallery at revision 1585bc2](https://github.com/gj94/transport-fever-3-mods/blob/1585bc27960fb67d970a1b5c75208ddf53597191/south_indian_stations_v02/GALLERY.md).
All three complete Blender masters were downloaded from that exact revision,
reassembled from their parts, and verified against the source SHA-256 manifests.
They remain under `.local/station-v02-source/south_indian_stations_v02/` for
further work, including the complete authored platforms, yards and interiors.
Downloaded authoring scripts are not executed; Blender auto-run stays disabled.

The operating game imports these intact building assemblies:

| Assembly | Evaluated source triangles | Source objects |
| --- | ---: | ---: |
| ERS west entrance, public rooms, sanitary rooms and forecourt | 175,780 | 1,544 |
| ERS east entrance and furnished hall | 78,008 | 374 |
| TVC heritage frontage, halls, booking office and furnished rooms | 730,906 | 5,416 |
| Nagercoil historical frontage, annex, halls and upper rooms | 2,521,091 | 1,715 |
| ERS furnished maintenance workshop | 13,548 | 202 |

Visible source geometry is not decimated: bevels, fittings, text, fixtures,
interiors, UVs and normals survive evaluated-mesh export. Geometry is grouped
into 31 spatial batches instead of 9,251 individual objects. Godot generates
distance LODs, and separate simpler meshes cast shadows; close views retain the
full detail. Source material graphs are translated to PBR shaders and packed
image pixels are retained. Procedural noise and transparent glass are realtime
approximations to Blender shading, not identical Cycles lighting/rendering.

Buildings replace the older three generic frontages. ERS gets its east hall on
the opposite side of the operating yard. The maintenance workshop is reused
beside the reconstructed depot receptions. Foundations follow the in-game site;
nearby detail streams with station scenery, and shared materials are prepared on
the main thread before worker scene assembly.

The static source yard meshes are **not** placed over the live running tracks.
Their mapped alignment/platform polygons differ from the reconstructed operating
graph and the user's CSV-selected inventory. Live platform surfaces, canopies,
bridges, pointwork, OHE and signals continue to use that graph. The source-master
yards remain available locally; this port does not claim a full operating-yard
conversion, walkable station-room navigation or a surveyed depot layout.

The sources are mixed-date reconstructions: ERS 2017, TVC 2022 and NCJ historical
2010 architecture with later mapping. Rooms and many fittings are inferred.
Provenance and font notices are preserved in `assets/models/ported/station-notices`
and the portable build's `station-notices` directory. See the asset register.

Reproduce:

```powershell
node tools/fetch_port_sources.mjs tools/station_v02_sources.json .local/station-v02-source
# Use the Python path in docs/pc-setup.md:
python tools/reassemble_station_sources.py
& .local/blender/blender-5.2.1-windows-x64/blender.exe --background --factory-startup --disable-autoexec --threads 3 --python tools/blender/port_station_sources.py -- ers tvc ncj ers_east ers_workshop
```

`*_detail/provenance.json` records source/output buffer hashes, collection scope,
geometry counts and bounds. Native `tools/check_station_models.gd` asserts the
same triangle totals and shader application and captures each building. Use the
external free camera to inspect ERS's two entrances, TVC's facade and NCJ's
lettering/columns; the complete Kerala scene check verifies streaming placement.
