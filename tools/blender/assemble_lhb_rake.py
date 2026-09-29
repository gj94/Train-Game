"""Build the complete editable WAP-7 + six-coach presentation master.

Native meshes are shared by duplicate coaches; each coach keeps its own parents
and berth/axle pivots. Run after both builders, always in background Blender.
"""
import bpy, os, sys, math
from mathutils import Vector
sys.path.insert(0,os.path.dirname(__file__))
import build_lhb as l
if not bpy.app.background: raise RuntimeError('Background Blender only.')
bpy.ops.wm.open_mainfile(filepath=os.path.join(l.P,'art','wap7','wap7_30306_full.blend'))
for col in list(bpy.data.collections):
    if col.name.startswith('STUDIO'):
        for ob in list(col.objects): bpy.data.objects.remove(ob,do_unlink=True)
        bpy.data.collections.remove(col)
for kind,count,offset in [('3a',4,0),('2a',2,4)]:
    with bpy.data.libraries.load(os.path.join(l.OUT,'lhb_'+kind+'.blend'),link=False) as (src,dst):
        dst.collections=['LHB_'+kind.upper()]
    template=dst.collections[0]
    for index in range(count):
        i=offset+index
        name=('B%d'%(index+1)) if kind=='3a' else ('A%d'%(index+1))
        col=bpy.data.collections.new('Coach_'+name); bpy.context.scene.collection.children.link(col)
        mapping={}
        for ob in template.objects:
            copy=ob.copy(); col.objects.link(copy); mapping[ob]=copy
        for ob,copy in mapping.items():
            if ob.parent in mapping: copy.parent=mapping[ob.parent]
            else: copy.location.y-=10.281+12+i*24
            copy.name=name+'_'+ob.name
            if ob.name.startswith('TailMarker_'):
                copy.hide_render=not (i==5 and ob.name=='TailMarker_-1')
                copy.hide_set(copy.hide_render)
            if ob.name in ['LastVehicleBoard','LastVehicleLetters']:
                copy.hide_render=i!=5; copy.hide_set(i!=5)
        root=next(copy for ob,copy in mapping.items() if ob.parent is None)
        root['formation_code']=name
    for ob in list(template.objects): bpy.data.objects.remove(ob,do_unlink=True)
    bpy.data.collections.remove(template)
sc=bpy.context.scene
studio=bpy.data.collections.new('STUDIO_Rake'); sc.collection.children.link(studio)
for name,loc,target,lens in [('Rake_Hero',(-55,32,21),(0,-64,1.9),35),('Coach_Close',(-12,-12,5),(0,-28,2.2),43)]:
    d=bpy.data.cameras.new(name); d.lens=lens; d.clip_end=2000
    ob=bpy.data.objects.new(name,d); studio.objects.link(ob); ob.location=loc
    ob.rotation_euler=(Vector(target)-ob.location).to_track_quat('-Z','Y').to_euler()
sun=bpy.data.lights.new('Daylight','SUN'); sun.energy=2; sun.angle=.12
ob=bpy.data.objects.new('Daylight',sun); studio.objects.link(ob); ob.rotation_euler=(.35,-.4,-.5)
sc.camera=bpy.data.objects['Rake_Hero']
sc.render.resolution_x=1920; sc.render.resolution_y=1080
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.region_3d.view_location=(0,-65,2)
            area.spaces.active.region_3d.view_distance=150
sc['formation']='WAP-7 30306 + B1 B2 B3 B4 A1 A2; 164.562 m over couplers'
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(l.OUT,'wap7_lhb_rake.blend'),compress=True)
print('FULL_LHB_RAKE_SAVED',flush=True)
