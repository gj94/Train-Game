**Current portable exports:** All **53 overnight entries** have checked current selections: **52 active stations plus the separately labelled historical TNU entry**. Use the [current portable export list](PORTABLE_EXPORTS.md). Original archives remain as history; packed Blender scenes retain the full procedural appearance. [Correction history and limitations](EXPORT_MATERIAL_NOTICE.md).

# Open and verify station models

Each completed station has an editable Blender source and a portable export, with a file manifest and source/render provenance. Consult that station's README for its exact files, software requirements and limitations.

The packed `.blend` and verified portable export are the primary deliverables. Retained builder, repair, render and export scripts preserve exact build provenance. They may reference absolute paths, inputs or shared helpers from the original working environment. A clean standalone rebuild outside that workspace has not been tested; the retained scripts are not presented as a tested portable build command. Opening the packed scene or importing the recovered GLB does not require rebuilding from those scripts.

The packed `.blend` is authoritative for the complete procedural Blender materials. GLB retains exported geometry and any embedded original sign textures. Procedural surface noise and other unsupported Blender-node effects use the exporter's PBR material approximation; the northern exports contain original sign images, without baked procedural texture maps. Lossless `.glb.gz` and `.glb.zip` packaging reproduces the verified GLB bytes exactly. This is a transport-byte guarantee; the packed Blender source retains the complete procedural shading.

## Files stored as transport parts

GitHub connector size limits require binaries over 20 MiB to be split into exact 16 MiB parts. No geometry or detail is removed. A folder ending in `.parts` contains `manifest.json`, numbered `.bin` parts and `reassemble.py`; the parts cannot be opened individually.

Download the repository or the complete relevant `.parts` folder, preserving its structure. With Python 3 installed, run `python reassemble.py` from that folder. The script checks every part and the whole-file SHA256, writes the original into the parent directory, and refuses to overwrite an existing different file. No additional Python packages are needed.

For all split files in this collection, run `python reassemble_all.py` from the collection directory. Existing already-verified models are skipped. Lossless `.gz` and `.zip` export archives then need normal decompression or extraction before opening.

Large whole-model attachments may exceed the chat attachment limit. The verified GitHub files and exact-byte parts are the durable delivery route. Preview images alone are not the model source.

## Inspect furnished rooms

In the middle station scenes, the Blender Outliner groups removable building roofs under `06_LIFT_OFF_ROOFS` and reconstructed room furnishings under `07_FURNISHED_INTERIORS_RECONSTRUCTED`. Hide the roof collection to inspect the rooms while leaving the furnishings visible. The saved `05_TICKET_INTERIOR` camera provides an interior viewpoint. These collection/camera names apply where present in the middle models; other stations can use their own scene organization. Hidden interiors remain reconstructions, as documented per station.

## Earlier ERS, TVC and NCJ models

See [the rich-v02 opening instructions](../south_indian_stations_v02/README.md) and [its tested all-model reassembly script](../south_indian_stations_v02/reassemble_all_models.py). Those source files and images remain unchanged.
