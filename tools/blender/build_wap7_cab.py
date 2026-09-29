"""WAP-7 cab, original reference-based geometry, background Blender only.

Uses the exterior's batched mesh helpers. Front is +Y, rail top is Z=0.
Exports a reusable cab at the actual locomotive coordinates, plus a master that
contains the exterior and both driving interiors. No photo textures are used.
"""
import bpy
import math
import os
import sys
from mathutils import Vector, Matrix
sys.path.insert(0, os.path.dirname(__file__))
import build_wap7 as b

P=b.P
OUT=os.path.join(P,'art','wap7')
CAB_FILE=os.path.join(OUT,'wap7_cab.blend')
GLB=os.path.join(P,'assets','models','wap7_cab.glb')


def label(content,p,size=.026,material='Letter',parent=None,facing='REAR'):
    return b.text('Engraving_'+content.replace('\n','_'),content,p,size,material,facing,parent)


def panel_text(content,x,v,size=.025,material='Letter'):
    # Slanted panel: text X right, local Y rises toward the windscreen.
    ob=label(content,(x,8.45+v*.6-.055,2.22+v*.8+.04125),size,material)
    ob.rotation_euler=Matrix(((1,0,0),(0,.6,.8),(0,-.8,.6))).transposed().to_euler()
    return ob


def shell():
    p=b.Parts('Cab_lining_floor_and_bulkhead',b.ROOT)
    p.box((0,7.93,1.61),(2.98,2.35,.09),'Floor')
    for x in [i*.042 for i in range(-34,35)]:
        p.box((x,7.84,1.661),(.013,2.06,.005),'Tread')
    for s in [-1,1]:
        p.box((s*1.47,7.95,2.15),(.09,2.36,1.0),'Lining')
        # Tile the side lining around two actual apertures, with no open seams.
        ys=[6.82,7.405,7.895,8.205,8.895,9.08]
        zs=[2.65,2.695,2.88,3.48,3.605,3.80]
        for ya,yb in zip(ys,ys[1:]):
            for za,zb in zip(zs,zs[1:]):
                cy=(ya+yb)/2; cz=(za+zb)/2
                if (7.405<cy<7.895 and 2.88<cz<3.48) or (8.205<cy<8.895 and 2.695<cz<3.605):
                    continue
                p.box((s*1.46,cy,cz),(.12,yb-ya,zb-za),'Lining')
        p.box((s*1.38,8.985,3.2),(.21,.23,1.12),'Lining')
        for y,w,z0,z1 in [(7.65,.49,2.88,3.48),(8.55,.69,2.695,3.605)]:
            for z in [z0,z1]:
                p.box((s*1.403,y,z),(.045,w,.025),'Steel')
            p.box((s*1.407,y,(z0+z1)/2),(.029,.025,z1-z0),'Steel')
            p.box((s*1.373,y+.21,2.99),(.035,.105,.028),'Steel')
        p.tube([(s*1.35,7.36,1.88),(s*1.35,7.36,2.53)],.018,'Steel')
        p.box((s*1.40,7.64,2.38),(.044,.17,.036),'SteelDark')
    p.box((0,6.86,2.71),(3.00,.085,2.17),'Lining')
    p.box((0,6.915,2.60),(.76,.04,1.92),'Seam')
    p.box((0,6.947,2.60),(.70,.035,1.85),'Door')
    p.box((0,6.975,3.05),(.42,.015,.47),'Rubber')
    p.box((0,6.987,3.05),(.355,.016,.405),'DarkGlass')
    p.tube([(.22,7.02,2.60),(.31,7.02,2.60),(.31,6.98,2.60)],.018,'Steel')
    for z in [1.95,3.28]:
        p.box((-.34,6.99,z),(.055,.045,.14),'Steel')
    p.box((0,7.9,3.80),(2.92,2.35,.10),'Headliner')
    for y in [7.2,7.8,8.4]:
        p.box((0,y,3.742),(2.88,.014,.012),'Seam')
    # Front inner surround has real open apertures, not opaque window planes.
    p.box((0,9.01,3.75),(2.86,.10,.17),'Lining')
    p.box((0,9.17,2.65),(2.85,.09,.14),'Lining')
    p.box((0,9.10,2.14),(2.85,.13,1.04),'Lining')
    p.box((0,8.94,2.595),(2.85,.53,.09),'Desk')
    p.box((0,9.075,3.20),(.115,.10,1.10),'Lining')
    for x in [-1.30,1.30]:
        p.box((x,9.035,3.20),(.105,.13,1.06),'Lining')
    for x in [-.67,.67]:
        p.tube(b.rounded_rect(x,3.2,1.12,.99,.10,9.11),.024,'Rubber',10,True)
        p.box((x,8.94,3.65),(1.07,.07,.085),'Visor')
        for dx in [-.43,.43]:
            p.cylinder((x+dx,8.94,3.60),(x+dx,8.94,3.73),.018,'Steel',12)
    p.finish(.008)
    label('MACHINE ROOM',(0,6.973,2.74),.051,'Letter',facing='FRONT')
    label('KEEP DOOR CLOSED',(0,6.975,2.40),.030,'Letter',facing='FRONT')
    label('DRIVING CAB',(0,9.005,3.72),.035,'Ink')


def dial(name,center,r,maximum,unit,face='Dial',needle=True):
    # Local X/Y is the dial face, local Z points toward the driver.
    root=b.empty(name+'_Housing',b.ROOT)
    root.location=center
    root.rotation_euler=(math.pi/2,0,0)
    p=b.Parts(name+'_Face',root)
    p.cylinder((0,0,-.027),(0,0,.012),r+.014,'Steel',64)
    p.cylinder((0,0,.013),(0,0,.018),r,'Rubber',64)
    p.cylinder((0,0,.019),(0,0,.021),r-.010,face,64)
    for i in range(41):
        a=math.radians(225-i/40*270)
        r0=r*(.72 if i%5==0 else .80)
        p.cylinder((r0*math.cos(a),r0*math.sin(a),.025),
                   (r*.91*math.cos(a),r*.91*math.sin(a),.025),.002 if i%5 else .0035,'Ink' if face=='GaugeWhite' else 'Letter',6)
    p.finish()
    for i in range(9):
        a=math.radians(225-i/8*270)
        ob=label(str(round(i/8*maximum)),(r*.60*math.cos(a),r*.60*math.sin(a),.027),r*.18,
                 'Ink' if face=='GaugeWhite' else 'Letter',root)
        ob.rotation_euler=(0,0,0)
    ob=label(unit,(0,-r*.38,.028),r*.14,'Ink' if face=='GaugeWhite' else 'Letter',root)
    ob.rotation_euler=(0,0,0)
    if needle:
        pivot=b.empty(name,root)
        pivot.rotation_euler.z=math.radians(225)
        p=b.Parts(name+'_Hand',pivot)
        p.mesh([(-r*.18,-.008,.034),(r*.76,-.003,.034),(r*.85,0,.034),(r*.76,.003,.034),(-r*.18,.008,.034)],[(0,1,2,3,4)],'Needle')
        p.cylinder((0,0,.029),(0,0,.042),r*.09,'SteelDark',24)
        p.finish()
    return root


def desk():
    p=b.Parts('Wraparound_driving_desk',b.ROOT)
    p.box((0,8.62,2.12),(2.82,.96,.22),'Desk')
    # Side pedestals leave a proper knee recess in front of the driver's seat.
    for x in [-1.22,1.21]:
        p.box((x,8.46,1.86),(.37,.76,.44),'Desk')
    p.box((.36,8.46,1.91),(.38,.79,.50),'Desk')
    p.box((0,8.17,2.11),(2.79,.04,.16),'Edge')
    slope=Matrix.Rotation(math.radians(-36.87),3,'X')
    # Local Y lies on the sloped panel, +Z toward driver/up.
    slope=Matrix(((1,0,0),(0,.6,.8),(0,-.8,.6))).transposed()
    p.box((0,8.60,2.42),(2.72,.49,.075),'Desk',slope)
    for x,w in [(-1.02,.55),(-.37,.66),(.42,.78),(1.13,.45)]:
        p.box((x,8.579,2.436),(w,.435,.028),'Panel',slope)
        for xx in [x-w/2+.025,x+w/2-.025]:
            for v in [.017,.401]:
                yy=8.45+v*.6-.035; zz=2.22+v*.8+.02625
                p.cylinder((xx,yy-.015,zz+.006),(xx,yy-.023,zz+.012),.008,'Steel',8)
    # Speed recorder stands on the shelf below the central windscreen post.
    p.box((-.07,8.85,2.93),(.34,.18,.57),'Recorder')
    p.box((-.07,8.743,2.93),(.294,.022,.522),'Panel')
    p.box((-.07,8.72,2.795),(.205,.018,.061),'Screen')
    for i in range(6):
        p.box((-.173+i*.041,8.714,2.74),(.028,.016,.025),'Yellow')
    for i in range(15):
        p.box((-.20+i*.019,8.85,3.228),(.007,.13,.010),'SteelDark')
    p.finish(.014)
    dial('NeedleSpeed',(-.07,8.718,3.016),.112,160,'km/h','GaugeWhite')
    dial('NeedlePower',(-1.01,8.506,2.51),.080,100,'POWER %')
    dial('NeedleBrake',(-1.01,8.40,2.35),.080,100,'BRAKE %')
    panel_text('TRACTION / BRAKE',-1.01,.025,.019)
    panel_text('WAP-7  /  30306',.4,.378,.025)
    # Original DDU with geometry bezel and an independent screen anchor.
    p=b.Parts('Driver_display_and_switchgear',b.ROOT)
    p.box((.39,8.508,2.455),(.57,.328,.038),'Black',slope)
    p.box((.39,8.484,2.473),(.469,.236,.012),'Screen',slope)
    for x in [.09,.69]:
        for v in [.087,.157,.227,.297]:
            yy=8.45+v*.6-.060; zz=2.22+v*.8+.045
            p.box((x,yy-.021,zz+.014),(.028,.026,.014),'Switch',slope)
    # Bank of annunciators and toggles.
    for j,ma in enumerate(['Green','Amber','Amber','Red']):
        x=-.66+j*.145; v=.307
        yy=8.45+v*.6-.035; zz=2.22+v*.8+.02625
        p.cylinder((x,yy,zz),(x,yy-.025,zz+.018),.033,'SteelDark',24)
        lamp=b.Parts(['PowerLamp','CoastLamp','BrakeLamp','EmergencyLamp'][j],b.ROOT)
        lamp.cylinder((x,yy-.027,zz+.019),(x,yy-.031,zz+.022),.025,ma,24)
        lamp.finish()
        panel_text(['POWER','COAST','BRAKE','EMERG'][j],x,.23,.019)
    for x in [-.68,-.52,-.36,-.20,.99,1.13,1.27]:
        for v in [.05,.13]:
            yy=8.45+v*.6-.035; zz=2.22+v*.8+.02625
            p.cylinder((x,yy-.012,zz+.010),(x,yy-.032,zz+.025),.019,'Steel',16)
            p.cylinder((x,yy-.032,zz+.025),(x,yy-.047,zz+.078),.007,'Switch',10)
    for x in [.98,1.12,1.26]:
        panel_text('AUX',x,.0,.019)
    panel_text('LIGHTS   WIPER   FAN',-.40,-.01,.020)
    # Emergency mushroom, radio, microphone, and clipboard.
    p.cylinder((.91,8.20,2.245),(.91,8.20,2.29),.080,'Yellow',40)
    p.cylinder((.91,8.20,2.29),(.91,8.20,2.35),.051,'Red',32)
    p.box((1.15,8.68,2.72),(.32,.13,.17),'Black')
    p.box((1.15,8.603,2.74),(.21,.008,.055),'Screen')
    p.cylinder((1.255,8.59,2.67),(1.255,8.57,2.67),.021,'Steel',24)
    p.box((1.38,8.37,2.31),(.088,.16,.078),'Black')
    p.tube([(1.36,8.47,2.3),(1.37,8.54,2.45),(1.40,8.65,2.57),(1.31,8.66,2.64)],.009,'Rubber',8)
    p.box((.10,8.22,2.246),(.24,.34,.014),'Board')
    p.box((.10,8.22,2.256),(.212,.303,.003),'Paper')
    p.box((.10,8.366,2.266),(.11,.018,.013),'Steel')
    for k in range(8):
        p.box((.10,8.30-k*.027,2.259),(.16,.003,.001),'Ink')
    p.finish(.005)
    anchor=b.empty('DDUScreen',b.ROOT)
    anchor.location=(.39,8.472,2.485)
    anchor.rotation_euler=slope.to_euler()
    digital=b.empty('DigitalSpeed',b.ROOT)
    digital.location=(-.07,8.707,2.795)
    digital.rotation_euler=(math.pi/2,0,0)
    # Controller and independent brake handles use real local pivots.
    for name,x,ma in [('ControllerPivot',-.61,'Switch'),('BrakeHandle',-1.17,'SteelDark')]:
        base=b.Parts(name+'_Base',b.ROOT)
        base.cylinder((x,8.23,2.24),(x,8.23,2.29),.082,'Rubber',40)
        base.ring((x,8.23,2.292),.074,.009,'Steel','Z')
        base.finish()
        pivot=b.empty(name,b.ROOT); pivot.location=(x,8.23,2.29)
        p=b.Parts(name+'_Lever',pivot)
        p.cylinder((0,0,0),(0,.07,.12),.014,'Steel',16)
        p.box((0,.088,.14),(.11,.062,.065),ma)
        p.finish(.018)
    label('SPEED RECORDER',(-.07,8.709,2.856),.018,'Letter')
    # Small decals lie flat on the console ledge.
    for content,x in [('TRACTION',-.61),('BRAKE',-1.17),('EMERGENCY',.91)]:
        ob=label(content,(x,8.10,2.242),.027,'Ink'); ob.rotation_euler=(0,0,0)


def furniture():
    p=b.Parts('Seats_pedals_fans_and_cab_equipment',b.ROOT)
    for x in [-.68,1.0]:
        p.cylinder((x,7.61,1.67),(x,7.61,1.77),.235,'SteelDark',40)
        p.cylinder((x,7.61,1.77),(x,7.61,1.97),.065,'Steel',24)
        for part,center,size in [('Cushion',(x,7.62,2.005),(.55,.51,.17)),
                                 ('Backrest',(x,7.35,2.36),(.56,.14,.68)),
                                 ('Headrest',(x,7.36,2.77),(.39,.16,.18))]:
            pad=b.Parts('Seat_%s_%s'%(x,part),b.ROOT)
            pad.box(center,size,'Seat')
            ob=pad.finish(.058)
            ob.modifiers[0].segments=6
            for polygon in ob.data.polygons: polygon.use_smooth=True
        for xx in [x-.22,x+.22]:
            p.tube([(xx,7.875,2.03),(xx,7.385,2.075),(xx,7.434,2.64)],.002,'Stitch')
        for xx in [x-.31,x+.31]:
            p.cylinder((xx,7.43,1.99),(xx,7.43,2.28),.018,'Steel')
            p.box((xx,7.64,2.30),(.08,.43,.065),'Rubber')
    p.box((-.69,8.40,1.68),(.23,.29,.065),'SteelDark')
    for x in [-.77,-.73,-.69,-.65,-.61]:
        p.box((x,8.40,1.718),(.01,.25,.008),'Steel')
    for x in [-1.19,1.19]:
        p.cylinder((x,8.79,3.72),(x,8.79,3.47),.023,'Desk',16)
        p.cylinder((x,8.81,3.47),(x,8.66,3.47),.065,'SteelDark',24)
        for radius in [.07,.12,.17,.215]:
            p.ring((x,8.61,3.47),radius,.004,'Steel','Y',48)
        for j in range(16):
            a=math.tau*j/16
            p.cylinder((x,8.61,3.47),(x+.217*math.cos(a),8.61,3.47+.217*math.sin(a)),.003,'Steel',6)
        p.ring((x,8.66,3.47),.222,.010,'SteelDark','Y',48)
        for j in range(3):
            a=math.tau*j/3
            p.box((x+.10*math.cos(a),8.645,3.47+.1*math.sin(a)),(.175,.015,.070),'Fan',Matrix.Rotation(-a,3,'Y'))
    p.box((0,7.73,3.708),(.24,.76,.055),'Steel')
    p.box((0,7.73,3.675),(.18,.69,.025),'Light')
    p.box((-1.07,6.97,2.69),(.66,.15,1.60),'Desk')
    for z in [2.16,2.67,3.18]:
        p.box((-1.07,7.053,z),(.61,.025,.45),'Panel')
        for x in [-1.27,-1.08,-.89]:
            p.box((x,7.080,z+.045),(.08,.023,.11),'Switch')
            p.box((x,7.095,z+.05),(.028,.010,.040),'Letter')
    p.cylinder((1.10,7.06,1.80),(1.10,7.06,2.40),.10,'Red',40)
    p.cylinder((1.10,7.06,2.40),(1.10,7.06,2.45),.062,'Steel',24)
    p.box((1.10,7.06,2.48),(.16,.058,.045),'Black')
    p.box((1.10,7.163,2.1),(.13,.010,.23),'Paper')
    p.tube([(1.14,7.06,2.47),(1.29,7.06,2.35),(1.28,7.12,1.83)],.012,'Rubber')
    p.box((.67,6.966,3.26),(.32,.035,.37),'Paper')
    p.box((-.52,7.55,1.70),(.25,.37,.14),'SteelDark')
    p.finish(.020)
    label('ABC',(1.10,7.176,2.10),.040,'Red',facing='FRONT')
    label('SAFETY FIRST\nCHECK SIGNAL\nBEFORE START',(.67,6.989,3.26),.028,'Ink',facing='FRONT')
    label('AUXILIARY CIRCUITS',(-1.07,7.085,3.44),.030,'Letter',facing='FRONT')


def studio():
    sc=bpy.context.scene
    sc.world=bpy.data.worlds.new('Cab daylight'); sc.world.use_nodes=True
    sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.48,.60,.74,1)
    sc.world.node_tree.nodes['Background'].inputs[1].default_value=.5
    for name,loc,power,size in [('Window light',(0,12,5),650,5),('Side light',(-4,8,4),350,4),('Cab bounce',(0,7.7,3.5),55,1.2)]:
        d=bpy.data.lights.new(name,'AREA'); d.energy=power; d.size=size
        ob=bpy.data.objects.new(name,d); sc.collection.objects.link(ob); ob.location=loc
        ob.rotation_euler=(Vector((0,8.5,2.2))-ob.location).to_track_quat('-Z','Y').to_euler()
    for name,loc,target,lens in [('Cab_Driver',(-.68,7.62,2.98),(-.35,9.4,2.53),17),
                                ('Cab_Overview',(1.18,7.0,3.35),(-.28,8.52,2.33),22),
                                ('Cab_Rear',(-1.10,8.38,3.05),(0,6.9,2.64),21)]:
        d=bpy.data.cameras.new(name); d.lens=lens
        ob=bpy.data.objects.new(name,d); sc.collection.objects.link(ob); ob.location=loc
        ob.rotation_euler=(Vector(target)-ob.location).to_track_quat('-Z','Y').to_euler()
    sc.camera=bpy.data.objects['Cab_Driver']; sc.render.engine='CYCLES'
    sc.cycles.samples=40; sc.cycles.use_denoising=True
    sc.render.resolution_x=1600; sc.render.resolution_y=1000; sc.render.resolution_percentage=100
    sc.view_settings.view_transform='AgX'


def main():
    if not bpy.app.background:
        raise RuntimeError('Run only in background Blender.')
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob,do_unlink=True)
    b.ASSET=bpy.data.collections.new('WAP7_DrivingInterior')
    bpy.context.scene.collection.children.link(b.ASSET)
    b.ROOT=b.empty('WAP7Cab'); b.ROOT['eye_blender_m']=[-.68,7.62,2.98]
    b.FONT=bpy.data.fonts.load('C:/Windows/Fonts/bahnschrift.ttf')
    for name,col,rough,metal in [
        ('Lining',(.62,.61,.54),.70,0),('Headliner',(.66,.64,.58),.8,0),
        ('Desk',(.36,.39,.38),.56,.15),('Door',(.38,.42,.40),.6,.15),
        ('Panel',(.055,.072,.076),.50,.3),('Floor',(.050,.062,.066),.8,0),
        ('Tread',(.095,.11,.11),.8,0),('Rubber',(.009,.012,.011),.8,0),
        ('Black',(.012,.016,.018),.6,.1),('SteelDark',(.15,.18,.18),.40,.6),
        ('Steel',(.47,.51,.50),.27,.8),('Seam',(.18,.20,.18),.7,.1),
        ('DarkGlass',(.025,.046,.044),.15,.5),('Visor',(.08,.11,.10),.8,0),
        ('Edge',(.24,.28,.27),.52,.3),('Recorder',(.24,.27,.25),.48,.25),
        ('GaugeWhite',(.68,.80,.57),.5,0),('Dial',(.013,.027,.03),.57,.1),
        ('Screen',(.009,.035,.041),.34,.1),('Switch',(.045,.055,.052),.42,.1),
        ('Letter',(.84,.86,.78),.48,0),('Ink',(.018,.027,.024),.5,0),
        ('Needle',(.98,.23,.04),.39,.1),('Yellow',(.91,.59,.035),.45,0),
        ('Red',(.61,.03,.02),.38,.1),('Green',(.035,.65,.22),.38,0),
        ('Amber',(.95,.48,.025),.38,0),('Board',(.18,.075,.028),.8,0),
        ('Paper',(.78,.76,.63),.9,0),('Seat',(.028,.069,.105),.84,0),
        ('Stitch',(.18,.23,.26),.85,0),('Fan',(.10,.14,.13),.55,.3),
    ]:
        b.mat(name,col,rough,metal)
    b.mat('Light',(.88,.84,.69),.5,0,1.2)
    shell(); desk(); furniture()
    bpy.ops.object.select_all(action='DESELECT')
    for ob in b.ASSET.objects: ob.select_set(True)
    bpy.context.view_layer.objects.active=b.ROOT
    bpy.ops.export_scene.gltf(filepath=GLB,export_format='GLB',use_selection=True,export_apply=True,export_extras=True)
    studio()
    bpy.ops.wm.save_as_mainfile(filepath=CAB_FILE,compress=True)
    if '--render' in sys.argv:
        for camera,filename in [('Cab_Driver','cab_driver.png'),('Cab_Overview','cab_overview.png'),('Cab_Rear','cab_rear.png')]:
            bpy.context.scene.camera=bpy.data.objects[camera]
            bpy.context.scene.render.filepath=os.path.join(OUT,filename)
            bpy.ops.render.render(write_still=True)
    # Full editable locomotive with BOTH interiors; original exterior is preserved.
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUT,'wap7_30306.blend'))
    with bpy.data.libraries.load(CAB_FILE,link=False) as (src,dst):
        dst.collections=['WAP7_DrivingInterior']
    col=dst.collections[0]; bpy.context.scene.collection.children.link(col)
    first=next(ob for ob in col.objects if ob.name.startswith('WAP7Cab'))
    first.name='DrivingInterior_Cab1'
    mapping={}
    other=bpy.data.collections.new('WAP7_DrivingInterior_Cab2'); bpy.context.scene.collection.children.link(other)
    for ob in col.objects:
        copy=ob.copy(); other.objects.link(copy); mapping[ob]=copy
    for ob,copy in mapping.items():
        if ob.parent in mapping: copy.parent=mapping[ob.parent]
    mapping[first].name='DrivingInterior_Cab2'; mapping[first].rotation_euler.z=math.pi
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'wap7_30306_full.blend'),compress=True)
    print('WAP7_CAB_COMPLETE',GLB,flush=True)


if __name__=='__main__':
    main()
