"""Read-only editable-master audit. Run with background Blender/autoexec disabled."""
import json
from pathlib import Path
import bpy

root = Path(__file__).resolve().parents[2]
catalog = json.loads((root / 'assets/models/scenery/manifest.json').read_text())
names = sorted(catalog) + ['tree_small_02_adapted']
for name in names:
    path = root / 'art/scenery' / (name + '.blend')
    bpy.ops.wm.open_mainfile(filepath=str(path), load_ui=False, use_scripts=False)
    meshes = [obj for obj in bpy.data.objects if obj.type == 'MESH']
    assert len(meshes) == 1 and len(meshes[0].data.vertices) > 0, path.name
    for image in bpy.data.images:
        if image.source == 'FILE':
            assert image.packed_file is not None or len(image.packed_files) > 0, (path.name, image.name)
    print('MASTER_OK', path.name, flush=True)
print(f'All {len(names)} scenery masters open with one editable mesh and no external image dependencies.', flush=True)
