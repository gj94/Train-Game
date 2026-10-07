"""Read-only inspection of the pinned WAP-7 detailed master; background Blender only."""
import bpy
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / '.local/wap7-v02-source/wap7_photoreal_v02/WAP7_detail_v02.blend'
bpy.ops.wm.open_mainfile(filepath=str(SOURCE), load_ui=False, use_scripts=False)
dg = bpy.context.evaluated_depsgraph_get()
records, triangles = [], 0
for ob in bpy.data.objects:
    if ob.type not in {'MESH', 'CURVE', 'FONT', 'EMPTY'}:
        continue
    item = dict(name=ob.name, type=ob.type, parent=ob.parent.name if ob.parent else None,
                hidden_render=ob.hide_render, hidden_viewport=ob.hide_viewport,
                visible=ob.visible_get(), matrix=[list(row) for row in ob.matrix_world],
                collections=[c.name for c in ob.users_collection],
                custom={k:str(v) for k,v in ob.items() if k != '_RNA_UI'})
    if ob.type != 'EMPTY':
        ev = ob.evaluated_get(dg)
        mesh = ev.to_mesh(preserve_all_data_layers=True, depsgraph=dg)
        item['triangles'] = sum(len(p.vertices)-2 for p in mesh.polygons)
        item['uvs'] = [uv.name for uv in mesh.uv_layers]
        item['materials'] = [m.name if m else None for m in mesh.materials]
        if not ob.hide_render:
            triangles += item['triangles']
        ev.to_mesh_clear()
    records.append(item)
materials = []
for mat in bpy.data.materials:
    nodes = []
    for n in mat.node_tree.nodes if mat.use_nodes else []:
        values = {}
        for inp in n.inputs:
            if inp.is_linked or not hasattr(inp, 'default_value'):
                continue
            value = inp.default_value
            if isinstance(value, (str,int,float,bool)):
                values[inp.name] = value
            elif hasattr(value, '__iter__'):
                values[inp.name] = list(value)
        nodes.append(dict(name=n.name,type=n.bl_idname,inputs=values,
                          image=n.image.filepath if n.type == 'TEX_IMAGE' and n.image else None,
                          uv_map=n.uv_map if n.type == 'UVMAP' else None,
                          operation=getattr(n,'operation',None)))
    materials.append(dict(name=mat.name,nodes=nodes,links=[
        [l.from_node.name,l.from_socket.name,l.to_node.name,l.to_socket.name]
        for l in mat.node_tree.links] if mat.use_nodes else []))
result = dict(objects=records,materials=materials,images=[dict(name=i.name,path=i.filepath,
    size=list(i.size),space=i.colorspace_settings.name,packed=bool(i.packed_file))
    for i in bpy.data.images],collections=[dict(name=c.name,hide_render=c.hide_render)
    for c in bpy.data.collections],visible_triangles=triangles)
out=ROOT/'.local/wap7-v02-inspection.json'
out.write_text(json.dumps(result,indent=2))
print('WAP7 INSPECTION', len(records), 'objects;',triangles,'unhidden triangles;',len(materials),'materials',flush=True)
print('VISIBLE GROUPS',dict(Counter(r['parent'] for r in records if r['type']!='EMPTY' and not r['hidden_render'])),flush=True)
