"""Publish completed staged bakes serially, verifying unchanged source inputs."""
import hashlib
import json
import shutil
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/models/ported'
STAGED = ROOT / '.local/train-fidelity/staged'


def doc(path):
    data = path.read_bytes()
    length, = struct.unpack_from('<I', data, 12)
    return json.loads(data[20:20 + length])


def preserved(before, after):
    assert before['nodes'] == after['nodes'], 'Rig/pivots changed'
    assert before['materials'] == after['materials'], 'Authored material slots changed'
    assert before['buffers'] == after['buffers'][:-1], 'Original buffers changed'
    assert before['accessors'] == after['accessors'][:len(before['accessors'])]
    assert before['bufferViews'] == after['bufferViews'][:len(before['bufferViews'])]
    assert len(before['meshes']) == len(after['meshes'])
    vertices = 0
    for bm, am in zip(before['meshes'], after['meshes']):
        assert len(bm['primitives']) == len(am['primitives'])
        for bp, ap in zip(bm['primitives'], am['primitives']):
            clean = dict(ap, attributes={k:v for k,v in ap['attributes'].items() if k != 'COLOR_0'})
            assert bp == clean, 'Geometry, UVs or indices changed'
            a = after['accessors'][ap['attributes']['COLOR_0']]
            assert a['count'] == before['accessors'][bp['attributes']['POSITION']]['count']
            assert a['componentType'] == 5121 and a['normalized'] and a['type'] == 'VEC4'
            vertices += a['count']
    return vertices


if __name__ == '__main__':
    path = ASSETS / 'manifest.json'
    catalogue = json.loads(path.read_text())
    for metadata in sorted(STAGED.glob('*.json')):
        key = metadata.stem
        spec = json.loads(metadata.read_text())
        current = ASSETS / (key + '.glb')
        staged = STAGED / (key + '.glb')
        if 'occlusion' in catalogue[key]:
            assert catalogue[key] == spec and hashlib.sha256(current.read_bytes()).hexdigest() == spec['output_sha256'], 'Existing bake differs: ' + key
            print('ALREADY_INSTALLED', key)
            continue
        vertices = preserved(doc(current), doc(staged))
        assert spec['dependencies'][:-1] == catalogue[key]['dependencies']
        assert hashlib.sha256(staged.read_bytes()).hexdigest() == spec['output_sha256']
        for dep in spec['dependencies']:
            source = STAGED / dep['uri'] if dep['uri'].endswith('/occlusion.bin') else ASSETS / dep['uri']
            assert source.stat().st_size == dep['byteLength']
            assert hashlib.sha256(source.read_bytes()).hexdigest() == dep['sha256']
        shutil.copyfile(STAGED / spec['dependencies'][-1]['uri'], ASSETS / spec['dependencies'][-1]['uri'])
        shutil.copyfile(staged, current)
        catalogue[key] = spec
        # Write after each complete model to allow a safe interrupted install.
        path.write_text(json.dumps(catalogue, indent=2) + '\n', newline='\n')
        print('INSTALLED', key, vertices, 'vertices; all original streams unchanged')
