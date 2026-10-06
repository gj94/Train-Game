import bpy, json
from pathlib import Path
root=Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(root/'.local/polyhaven-tree/tree_small_02_1k.blend'))
for obj in bpy.data.objects:
    print('TREE_OBJECT',obj.name,obj.type,'hidden',obj.hide_viewport,obj.hide_render,'location',list(obj.location),'dimensions',list(obj.dimensions),'verts',len(obj.data.vertices) if obj.type=='MESH' else None,'polys',len(obj.data.polygons) if obj.type=='MESH' else None)
    for mod in obj.modifiers:
        print('MODIFIER',mod.name,mod.type,flush=True)
        if mod.type=='NODES' and mod.node_group:
            for socket in mod.node_group.interface.items_tree:
                if socket.item_type=='SOCKET' and socket.in_out=='INPUT':
                    try: value=mod[socket.identifier]
                    except Exception: value=getattr(socket,'default_value',None)
                    print('INPUT',socket.name,socket.identifier,str(value),flush=True)
for collection in bpy.data.collections:
    print('COLLECTION',collection.name,'hidden',collection.hide_viewport,collection.hide_render)
for mat in bpy.data.materials:
    print('MATERIAL',mat.name,[(n.type,n.name) for n in mat.node_tree.nodes] if mat.use_nodes else [])
