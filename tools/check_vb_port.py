"""Offline integrity of all seven full-size Vande Bharat v02 source transfers."""
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
folder = ROOT / 'assets/models/ported'
catalog = json.loads((folder / 'manifest.json').read_text())
pin = json.loads((ROOT / 'tools/vb_v02_sources.json').read_text())
digest = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
total = 0
for key, spec in catalog.items():
    if not key.startswith('vb_'):
        continue
    assert spec['source_revision'] == pin['revision']
    assert spec['detailed_materials'] and spec['pitch'] == 24
    assert spec['visible_source_objects'] > 1500
    assert spec['triangles'] > 1_000_000
    assert spec['shadow_triangles'] < spec['triangles'] * .1
    assert digest(folder / (key + '.glb')) == spec['output_sha256']
    detail = folder / (key + '_detail')
    assert digest(detail / 'shadows.glb') == spec['shadow_sha256']
    raw = (folder / (key + '.glb')).read_bytes()
    assert struct.unpack_from('<III', raw) == (0x46546c67, 2, len(raw))
    size, kind = struct.unpack_from('<II', raw, 12)
    assert kind == 0x4e4f534a
    gltf = json.loads(raw[20:20+size])
    triangles = 0
    for mesh in gltf['meshes']:
        for primitive in mesh['primitives']:
            triangles += gltf['accessors'][primitive['indices']]['count'] // 3
            for name in ['POSITION', 'NORMAL', 'TEXCOORD_0', 'TEXCOORD_1', 'TEXCOORD_2', 'TEXCOORD_3']:
                assert gltf['accessors'][primitive['attributes'][name]]['componentType'] == 5126
    assert triangles == spec['triangles']
    for dep in spec['dependencies']:
        path = folder / dep['uri']
        assert path.stat().st_size == dep['byteLength'] < 50 * 1024 * 1024
        assert digest(path) == dep['sha256']
    index = json.loads((detail / 'materials.json').read_text())
    assert len(index['materials']) == spec['material_count']
    for mat in index['materials']:
        shader = detail / 'shaders' / mat['shader']
        assert shader.exists() and 'CUSTOM0' in shader.read_text()
    assert len(spec['axles']) == 4 and len(spec['bogies']) == 2
    assert len(spec['passengers']) >= 40
    assert all(abs(abs(b['position'][2]) - 7.45) < .001 for b in spec['bogies'])
    assert all(abs(a['radius'] - .476) < .001 for a in spec['axles'])
    assert 'meshes/force_disable_compression=true' in (folder / (key + '.glb.import')).read_text()
    total += triangles
    print(f'{key}: {triangles:,} triangles, {spec["visible_source_objects"]:,} source objects, {len(spec["passengers"])} seats PASS')
print(f'Vande Bharat: seven full-size masters, {total:,} preserved triangles, native articulation, material graphs and dependency hashes PASS')
