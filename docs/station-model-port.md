# ERS, TVC and Nagercoil station models

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
