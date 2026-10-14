"""Offline visibility bake over the exact imported train geometry (background Blender).

Adds normalized COLOR_0 bytes in a separate buffer; positions, split normals,
indices, UVs, author coordinates, pivots and textures remain byte-identical.
R: short-range contact visibility. G: enclosure visibility. B/A: one.
No sunlight, colour, camera, world position or time of day is baked.
"""
import argparse
import hashlib
import json
import math
import struct
import sys
import time
from pathlib import Path

import numpy as np
from mathutils import Matrix, Quaternion, Vector
from mathutils.bvhtree import BVHTree

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / 'assets/models/ported'
DTYPES = {5121: '<u1', 5123: '<u2', 5125: '<u4', 5126: '<f4'}
WIDTHS = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}


def read_model(key):
    path = ASSETS / (key + '.glb')
    raw = path.read_bytes()
    size, kind = struct.unpack_from('<II', raw, 12)
    assert kind == 0x4e4f534a
    doc = json.loads(raw[20:20 + size])
    buffers = [(ASSETS / b['uri']).read_bytes() for b in doc['buffers']]
    return path, doc, buffers


def accessor(doc, buffers, idx):
    a = doc['accessors'][idx]
    v = doc['bufferViews'][a['bufferView']]
    dtype = np.dtype(DTYPES[a['componentType']])
    width = WIDTHS[a['type']]
    stride = v.get('byteStride', dtype.itemsize * width)
    return np.ndarray((a['count'], width), dtype=dtype, buffer=buffers[v['buffer']],
                      offset=v.get('byteOffset', 0) + a.get('byteOffset', 0),
                      strides=(stride, dtype.itemsize))


def placements(doc):
    result = []
    def visit(index, parent):
        node = doc['nodes'][index]
        if 'matrix' in node:
            transform = Matrix(np.array(node['matrix']).reshape(4, 4).T.tolist())
        else:
            q = node.get('rotation', [0, 0, 0, 1])
            transform = Matrix.LocRotScale(Vector(node.get('translation', [0, 0, 0])),
                Quaternion((q[3], *q[:3])), Vector(node.get('scale', [1, 1, 1])))
        transform = parent @ transform
        if 'mesh' in node:
            result.append((index, node['mesh'], transform))
        for child in node.get('children', []):
            visit(child, transform)
    for node in doc['scenes'][doc.get('scene', 0)]['nodes']:
        visit(node, Matrix.Identity(4))
    return result


def bake(key, samples, stage=False):
    started = time.monotonic()
    path, doc, buffers = read_model(key)
    assert 'train_occlusion' not in doc.get('extras', {}), 'Already baked: ' + key
    material_index = json.loads((ASSETS / (key + '_detail/materials.json')).read_text())
    glass = {m['name'] for m in material_index['materials'] if m['glass']}
    positions, triangles, surfaces = [], [], []
    count = 0
    # Store shared-position accessors once per primitive. A glTF vertex can have
    # different normals at material edges, so the bake preserves split normals.
    for node_idx, mesh_idx, transform in placements(doc):
        matrix = np.array(transform, dtype=np.float64)
        normal_matrix = np.linalg.inv(matrix[:3, :3]).T
        for primitive in doc['meshes'][mesh_idx]['primitives']:
            attr = primitive['attributes']
            local = accessor(doc, buffers, attr['POSITION'])
            normal = accessor(doc, buffers, attr['NORMAL']) @ normal_matrix.T
            normal /= np.maximum(np.linalg.norm(normal, axis=1, keepdims=True), 1e-10)
            position = local @ matrix[:3, :3].T + matrix[:3, 3]
            role = doc['materials'][primitive['material']]['name']
            optical = role in glass or any(s in role.lower() for s in ('decal', '_art_', 'legend'))
            surfaces.append((primitive, position, normal, optical, doc['nodes'][node_idx].get('name', '')))
            if optical:
                continue
            indices = accessor(doc, buffers, primitive['indices']).reshape(-1, 3)
            positions.append(position)
            triangles.append(indices.astype(np.int64) + count)
            count += len(position)
    vertices = np.concatenate(positions)
    faces = np.concatenate(triangles)
    bvh = BVHTree.FromPolygons(vertices.tolist(), faces.tolist(), all_triangles=True)
    del vertices, faces, positions, triangles
    print('BAKE_START', key, 'surfaces', len(surfaces), 'samples', samples, flush=True)
    # Cosine-weighted, stratified hemisphere. No randomness/no temporal noise.
    directions = []
    for i in range(samples):
        radius = math.sqrt((i + .5) / samples)
        angle = i * math.pi * (3 - math.sqrt(5))
        directions.append((radius * math.cos(angle), radius * math.sin(angle), math.sqrt(1 - radius * radius)))
    cache = {}
    packed = bytearray()
    summaries = []
    for si, (primitive, position, normal, optical, name) in enumerate(surfaces):
        colour = np.full((len(position), 4), 255, dtype=np.uint8)
        if not optical:
            # Repeated split vertices share a probe at 2 cm / quantized normal.
            # Rays start at the actual first surface point, never inside a voxel.
            keys = np.concatenate((np.rint(position / .02), np.rint(normal * 12)), axis=1).astype(np.int32)
            unique, first, inverse = np.unique(keys, axis=0, return_index=True, return_inverse=True)
            values = np.empty((len(unique), 2), dtype=np.uint8)
            for j, row in enumerate(unique):
                token = tuple(row)
                value = cache.get(token)
                if value is None:
                    n = Vector(normal[first[j]])
                    p = Vector(position[first[j]]) + n * .003
                    t = n.cross(Vector((0, 1, 0)) if abs(n.y) < .9 else Vector((1, 0, 0))).normalized()
                    b = n.cross(t)
                    near, far = 0.0, 0.0
                    for dx, dy, dz in directions:
                        hit, _, _, distance = bvh.ray_cast(p, t * dx + b * dy + n * dz, 5.0)
                        if hit is not None:
                            near += max(0.0, 1.0 - distance / .55)
                            far += max(0.0, 1.0 - distance / 5.0)
                    value = (round(255 * (1 - near / samples)), round(255 * (1 - far / samples)))
                    cache[token] = value
                values[j] = value
            colour[:, :2] = values[inverse]
        offset = len(packed)
        packed.extend(colour.tobytes())
        view = len(doc['bufferViews'])
        doc['bufferViews'].append({'buffer': len(doc['buffers']), 'byteOffset': offset, 'byteLength': len(colour) * 4, 'target': 34962})
        acc = len(doc['accessors'])
        doc['accessors'].append({'bufferView': view, 'componentType': 5121, 'normalized': True, 'count': len(colour), 'type': 'VEC4'})
        primitive['attributes']['COLOR_0'] = acc
        summaries.append({'mesh': name, 'vertices': len(colour), 'mean_contact': float(colour[:, 0].mean() / 255), 'mean_enclosure': float(colour[:, 1].mean() / 255)})
        if si % 25 == 0:
            print('BAKE_PROGRESS', key, si, '/', len(surfaces), 'probes', len(cache), 'seconds', round(time.monotonic() - started), flush=True)
    uri = key + '_detail/occlusion.bin'
    destination = ROOT / '.local/train-fidelity/staged' if stage else ASSETS
    (destination / (key + '_detail')).mkdir(parents=True, exist_ok=True)
    (destination / uri).write_bytes(packed)
    doc['buffers'].append({'uri': uri, 'byteLength': len(packed)})
    doc.setdefault('extras', {})['train_occlusion'] = {'version': 1, 'samples': samples, 'contact_m': .55, 'enclosure_m': 5.0, 'probe_cell_m': .02}
    encoded = json.dumps(doc, separators=(',', ':')).encode()
    encoded += b' ' * (-len(encoded) % 4)
    baked_path = destination / path.name
    baked_path.write_bytes(struct.pack('<III', 0x46546c67, 2, 20 + len(encoded)) + struct.pack('<II', len(encoded), 0x4e4f534a) + encoded)
    catalogue_path = ASSETS / 'manifest.json'
    catalogue = json.loads(catalogue_path.read_text())
    catalogue[key]['output_sha256'] = hashlib.sha256(baked_path.read_bytes()).hexdigest()
    catalogue[key]['dependencies'].append({'uri': uri, 'byteLength': len(packed), 'sha256': hashlib.sha256(packed).hexdigest()})
    catalogue[key]['occlusion'] = doc['extras']['train_occlusion']
    if stage:
        (destination / (key + '.json')).write_text(json.dumps(catalogue[key], indent=2) + '\n')
    else:
        catalogue_path.write_text(json.dumps(catalogue, indent=2) + '\n')
    result = {'key': key, 'seconds': time.monotonic() - started, 'probes': len(cache), 'bytes': len(packed), 'surfaces': summaries}
    out = ROOT / '.local/train-fidelity/bakes'
    out.mkdir(parents=True, exist_ok=True)
    (out / (key + '.json')).write_text(json.dumps(result, indent=2) + '\n')
    print('BAKE_DONE', key, round(result['seconds'], 1), 'seconds', len(packed), 'bytes', flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('models', nargs='+')
    parser.add_argument('--samples', type=int, default=24)
    parser.add_argument('--stage', action='store_true', help='Stage independent model outputs; do not mutate the game or shared manifest')
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
    assert 8 <= args.samples <= 128
    for key in args.models:
        bake(key, args.samples, args.stage)
