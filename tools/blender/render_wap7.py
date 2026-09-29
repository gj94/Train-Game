"""Inspect the saved WAP-7 or its actual GLB round trip in background Blender.

blender -b --factory-startup --python tools/blender/render_wap7.py -- hero front bogie roof side
Add --roundtrip to replace the source assemblies with the exported GLB.
"""
import bpy
import json
import os
import sys

P=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT=os.path.join(P,'art','wap7')
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['hero']
bpy.ops.wm.open_mainfile(filepath=os.path.join(OUT,'wap7_30306.blend'))
roundtrip='--roundtrip' in args
if roundtrip:
    for ob in list(bpy.data.collections['WAP-7 • locomotive assemblies'].objects):
        bpy.data.objects.remove(ob,do_unlink=True)
    before=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(P,'assets','models','wap7.glb'))
    imported=set(bpy.data.objects)-before
    meshes=[ob for ob in imported if ob.type=='MESH']
    bounds=[ob.matrix_world @ v.co for ob in meshes for v in ob.data.vertices]
    stats={
        'imported_meshes':len(meshes),
        'bounds_min':[min(v[a] for v in bounds) for a in range(3)],
        'bounds_max':[max(v[a] for v in bounds) for a in range(3)],
        'wheelsets':sorted(ob.name for ob in meshes if ob.name.startswith('Wheelset_')),
        'all_materials_backface_culled':all(m.use_backface_culling for ob in meshes for m in ob.data.materials),
    }
    assert len(stats['wheelsets'])==6, stats
    assert 20.4 < stats['bounds_max'][1]-stats['bounds_min'][1] < 20.8, stats
    assert 3.1 < stats['bounds_max'][0]-stats['bounds_min'][0] < 3.9, stats
    assert stats['all_materials_backface_culled'], stats
    with open(os.path.join(OUT,'export-validation.json'),'w') as f:
        json.dump(stats,f,indent=2)
    print('ROUNDTRIP_VALIDATED',stats,flush=True)
sc=bpy.context.scene
views={'hero':'01_Hero','front':'02_Front','bogie':'03_Bogie','roof':'04_Roof','side':'05_Side'}
for view in args:
    if view not in views:
        continue
    sc.camera=bpy.data.objects[views[view]]
    sc.render.filepath=os.path.join(OUT,view+('_glb' if roundtrip else '')+'.png')
    bpy.ops.render.render(write_still=True)
