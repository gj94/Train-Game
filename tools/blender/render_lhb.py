"""Inspect the saved native master or the exported GLB in background Blender."""
import os, sys
import bpy
sys.path.insert(0,os.path.dirname(__file__))
import build_lhb as l

if not bpy.app.background: raise RuntimeError('Background Blender only.')
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['3a','Hero','Aisle']
kind=args[0]
bpy.ops.wm.open_mainfile(filepath=os.path.join(l.OUT,'lhb_'+kind+'.blend'))
suffix=''
if '--glb' in args:
    col=bpy.data.collections['LHB_'+kind.upper()]
    for ob in list(col.objects): bpy.data.objects.remove(ob,do_unlink=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(l.MODELS,'lhb_'+kind+'.glb'))
    suffix='_glb'
for camera in args[1:]:
    if camera.startswith('--'): continue
    sc=bpy.context.scene; sc.camera=bpy.data.objects[camera]
    sc.render.filepath=os.path.join(l.OUT,kind+'_'+camera.lower()+suffix+'.png')
    bpy.ops.render.render(write_still=True)
