"""Inventory pinned coastal Blender masters, without executing source scripts."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / '.local/coastal-station-source'


def sources(codes=None):
    manifest = json.loads((ROOT / 'tools/coastal_station_sources.json').read_text())
    result = []
    for station in manifest['stations']:
        if codes and station['code'] not in codes: continue
        folder = BASE / station['path']
        for parts in folder.glob('*.blend.parts'):
            spec = json.loads((parts / 'manifest.json').read_text())
            data = bytearray()
            for part in spec['parts']:
                path = (parts / part['filename']).resolve()
                assert path.parent == parts.resolve()
                block = path.read_bytes()
                assert len(block) == part['size']
                assert hashlib.sha256(block).hexdigest() == part['sha256']
                data.extend(block)
            assert len(data) == spec['size']
            assert hashlib.sha256(data).hexdigest() == spec['sha256']
            target = folder / spec['filename']
            assert target.resolve().parent == folder.resolve()
            if not target.exists(): target.write_bytes(data)
            assert target.read_bytes() == data
        files = list(folder.glob('*.blend'))
        assert len(files) == 1, (station['code'], files)
        relative=files[0].relative_to(BASE).as_posix()
        blob=next((f for f in manifest['files'] if f['path']==relative),None)
        if blob:
            raw=files[0].read_bytes()
            assert hashlib.sha1(('blob %d\0'%len(raw)).encode()+raw).hexdigest()==blob['sha'],relative
        result.append(dict(station, source=str(files[0])))
    return result


if __name__ == '__main__':
    import bpy
    import sys
    from mathutils import Vector
    codes=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else None
    for station in sources(codes):
        bpy.ops.wm.open_mainfile(filepath=station['source'], load_ui=False, use_scripts=False)
        report = dict(station, collections=[], materials=[])
        for collection in bpy.data.collections:
            objects = [o for o in collection.objects if o.type in ('MESH','FONT','CURVE') and not o.hide_render]
            bounds = [o.matrix_world @ Vector(v) for o in objects for v in o.bound_box]
            report['collections'].append(dict(name=collection.name, objects=len(objects), hidden=collection.hide_render,
                bounds=[[min(v[a] for v in bounds) for a in range(3)], [max(v[a] for v in bounds) for a in range(3)]] if bounds else [],
                names=[o.name for o in objects]))
        for mat in bpy.data.materials:
            report['materials'].append(dict(name=mat.name,nodes=sorted({n.bl_idname for n in mat.node_tree.nodes}) if mat.use_nodes else []))
        output=ROOT/'.local/coastal-inventory'; output.mkdir(exist_ok=True)
        (output/(station['code']+'.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
        print('INVENTORY',station['code'],len(bpy.data.objects),flush=True)
