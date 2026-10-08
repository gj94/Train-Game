"""Read-only independent source census; run in background Blender after porting."""
import bpy
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
pin = json.loads((ROOT / 'tools/coach_v02_sources.json').read_text())
catalog = json.loads((ROOT / 'assets/models/ported/manifest.json').read_text())
report = {}
for entry in pin['models']:
    path = ROOT / '.local/coach-v02-source' / entry['path']
    spec = catalog[entry['id']]
    assert hashlib.sha256(path.read_bytes()).hexdigest() == spec['source_sha256']
    bpy.ops.wm.open_mainfile(filepath=str(path), load_ui=False, use_scripts=False)
    root = next(o for o in bpy.data.objects if o.type == 'EMPTY' and not o.parent and 'ROOT' in o.name.upper())
    graph = bpy.context.evaluated_depsgraph_get()
    count = triangles = 0
    for obj in root.children_recursive:
        if obj.type not in {'MESH','FONT','CURVE'} or obj.hide_render or any(c.hide_render for c in obj.users_collection):
            continue
        evaluated = obj.evaluated_get(graph)
        mesh = evaluated.to_mesh()
        if mesh and len(mesh.vertices):
            count += 1
            mesh.calc_loop_triangles()
            triangles += len(mesh.loop_triangles)
        evaluated.to_mesh_clear()
    assert count == spec['visible_source_objects'], (entry['id'], count, spec['visible_source_objects'])
    assert triangles == spec['triangles'], (entry['id'], triangles, spec['triangles'])
    report[entry['id']] = dict(visible_objects=count, evaluated_triangles=triangles, source_sha256=spec['source_sha256'])
    print('SOURCE_CENSUS_PASS', entry['id'], count, triangles, flush=True)
(ROOT / '.local/coach-source-census.json').write_text(json.dumps(report, indent=2) + '\n')
