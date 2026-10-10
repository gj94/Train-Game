"""Consolidate pinned GLBs in background Blender; keep source pixels and close geometry.

Static scenery only: source masters and hinge hierarchies remain in the verified
download cache. Runtime meshes share content-addressed images across all 52 entries.
"""
import bpy
import hashlib
import json
import math
import struct
import sys
from pathlib import Path
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / '.local/trackside-source'
OUT = ROOT / 'assets/models/trackside'
INDEX = json.loads((SOURCE / 'ASSET_INDEX.json').read_text())
PIN = '16c06aee07c70eea5ed74e8420116998c27a4895'


def externalize(source, target):
    raw = source.read_bytes()
    size = struct.unpack_from('<I', raw, 12)[0]
    doc = json.loads(raw[20:20 + size])
    start = 20 + size
    binary = raw[start + 8:]
    for image in doc.get('images', []):
        view = doc['bufferViews'][image.pop('bufferView')]
        data = binary[view.get('byteOffset', 0):view.get('byteOffset', 0) + view['byteLength']]
        extension = '.jpg' if image.pop('mimeType') == 'image/jpeg' else '.png'
        name = hashlib.sha256(data).hexdigest() + extension
        path = OUT / 'textures' / name
        path.parent.mkdir(parents=True, exist_ok=True)
        if not path.exists():
            path.write_bytes(data)
        image['uri'] = 'textures/' + name
    # Only retain geometry views. Image payloads now have shared URI identities.
    used = {a['bufferView'] for a in doc['accessors'] if 'bufferView' in a}
    remap = {}
    geometry = bytearray()
    views = []
    for old in sorted(used):
        view = doc['bufferViews'][old]
        segment = binary[view.get('byteOffset', 0):view.get('byteOffset', 0) + view['byteLength']]
        geometry.extend(b'\0' * (-len(geometry) % 4))
        remap[old] = len(views)
        views.append(dict(view, buffer=0, byteOffset=len(geometry)))
        geometry.extend(segment)
    for accessor in doc['accessors']:
        if 'bufferView' in accessor:
            accessor['bufferView'] = remap[accessor['bufferView']]
        assert 'sparse' not in accessor
    doc['bufferViews'] = views
    doc['buffers'] = [{'uri': target.stem + '.bin', 'byteLength': len(geometry)}]
    target.with_suffix('.bin').write_bytes(geometry)
    target.write_text(json.dumps(doc, separators=(',', ':')))
    return len(geometry), len(doc.get('materials', []))


def convert(asset):
    name = asset['asset_id']
    path = SOURCE / 'unpacked' / asset['glb']['path_in_archive']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == asset['glb']['sha256']
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    scene = bpy.context.scene
    objects = [o for o in scene.objects if o.type == 'MESH']
    # Align facade -Z to the existing footprint/frontage convention. This is a
    # rigid turn about the source ground datum; no dimensions are stretched.
    turn = Matrix.Rotation(math.pi, 4, 'Z') if asset['category'] == 'buildings' else Matrix.Identity(4)
    for obj in objects:
        world = turn @ obj.matrix_world
        obj.parent = None
        obj.matrix_world = world
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = 'TF3_' + name
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for material in obj.data.materials:
        if material and not material.name.startswith('TF3_'):
            material.name = 'TF3_' + material.name
    # Collapse duplicated material slots after joining; keep transparency/UVs.
    materials = list(obj.data.materials)
    unique = []
    indices = []
    for material in materials:
        if material not in unique:
            unique.append(material)
        indices.append(unique.index(material))
    slots = [indices[p.material_index] for p in obj.data.polygons]
    obj.data.materials.clear()
    for material in unique:
        obj.data.materials.append(material)
    for polygon, slot in zip(obj.data.polygons, slots):
        polygon.material_index = slot
    obj.data.calc_loop_triangles()
    vertices = [Vector((v.co.x, v.co.z, -v.co.y)) for v in obj.data.vertices]
    lo = [min(v[i] for v in vertices) for i in range(3)]
    hi = [max(v[i] for v in vertices) for i in range(3)]
    temp = SOURCE / (name + '.glb')
    bpy.ops.export_scene.gltf(filepath=str(temp), export_format='GLB', use_selection=True,
                             export_cameras=False, export_lights=False, export_animations=False)
    size, surfaces = externalize(temp, OUT / (name + '.gltf'))
    entry = dict(source_id=name, source_sha256=asset['glb']['sha256'], category=asset['category'],
                 title=asset['title'], triangles=len(obj.data.loop_triangles), surfaces=surfaces,
                 godot_min=lo, godot_max=hi, godot_size=[hi[i]-lo[i] for i in range(3)],
                 geometry_bytes=size, path='res://assets/models/trackside/' + name + '.gltf')
    print('PORTED', name, entry['triangles'], surfaces, flush=True)
    return entry


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    manifest_path = OUT / 'manifest.json'
    manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else {'revision': PIN, 'assets': {}}
    only = next((a[7:].split(',') for a in sys.argv if a.startswith('--only=')), None)
    for asset in INDEX['assets']:
        if only and asset['asset_id'] not in only:
            continue
        manifest['assets']['tf3_' + asset['asset_id']] = convert(asset)
        manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
