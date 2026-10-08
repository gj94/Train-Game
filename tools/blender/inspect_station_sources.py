"""Background-only inventory of the pinned scene. Does not execute its scripts."""
import bpy
import json
import sys
from pathlib import Path
from mathutils import Vector

root=Path(__file__).resolve().parents[2]
code=sys.argv[sys.argv.index('--')+1].lower()
source=root/'.local/station-v02-source/south_indian_stations_v02'/code/(code.upper()+'_full_station_v02.blend')
bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False,use_scripts=False)
result={'station':code,'objects':len(bpy.data.objects),'collections':[], 'materials':[], 'images':[]}
for collection in bpy.data.collections:
    objects=[o for o in collection.objects if o.type in ('MESH','FONT','CURVE')]
    bounds=[]
    for obj in objects:
        bounds.extend(obj.matrix_world@Vector(p) for p in obj.bound_box)
    result['collections'].append({'name':collection.name,'objects':len(objects),
        'vertices':sum(len(o.data.vertices) for o in objects if o.type=='MESH'),
        'hidden':collection.hide_render,
        'min':[min(p[a] for p in bounds) for a in range(3)] if bounds else [],
        'max':[max(p[a] for p in bounds) for a in range(3)] if bounds else [],
        'examples':[o.name for o in objects[:8]]})
for m in bpy.data.materials:
    result['materials'].append({'name':m.name,'nodes':sorted(set(n.bl_idname for n in m.node_tree.nodes)) if m.use_nodes else [], 'colour':list(m.diffuse_color)})
for im in bpy.data.images:
    result['images'].append({'name':im.name,'size':list(im.size),'packed':bool(im.packed_file),'path':im.filepath})
(root/'.local'/('station-'+code+'-inventory.json')).write_text(json.dumps(result,indent=2),encoding='utf-8')
print(code, 'inventory saved',len(bpy.data.objects),'objects')
