"""Original LHB luggage/brake/generator van for the full-length AC rake.
Uses the same articulated FIAT bogies and couplings as the passenger vehicles.
Exterior only: the generator compartment is not a passenger camera location.
"""
import os, sys, math
import bpy
sys.path.insert(0,os.path.dirname(__file__))
import build_lhb as l
import build_wap7 as b

def build():
    if not bpy.app.background: raise RuntimeError('Background Blender only')
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    b.M={}; b.GROUPS=[]
    b.ASSET=bpy.data.collections.new('LHB_EOG'); bpy.context.scene.collection.children.link(b.ASSET)
    b.ROOT=b.empty('LHB_EOG'); b.FONT=bpy.data.fonts.load('C:/Windows/Fonts/bahnschrift.ttf')
    l.palette()
    p=b.Parts('EOG_body_and_roof',b.ROOT)
    p.box((0,0,2.48),(3.24,23.54,2.45),'Grey')
    p.box((0,0,1.20),(3.1,23.54,.18),'Under')
    for s in [-1,1]:
        p.box((s*1.625,0,3.49),(.016,23.5,.21),'Red')
        p.box((s*1.625,0,2.02),(.016,23.5,.15),'Blue')
    # Curved roof profile, with recessed-looking radiator/exhaust panels.
    vs=[]
    for y in [-11.77,11.77]:
        for i in range(25):
            t=i*math.pi/24
            vs.append((1.62*math.cos(t),y,3.705+.42*math.sin(t)))
    p.mesh(vs,[(i,i+1,i+26,i+25) for i in range(24)],'Roof',True)
    p.mesh(vs,[tuple(reversed(range(25))),tuple(range(25,50))],'Roof')
    p.finish(.018)
    p=b.Parts('EOG_radiators_louvres_and_doors',b.ROOT)
    for s in [-1,1]:
        for y in [-7.0,-3.9,1.4,4.6]:
            p.box((s*1.645,y,2.63),(.04,2.25,1.75),'Dark')
            for i in range(29): p.box((s*1.676,y,1.8+i*.059),(.025,2.19,.022),'Steel')
            for dy in [-1.16,1.16]: p.box((s*1.678,y+dy,2.63),(.035,.055,1.84),'Steel')
        for y in [-.85,9.6]:
            p.box((s*1.649,y,2.34),(.044,1.13,2.04),'Grey')
            p.box((s*1.677,y,2.84),(.02,.7,.66),'Glass')
            p.box((s*1.688,y+.37,2.08),(.025,.04,.26),'Steel')
            for yy in [y-.64,y+.64]:
                p.cylinder((s*1.72,yy,1.58),(s*1.72,yy,2.77),.022,'Steel',12)
            for h in [.63,.86,1.08]: p.box((s*1.48,y,h),(.42,1.2,.07),'Steel')
        # Luggage shutter and guard's windows at the rear section.
        p.box((s*1.652,7.35,2.4),(.038,1.7,2.1),'Dark')
        for i in range(28): p.box((s*1.68,7.35,1.4+i*.072),(.025,1.67,.04),'Grey')
        p.box((s*1.65,-9.8,2.75),(.025,1.02,.73),'Glass')
        for yy in [-10.2,-10,-9.8,-9.6,-9.4]: p.box((s*1.70,yy,2.75),(.025,.024,.78),'Steel')
        l.label('EOG_class','LUGGAGE BRAKE & GENERATOR CAR',(s*1.653,0,3.43),.112,'Yellow','RIGHT' if s>0 else 'LEFT')
        l.label('EOG_number','SR  192002  /  LWLRRM',(s*1.653,-8.9,1.72),.082,'Letter','RIGHT' if s>0 else 'LEFT')
        l.label('EOG_warning','DANGER  750 V',(s*1.691,7.35,2.8),.082,'Yellow','RIGHT' if s>0 else 'LEFT')
    for y in [-6,-2,2,6]:
        p.box((0,y,4.12),(1.3,1.4,.07),'Dark')
        for i in range(14): p.box((0,y-.63+i*.095,4.16),(1.25,.027,.028),'Steel')
        p.cylinder((.5,y,4.1),(.5,y,4.34),.10,'Bogie',16)
    p.finish(.008)
    l.bogie(1,7.45); l.bogie(2,-7.45); l.ends(); l.equipment()
    ob=bpy.data.objects.get('Roof_RMPU_and_service_panels')
    if ob: bpy.data.objects.remove(ob,do_unlink=True)
    b.ROOT['length_over_couplers_m']=24.0; b.ROOT['body_length_m']=23.54
    bpy.ops.object.select_all(action='DESELECT')
    for ob in b.ASSET.objects: ob.select_set(True)
    bpy.context.view_layer.objects.active=b.ROOT
    bpy.ops.export_scene.gltf(filepath=os.path.join(l.MODELS,'lhb_eog.glb'),export_format='GLB',use_selection=True,export_apply=True,export_extras=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(l.OUT,'lhb_eog.blend'),compress=True)
    print('EOG_COMPLETE',flush=True)

if __name__=='__main__': build()
