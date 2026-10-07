"""Convert the pinned, user-owned Blender masters to metre-scale Godot GLBs.

Run only in background Blender. Never executes the downloaded source scripts or
saves over the masters. Meshes are consolidated per rigid parent, retaining
materials, UVs, split normals, mechanical pivots and interior geometry.
"""
import bpy
import hashlib
import json
import math
import sys
from pathlib import Path
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / '.local/transport-fever-3-mods'
PIN = json.loads((ROOT / 'tools/port_sources.json').read_text())
OUT = ROOT / 'assets/models/ported'
# glTF performs Z-up -> Y-up; first turn the author's +X forward to Blender +Y.
C = Matrix.Rotation(math.pi / 2, 4, 'Z')
D = Matrix.Rotation(-math.pi / 2, 4, 'X') @ C
SKIP = ('PAX_', 'PASSENGER_SEATED_', 'BERTH_', 'DRIVER_')
CLASSES = ('1a', '2a', '3a', '2s', 'cc', 'sl', 'gs')


def vec(v):
    return [round(float(x), 7) for x in v]


def convert(entry, source=SOURCE, pin=PIN, detailed=False):
    key = entry['id']
    path = source / entry['path']
    raw = path.read_bytes()
    expected = next(f['sha'] for f in pin['files'] if f['path'] == entry['path'])
    assert hashlib.sha1(f'blob {len(raw)}\0'.encode() + raw).hexdigest() == expected
    bpy.ops.wm.open_mainfile(filepath=str(path), load_ui=False, use_scripts=False)
    root = next(o for o in bpy.data.objects if o.type == 'EMPTY' and not o.parent and 'ROOT' in o.name.upper())
    objects = [root, *root.children_recursive]
    source_object_count = len(objects)
    assert not any(o.library for o in objects), 'Per-car source must be self-contained'
    if detailed:
        # A rigid interior batch can be culled at distance without removing any
        # source detail. Preserve every member's original world transform.
        body = bpy.data.objects['BODY']
        machinery = bpy.data.objects.new('MACHINERY_INTERIOR', None)
        bpy.context.scene.collection.objects.link(machinery)
        machinery.parent = body
        for ob in objects:
            if ob.name.startswith('MACHV02_') and ob.parent == body:
                world_matrix = ob.matrix_world.copy()
                ob.parent = machinery
                ob.matrix_world = world_matrix
        objects.append(machinery)
        bpy.context.view_layer.update()
    # Evaluate the documented rigid mechanisms ourselves; Blender drivers are
    # not a portable animation format and source auto-run stays disabled.
    pantos = []
    for ctrl in objects:
        if ctrl.type != 'EMPTY' or 'PANTO' not in ctrl.name or not ctrl.name.endswith('_CTRL'):
            continue
        prefix = ctrl.name[:-5]
        base, arms, low, sign = (4.212, 2.45, math.radians(1), -1)
        if key.startswith('vb_'):
            base, arms = 4.032, 2.7
        elif key == 'wag9':
            base, arms = 4.149, 2.53
            low = math.asin((4.255 - base) / arms)
        elif key.startswith('wag12'):
            base, arms, sign = 4.168, 4.4, 1
            low = math.asin((4.245 - base) / arms)
        names = [prefix + '_' + s for s in ('LOWER_PIVOT', 'ELBOW_PIVOT', 'HEAD_LEVEL_PIVOT')]
        for name, factor in zip(names, (sign, -2 * sign, sign)):
            ob = bpy.data.objects[name]
            ob.animation_data_clear()
            ob.rotation_euler.y = factor * low
        pantos.append(dict(nodes=names, base=base, arms=arms, lower_angle=low, sign=sign))
    bpy.context.view_layer.update()
    keep = [o for o in objects if o.type == 'EMPTY' and not o.name.startswith(SKIP)]
    coll = bpy.data.collections.new('GODOT_PORT')
    bpy.context.scene.collection.children.link(coll)
    mapped = {}
    for old in keep:
        ob = bpy.data.objects.new('PORT_' + old.name, None)
        coll.objects.link(ob)
        mapped[old] = ob
    for old, ob in mapped.items():
        parent = old.parent
        while parent and parent not in mapped:
            parent = parent.parent
        if parent:
            ob.parent = mapped[parent]
            local = parent.matrix_world.inverted() @ old.matrix_world
        else:
            local = old.matrix_world
        ob.matrix_basis = C @ local @ C.inverted()
    # Work from evaluated geometry: bevels/text/modifiers are baked only here.
    groups = {}
    visible_objects = 0
    material_sources = {}
    group_frames = {}
    for ob in objects:
        if ob.type not in {'MESH', 'FONT', 'CURVE'}:
            continue
        if detailed and (ob.hide_render or any(c.hide_render for c in ob.users_collection)):
            continue
        visible_objects += 1
        parent = ob.parent
        while parent and parent not in mapped:
            parent = parent.parent
        groups.setdefault(parent or root, []).append(ob)
    dg = bpy.context.evaluated_depsgraph_get()
    materials = {}
    all_bounds = []
    triangles = 0
    for parent, members in groups.items():
        vertices, faces, normals, uvs, indices, slots = [], [], [], [], [], []
        coordinates, generated_uvs = [], []
        for ob in members:
            evaluated = ob.evaluated_get(dg)
            mesh = evaluated.to_mesh(preserve_all_data_layers=True, depsgraph=dg)
            if not mesh or not len(mesh.vertices):
                if detailed: visible_objects -= 1
                evaluated.to_mesh_clear()
                continue
            transform = C @ parent.matrix_world.inverted() @ ob.matrix_world
            normal_transform = transform.to_3x3().inverted().transposed()
            offset = len(vertices)
            vertices.extend(tuple(transform @ v.co) for v in mesh.vertices)
            all_bounds.extend(D @ ob.matrix_world @ v.co for v in mesh.vertices)
            active_uv = mesh.uv_layers.active
            if detailed:
                minimum = Vector([min(v.co[i] for v in mesh.vertices) for i in range(3)])
                extent = Vector([max(v.co[i] for v in mesh.vertices) for i in range(3)]) - minimum
            for poly in mesh.polygons:
                mat = mesh.materials[poly.material_index] if poly.material_index < len(mesh.materials) else None
                if mat and mat.name not in materials:
                    material_sources[mat.name] = mat
                    copy = mat.copy()
                    copy.name = key + '_' + mat.name
                    copy.use_backface_culling = True
                    p = copy.node_tree.nodes.get('Principled BSDF') if copy.use_nodes else None
                    if p and (p.inputs['Transmission Weight'].default_value > .1 or p.inputs['Alpha'].default_value < .99):
                        p.inputs['Transmission Weight'].default_value = 0
                        p.inputs['Alpha'].default_value = .16
                        p.inputs['Metallic'].default_value = 0
                        p.inputs['Roughness'].default_value = .12
                        copy.surface_render_method = 'DITHERED'
                    materials[mat.name] = copy
                material = materials.get(mat.name) if mat else None
                selected_uv = active_uv
                if detailed and mat:
                    named = next((n.uv_map for n in mat.node_tree.nodes if n.type == 'UVMAP'), None)
                    if named:
                        selected_uv = mesh.uv_layers.get(named)
                        assert selected_uv, f'{ob.name}: missing {named}'
                if material not in slots:
                    slots.append(material)
                # The VB authoring ceiling uses the outer roof's upward winding.
                # Renderers with backface culling need an inward-facing lining.
                inward_ceiling = key.startswith('vb_') and ob.name.startswith('Curved_ceiling_inner')
                face_vertices = list(poly.vertices)
                face_loops = list(poly.loop_indices)
                if inward_ceiling:
                    face_vertices.reverse()
                    face_loops.reverse()
                faces.append(tuple(offset + i for i in face_vertices))
                indices.append(slots.index(material))
                triangles += len(poly.vertices) - 2
                for loop in face_loops:
                    normal = (normal_transform @ mesh.corner_normals[loop].vector).normalized()
                    normals.append(tuple(-normal if inward_ceiling else normal))
                    uvs.append(tuple(selected_uv.data[loop].uv) if selected_uv else (0, 0))
                    if detailed:
                        co = mesh.vertices[mesh.loops[loop].vertex_index].co
                        gen = [(co[i]-minimum[i])/extent[i] if extent[i] > 1e-9 else 0.0 for i in range(3)]
                        coordinates.append((*co,gen[2]))
                        generated_uvs.append(gen[:2])
            evaluated.to_mesh_clear()
        merged = bpy.data.meshes.new(key + '_' + parent.name)
        merged.from_pydata(vertices, [], faces)
        for mat in slots:
            merged.materials.append(mat)
        for poly, idx in zip(merged.polygons, indices):
            poly.material_index = idx
            poly.use_smooth = True
        merged.normals_split_custom_set(normals)
        uv = merged.uv_layers.new(name='UVMap')
        for loop, xy in zip(uv.data, uvs):
            loop.uv = xy
        if detailed:
            gen_uv = merged.uv_layers.new(name='GeneratedXY')
            gen_uv.data.foreach_set('uv', [v for c in generated_uvs for v in c])
            object_xy = merged.uv_layers.new(name='ObjectXY')
            object_xy.data.foreach_set('uv', [v for c in coordinates for v in c[:2]])
            object_z = merged.uv_layers.new(name='ObjectZ_GeneratedZ')
            object_z.data.foreach_set('uv', [v for c in coordinates for v in c[2:]])
            merged.uv_layers.active_index = 0
        visual = bpy.data.objects.new('Visual_' + parent.name, merged)
        coll.objects.link(visual)
        visual.parent = mapped[parent]
        visual.matrix_basis = Matrix.Identity(4)
        if detailed:
            group_frames[visual.name] = [list(row) for row in parent.matrix_world @ D.inverted()]
    # Remove the source objects from the active scene, freeing their original
    # names without modifying or saving any authoring files.
    for old, ob in mapped.items():
        name = old.name
        old.name = 'SOURCE_' + name
        ob.name = name
    bpy.ops.object.select_all(action='DESELECT')
    for ob in coll.objects:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = mapped[root]
    OUT.mkdir(parents=True, exist_ok=True)
    shaders = []
    if detailed:
        # glTF can repack images and clear their source file paths; capture the
        # original graphs and image pixels before invoking its exporter.
        sys.path.insert(0, str(Path(__file__).parent))
        from wap7_materials import export_materials
        shaders = export_materials(material_sources.values(), OUT/'wap7_detail/textures')
        (ROOT/'.local/wap7-materials.json').write_text(json.dumps(shaders,indent=2))
        material_index = [{k:v for k,v in m.items() if k != 'code'} for m in shaders]
        (OUT/'wap7_detail/materials.json').write_text(json.dumps(dict(materials=material_index,frames=group_frames),indent=2)+'\n')
    export_options = dict(export_vertex_color='NONE', export_attributes=True) if detailed else {}
    export_path = ROOT/'.local/wap7-detail-export.glb' if detailed else OUT/(key+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(export_path), export_format='GLB',
        use_selection=True, export_yup=True, export_animations=False, export_cameras=False,
        export_lights=False, export_extras=False, export_materials='EXPORT', **export_options)
    dependencies = []
    if detailed:
        sys.path.insert(0, str(Path(__file__).parent))
        from split_gltf_buffers import split_glb
        dependencies = split_glb(export_path, OUT/(key+'.glb'))
    coupling = [o for o in keep if o.name.replace('SOURCE_', '') in ('COUPLING_FRONT', 'COUPLING_REAR')]
    pitch = abs(coupling[0].matrix_world.translation.x - coupling[1].matrix_world.translation.x)
    bogies = [o for o in keep if 'BOGIE' in o.name and 'AXLE' not in o.name]
    axles = [o for o in keep if 'AXLE' in o.name]
    eyes = [o for o in keep if 'CAB_EYE_CAMERA_REFERENCE' in o.name]
    passengers = [o for o in objects if o.type == 'EMPTY' and o.name.startswith(('PAX_', 'PASSENGER_SEATED_'))]
    lo = [min(v[i] for v in all_bounds) for i in range(3)]
    hi = [max(v[i] for v in all_bounds) for i in range(3)]
    clean = lambda o: o.name.removeprefix('SOURCE_')
    result = dict(id=key, pitch=round(pitch, 6), bounds=[vec(lo), vec(hi)],
        bogies=[dict(node=clean(o), position=vec(D @ o.matrix_world.translation)) for o in bogies],
        axles=[dict(node=clean(o), position=vec(D @ o.matrix_world.translation), radius=round(o.matrix_world.translation.z, 6)) for o in axles],
        eyes=[dict(node=clean(o), position=vec(D @ o.matrix_world.translation)) for o in eyes],
        passengers=[dict(position=vec(D @ o.matrix_world.translation), forward=vec((D @ o.matrix_world.to_3x3().col[0].to_4d()).to_3d())) for o in passengers],
        pantographs=pantos, source=entry['path'], source_sha256=hashlib.sha256(raw).hexdigest(),
        source_objects=source_object_count, mesh_groups=len(groups), triangles=triangles,
        output_sha256=hashlib.sha256((OUT / (key + '.glb')).read_bytes()).hexdigest())
    if key == 'wap7':
        result['eyes'] = [dict(position=[-.78, 3.05, -7.52]), dict(position=[.78, 3.05, 7.52])]
    if detailed:
        result.update(detailed_materials=True, source_revision=pin['revision'], visible_source_objects=visible_objects,
                      dependencies=dependencies,
                      material_count=len(shaders), coordinate_encoding='TEXCOORD_1 = generated.xy; TEXCOORD_2 = object.xy; TEXCOORD_3 = object.z/generated.z (32-bit floats)',
                      hidden_legacy_excluded=True)
        result['eyes'] = [dict(position=[-.78,3.05,-7.98]),dict(position=[.78,3.05,7.98])]
        print('DETAIL MATERIALS',len(shaders),'visible objects',visible_objects,flush=True)
        from wap7_shadows import export_shadows
        shadow_path=OUT/'wap7_detail/shadows.glb'
        result['shadow_triangles']=export_shadows([o for o in coll.objects if o.type=='MESH'],shadow_path)
        result['shadow_sha256']=hashlib.sha256(shadow_path.read_bytes()).hexdigest()
        print('SHADOW TRIANGLES',result['shadow_triangles'],flush=True)
    print('PORTED', key, len(objects), 'objects ->', len(groups), 'rigid mesh groups', flush=True)
    return result


def main():
    selected = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    report_path = OUT / 'manifest.json'
    report = json.loads(report_path.read_text()) if report_path.exists() else {}
    for entry in PIN['models']:
        if selected and entry['id'] not in selected:
            continue
        if entry['id'] == 'wap7':
            detail_pin = json.loads((ROOT/'tools/wap7_v02_sources.json').read_text())
            report['wap7'] = convert(detail_pin['models'][0], ROOT/'.local/wap7-v02-source', detail_pin, True)
        else:
            report[entry['id']] = convert(entry)
        report_path.write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
