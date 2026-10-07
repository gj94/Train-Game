"""Offline integrity checks for the detailed WAP-7's lossless transfer."""
import hashlib
import json
import struct
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
folder=ROOT/'assets/models/ported'
spec=json.loads((folder/'manifest.json').read_text())['wap7']
pin=json.loads((ROOT/'tools/wap7_v02_sources.json').read_text())
index=json.loads((folder/'wap7_detail/materials.json').read_text())
digest=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert spec['source_revision']==pin['revision']
assert spec['triangles']==2885744 and spec['visible_source_objects']==12331
assert spec['mesh_groups']==24 and spec['material_count']==109
assert spec['shadow_triangles']<120000
assert digest(folder/'wap7.glb')==spec['output_sha256']
assert digest(folder/'wap7_detail/shadows.glb')==spec['shadow_sha256']
raw=(folder/'wap7.glb').read_bytes()
assert struct.unpack_from('<III',raw)==(0x46546c67,2,len(raw))
size,kind=struct.unpack_from('<II',raw,12)
assert kind==0x4e4f534a
gltf=json.loads(raw[20:20+size])
for dependency in spec['dependencies']:
    p=folder/dependency['uri']
    assert digest(p)==dependency['sha256']
    assert p.stat().st_size==dependency['byteLength']<50*1024*1024
triangles=0
for mesh in gltf['meshes']:
    for primitive in mesh['primitives']:
        triangles+=gltf['accessors'][primitive['indices']]['count']//3
        for name in ['POSITION','NORMAL','TEXCOORD_0','TEXCOORD_1','TEXCOORD_2','TEXCOORD_3']:
            accessor=gltf['accessors'][primitive['attributes'][name]]
            assert accessor['componentType']==5126, name+' must remain 32-bit float'
assert triangles==spec['triangles']
sources={f['path'].replace('\\','/').rsplit('/',1)[-1]:f for f in pin['files'] if '/textures/' in f['path']}
textures={name for mat in index['materials'] for name in mat['textures'].values()}
for name in textures:
    pixels=(folder/'wap7_detail/textures'/name).read_bytes()
    expected=sources[name]
    git_hash=hashlib.sha1(f'blob {len(pixels)}\0'.encode()+pixels).hexdigest()
    assert git_hash==expected['sha'], 'Native image pixels changed: '+name
assert len(textures)==40
for mat in index['materials']:
    shader=folder/'wap7_detail/shaders'/mat['shader']
    assert shader.exists()
    assert 'CUSTOM0' in shader.read_text()
staged=ROOT/'.local/wap7-materials.json'
if staged.exists():
    for mat in json.loads(staged.read_text()):
        assert (folder/'wap7_detail/shaders'/mat['shader']).read_text()==mat['code']
print(f'WAP-7 integrity: {triangles:,} triangles, 40 exact source images, 109 materials, full float coordinates, dependency/shader hashes PASS')
