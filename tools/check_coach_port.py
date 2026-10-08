"""Integrity and mechanical contract of fourteen detailed coach transfers."""
import hashlib
import json
import struct
from fnmatch import fnmatch
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/models/ported'
pin = json.loads((ROOT / 'tools/coach_v02_sources.json').read_text())
catalog = json.loads((ASSETS / 'manifest.json').read_text())
digest = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
capacities = {'icf': [18, 46, 64, 108, 73, 72, 108], 'lhb': [24, 52, 72, 102, 78, 80, 100]}
classes = ['1a', '2a', '3a', '2s', 'cc', 'sl', 'gs']
total = 0
filters = next(line for line in (ROOT / 'export_presets.cfg').read_text().splitlines() if line.startswith('include_filter=')).split('"')[1].split(',')
for source in pin['models']:
    key = source['id']
    family, coach = key.split('_')
    spec = catalog[key]
    assert spec['source_revision'] == pin['revision'] and spec['detailed_materials']
    assert spec['source'] == source['path']
    assert len(spec['passengers']) == capacities[family][classes.index(coach)]
    assert spec['visible_source_objects'] > 1500 and spec['triangles'] > 500_000
    assert spec['mesh_groups'] <= 24, 'Fixed components must consolidate into rigid batches'
    assert spec['shadow_triangles'] < spec['triangles'] * .08
    assert len(spec['axles']) == 4 and len(spec['bogies']) == 2
    pivot = 7.3915 if family == 'icf' else 7.45
    assert all(abs(abs(b['position'][2]) - pivot) < .001 for b in spec['bogies'])
    assert all(abs(a['radius'] - .4575) < .001 for a in spec['axles'])
    assert abs(spec['pitch'] - (22.297 if family == 'icf' else 24.0)) < .001
    assert digest(ASSETS / (key + '.glb')) == spec['output_sha256']
    detail = ASSETS / (key + '_detail')
    assert any(fnmatch(f'assets/models/ported/{key}_detail/materials.json', pattern) for pattern in filters), 'Portable build needs dynamic material metadata'
    assert digest(detail / 'shadows.glb') == spec['shadow_sha256']
    raw = (ASSETS / (key + '.glb')).read_bytes()
    assert struct.unpack_from('<III', raw) == (0x46546c67, 2, len(raw))
    size, kind = struct.unpack_from('<II', raw, 12)
    assert kind == 0x4e4f534a
    gltf = json.loads(raw[20:20+size])
    triangles = 0
    for mesh in gltf['meshes']:
        for primitive in mesh['primitives']:
            triangles += gltf['accessors'][primitive['indices']]['count'] // 3
            for name in ['POSITION','NORMAL','TEXCOORD_0','TEXCOORD_1','TEXCOORD_2','TEXCOORD_3']:
                assert gltf['accessors'][primitive['attributes'][name]]['componentType'] == 5126
    assert triangles == spec['triangles']
    for dependency in spec['dependencies']:
        file = ASSETS / dependency['uri']
        assert file.stat().st_size == dependency['byteLength'] < 50 * 1024 * 1024
        assert digest(file) == dependency['sha256']
    index = json.loads((detail / 'materials.json').read_text())
    assert len(index['materials']) == spec['material_count']
    images = set()
    for material in index['materials']:
        shader = detail / 'shaders' / material['shader']
        assert shader.exists() and 'CUSTOM0' in shader.read_text()
        for image in material['textures'].values():
            images.add(image)
            data = (detail / 'textures' / image).read_bytes()
            expected = next(f for f in pin['files'] if f['path'].endswith('/textures/' + image))
            assert hashlib.sha1(f'blob {len(data)}\0'.encode() + data).hexdigest() == expected['sha']
    if family == 'icf': assert images, 'Original Hindi class marking must survive'
    imports = (ASSETS / (key + '.glb.import')).read_text()
    assert 'meshes/force_disable_compression=true' in imports
    assert 'nodes/use_name_suffixes=false' in imports
    assert 'nodes/use_node_type_suffixes=false' in imports
    total += triangles
    print(f'{key}: {triangles:,} triangles; {spec["material_count"]} authored materials; {len(spec["passengers"])} seated roots PASS')
print(f'Detailed coaches: 14 masters, {total:,} triangles, original markings and mechanical datums PASS')
