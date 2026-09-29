"""Original LHB 3A/2A coaches; run ONLY in background Blender.

Metres, X across, +Y forward, Z=0 at rail top. Each model includes a complete
interior, articulated FIAT bogies and four axle pivots. No purchased meshes or
photographs are embedded. See docs/lhb.md for references and approximations.
blender -b --factory-startup --python tools/blender/build_lhb.py -- --render
"""
import os, sys, math, json
import bpy
from mathutils import Vector, Matrix
sys.path.insert(0, os.path.dirname(__file__))
import build_wap7 as b

P = b.P
OUT = os.path.join(P, 'art', 'lhb')
MODELS = os.path.join(P, 'assets', 'models')
CENTRES = [-7.92 + i*1.98 for i in range(9)]
HALF = 11.77
Parts = b.Parts


def palette():
    for name,c,r,m in [
        ('Red',(.51,.018,.033),.36,.25), ('Grey',(.44,.46,.45),.57,.32),
        ('Roof',(.48,.50,.49),.6,.45), ('Under',(.055,.067,.067),.67,.5),
        ('Bogie',(.105,.12,.12),.52,.7), ('Steel',(.45,.51,.52),.27,.86),
        ('Tread',(.31,.35,.36),.23,.95), ('Rubber',(.012,.017,.018),.9,0),
        ('Dark',(.019,.027,.030),.64,.15), ('Letter',(.84,.86,.80),.55,0),
        ('Ink',(.023,.043,.063),.65,0), ('Yellow',(.94,.66,.04),.53,.1),
        ('Blue',(.025,.16,.27),.56,0), ('Piping',(.10,.28,.38),.59,0),
        ('Lining',(.67,.68,.60),.8,0), ('Partition',(.54,.59,.54),.72,0),
        ('Floor',(.105,.15,.145),.95,0), ('Curtain',(.024,.12,.16),.94,0),
        ('White',(.82,.84,.77),.65,0), ('Glass',(.10,.19,.22),.14,.15),
        ('Mirror',(.57,.67,.69),.09,.97), ('Brake',(.24,.22,.17),.74,.5),
        ('PipeRed',(.52,.055,.025),.6,.45), ('PipeYellow',(.65,.47,.08),.6,.4),
        ('Ceramic',(.76,.80,.74),.25,0), ('Seam',(.26,.30,.27),.86,0),
    ]:
        mat=b.mat(name,c,r,m); mat.name='LHB_'+name
    for name,col,power in [('Light',(.81,.89,.87),2),('Tail',(.9,.01,.005),2)]:
        mat=b.mat(name,col,.5,0,power); mat.name='LHB_'+name
    # Exported glass is translucent; the game removes it only in the occupied coach.
    glass=b.M['Glass']; glass.surface_render_method='DITHERED'
    for name in ['Glass','Grey','Curtain','Lining']:
        b.M[name].use_backface_culling=False
    glass.node_tree.nodes['Principled BSDF'].inputs['Alpha'].default_value=.25
    glass.diffuse_color=(.10,.19,.22,.25)
    # Subtle material grain in the editable master. glTF uses the matching base colour.
    for name,scale,strength in [('Blue',175,.1),('Floor',115,.18),('Curtain',120,.17)]:
        mat=b.M[name]; nodes=mat.node_tree.nodes
        noise=nodes.new('ShaderNodeTexNoise'); noise.inputs['Scale'].default_value=scale
        bump=nodes.new('ShaderNodeBump'); bump.inputs['Strength'].default_value=strength
        bump.inputs['Distance'].default_value=.006
        mat.node_tree.links.new(noise.outputs['Fac'],bump.inputs['Height'])
        mat.node_tree.links.new(bump.outputs['Normal'],nodes['Principled BSDF'].inputs['Normal'])


def label(name,txt,p,size=.08,mat='Ink',face='RIGHT',parent=None):
    return b.text(name,txt,p,size,mat,face,parent)


def rounded_window(y,s,parent):
    p=Parts('Window_%s_%s'%(s,round(y,2)),parent)
    pts=[]
    # Rounded opening in the YZ plane. A rubber ring, a silver retaining strip,
    # and reveal connect the exterior to the cabin without a solid backing plate.
    for yy,zz,start in [(y+.57,2.89,0),(y-.57,2.89,90),(y-.57,2.21,180),(y+.57,2.21,270)]:
        for i in range(7):
            a=math.radians(start+i*15)
            pts.append((s*1.634,yy+.09*math.cos(a),zz+.09*math.sin(a)))
    p.tube(pts,.037,'Rubber',10,True)
    p.tube([(s*1.643,v[1],v[2]) for v in pts],.009,'Steel',6,True)
    inner=[(s*1.485,v[1],v[2]) for v in pts]
    for i in range(len(pts)):
        j=(i+1)%len(pts)
        p.mesh([pts[i],pts[j],inner[j],inner[i]],[(0,1,2,3)],'Grey')
    for k,(yy,zz) in enumerate([(y+.66,2.98),(y-.66,2.98),(y-.66,2.12),(y+.66,2.12)]):
        corner=[(s*1.477,yy,zz)]+[(s*1.477,v[1],v[2]) for v in pts[k*7:k*7+7]]
        p.mesh(corner,[tuple(range(8))],'Lining')
    p.finish()
    pane=Parts('Glass_%s_%s'%(s,round(y,2)),parent)
    pane.mesh([(s*1.606,v[1],v[2]) for v in pts],[tuple(range(len(pts)))],'Glass')
    pane.finish()


def body(kind):
    p=Parts('Shell_Livery',b.ROOT)
    p.box((0,0,1.225),(3.12,23.54,.19),'Under')
    # Continuous panels above and below the open window belt.
    for s in [-1,1]:
        p.box((s*1.572,0,1.685),(.096,23.54,.73),'Grey')
        p.box((s*1.572,0,2.078),(.096,23.54,.056),'Red')
        p.box((s*1.572,0,3.31),(.096,23.54,.66),'Red')
        bounds=[-9.25]+[v for y in CENTRES for v in (y-.66,y+.66)]+[9.25]
        for a,c in zip(bounds[::2],bounds[1::2]):
            p.box((s*1.572,(a+c)/2,2.542),(.096,c-a,.876),'Red')
        for sg in [-1,1]:
            # End portions with recessed passenger door in between.
            p.box((s*1.572,sg*9.62,2.54),(.096,.74,.88),'Red')
            p.box((s*1.572,sg*11.30,2.54),(.096,.94,.88),'Red')
        for y in CENTRES: rounded_window(y,s,b.ROOT)
    # Full curved roof, with a flat interior ceiling below it.
    profile=[]
    for i in range(33):
        a=math.pi*i/32
        profile.append((1.62*math.cos(a),3.62+.63*math.sin(a)))
    for i in range(32):
        x,z=profile[i]; xx,zz=profile[i+1]
        p.mesh([(x,-HALF,z),(x,HALF,z),(xx,HALF,zz),(xx,-HALF,zz)],[(0,1,2,3)],'Roof',True)
    for e in [-1,1]:
        p.mesh([(x,e*HALF,z) for x,z in profile],[tuple(range(33))],'Grey')
        for s in [-1,1]:
            p.box((s*1.035,e*11.728,2.465),(1.07,.084,2.29),'Grey')
        p.box((0,e*11.728,3.465),(1.00,.084,.31),'Grey')
    p.finish(.006)
    hardware=Parts('Door_hardware_steps_seams',b.ROOT)
    for s in [-1,1]:
        for e in [-1,1]:
            y=e*10.40
            hardware.box((s*1.63,y,2.34),(.035,.82,2.05),'Grey')
            hardware.box((s*1.653,y,2.44),(.015,.76,.83),'Red')
            hardware.box((s*1.659,y,2.99),(.015,.41,.45),'Rubber')
            hardware.box((s*1.671,y,2.99),(.016,.34,.38),'Glass')
            for yy in [y-.41,y+.41]:
                hardware.box((s*1.66,yy,2.34),(.014,.015,2.04),'Rubber')
            hardware.tube([(s*1.72,y-.57,1.63),(s*1.77,y-.57,1.70),(s*1.77,y-.57,2.91),(s*1.72,y-.57,3.0)],.018,'Steel')
            hardware.tube([(s*1.72,y+.57,1.63),(s*1.77,y+.57,1.70),(s*1.77,y+.57,2.91),(s*1.72,y+.57,3.0)],.018,'Steel')
            hardware.tube([(s*1.70,y+.25,2.34),(s*1.77,y+.25,2.34),(s*1.77,y+.25,2.14),(s*1.70,y+.25,2.14)],.018,'Steel')
            for z in [1.03,.75,.48]:
                hardware.box((s*1.58,y,z),(.48,.78,.048),'Bogie')
                for dy in [-.27,-.09,.09,.27]:
                    hardware.box((s*1.62,y+dy,z+.026),(.35,.012,.008),'Steel')
            for yy in [y-.34,y+.34]:
                hardware.box((s*1.74,yy,.75),(.035,.035,.60),'Steel')
            for z in [1.59,2.62,3.24]:
                hardware.cylinder((s*1.66,y-.43,z),(s*1.66,y-.43,z+.09),.022,'Steel',12)
            label('ENTRY','ENTRY',(s*1.68,y,3.48),.065,'Ink','RIGHT' if s>0 else 'LEFT')
        for y in [i*.98 for i in range(-11,12)]:
            hardware.box((s*1.625,y,1.67),(.006,.006,.68),'Seam')
        hardware.box((s*1.635,0,3.65),(.048,23.25,.043),'Grey')
        for y in [-6.4,6.4]:
            hardware.box((s*1.642,y,3.30),(.016,2.34,.245),'Yellow')
            label('Destination','CHENNAPURAM  -  KADALUR',(s*1.658,y,3.30),.091,'Ink','RIGHT' if s>0 else 'LEFT')
        label('Class','AC THREE TIER' if kind=='3a' else 'AC TWO TIER',(s*1.642,0,3.37),.15,'Letter','RIGHT' if s>0 else 'LEFT')
        label('Railway','SR',(s*1.65,-3.70,3.39),.16,'Letter','RIGHT' if s>0 else 'LEFT')
        label('Fleet','LWACCN  197204' if kind=='3a' else 'LWACCW  197108',(s*1.63,1.6,1.82),.085,'Letter','RIGHT' if s>0 else 'LEFT')
        label('Technical','AIR BRAKE  |  160 km/h  |  CBC',(s*1.63,-2.35,1.53),.052,'Letter','RIGHT' if s>0 else 'LEFT')
        label('Water','WATER FILL',(s*1.66,4.2,1.78),.05,'Letter','RIGHT' if s>0 else 'LEFT')
        hardware.ring((s*1.65,4.2,1.63),.055,.012,'Steel','X',24)
    hardware.finish(.009)


def spring(p,x,y,z,r=.11,h=.31,turns=6):
    p.tube([(x+r*math.cos(i*math.tau*turns/84),y+r*math.sin(i*math.tau*turns/84),z+h*i/84) for i in range(85)],.022,'Bogie',7)


def bogie(index,y):
    root=b.empty('Bogie_%d'%index,b.ROOT); root.location.y=y
    p=Parts('FIAT_Frame_%d'%index,root)
    for s in [-1,1]:
        p.box((s*1.045,0,.79),(.23,3.43,.27),'Bogie')
        for yy in [-1.28,1.28]:
            p.box((s*1.02,yy,.56),(.36,.42,.28),'Bogie')
            p.cylinder((s*1.05,yy,.4575),(s*1.24,yy,.4575),.148,'Bogie',32)
            for a in range(6):
                ang=a*math.tau/6
                p.cylinder((s*1.235,yy+.10*math.cos(ang),.4575+.10*math.sin(ang)),(s*1.258,yy+.10*math.cos(ang),.4575+.10*math.sin(ang)),.014,'Steel',6)
            for dy in [-.34,.34]: spring(p,s*1.045,yy+dy,.59,.085,.29,5)
            p.cylinder((s*1.15,yy-.30,.59),(s*1.15,yy-.20,1.03),.034,'Bogie',16)
            p.cylinder((s*1.15,yy-.30,.59),(s*1.15,yy-.26,.79),.051,'Steel',16)
        for yy in [-.32,.32]: spring(p,s*.91,yy,.91,.17,.36,6)
        p.box((s*.92,0,1.285),(.49,1.10,.09),'Bogie')
        p.cylinder((s*1.17,-.70,.88),(s*1.26,.90,1.15),.043,'Steel',16)
        p.cylinder((s*1.17,-.70,.88),(s*1.22,.20,1.03),.068,'Bogie',20)
        p.tube([(s*1.17,-1.55,.9),(s*1.17,-1.64,.58),(s*1.07,-1.66,.48)],.018,'Steel')
    for yy in [-.67,.67]: p.box((0,yy,.84),(2.18,.22,.21),'Bogie')
    p.cylinder((0,0,.75),(0,0,1.18),.21,'Bogie',32)
    p.cylinder((-1,-.52,.9),(1,-.52,.9),.048,'Steel',16)
    p.finish(.014)
    for j,yy in enumerate([-1.28,1.28]):
        pivot=b.empty('Axle_%d_%d'%(index,j+1),root); pivot.location=(0,yy,.4575)
        wh=Parts('Wheels_%d_%d'%(index,j+1),pivot)
        wh.cylinder((-1.09,0,0),(1.09,0,0),.085,'Steel',28)
        for s in [-1,1]:
            wh.cylinder((s*.765,0,0),(s*.915,0,0),.4575,'Tread',64)
            wh.cylinder((s*.747,0,0),(s*.785,0,0),.477,'Tread',64)
            wh.cylinder((s*.917,0,0),(s*.929,0,0),.374,'Bogie',56)
            wh.cylinder((s*.932,0,0),(s*.95,0,0),.143,'Steel',32)
            # Wear lines and hub fasteners rotate with the wheel.
            for r in [.205,.32,.409]: wh.ring((s*.933,0,0),r,.004,'Steel','X',48)
        for xx in [-.46,0,.46]:
            wh.cylinder((xx-.038,0,0),(xx+.038,0,0),.277,'Brake',48)
            wh.ring((xx+.041,0,0),.24,.014,'Steel','X',40)
            for a in range(16):
                ang=a*math.tau/16
                wh.cylinder((xx-.044,.20*math.cos(ang),.20*math.sin(ang)),(xx+.044,.20*math.cos(ang),.20*math.sin(ang)),.012,'Dark',6)
        wh.finish(.005)
        br=Parts('Brake_calipers_%d_%d'%(index,j),root)
        for xx in [-.46,0,.46]:
            br.box((xx,yy+.205,.61),(.22,.25,.22),'Bogie')
            br.cylinder((xx,yy+.19,.69),(xx,yy+.49,.69),.09,'Bogie',20)
            br.tube([(xx,yy+.48,.68),(xx,yy+.61,.90),(xx+.18,yy+.64,.94)],.013,'Rubber')
        br.finish(.01)


def equipment():
    p=Parts('Underfloor_tanks_battery_brake_pipes',b.ROOT)
    for y in [-3.30,3.30]:
        p.box((0,y,.78),(2.43,1.42,.61),'Grey')
        for x in [-.96,.96]: p.box((x,y,.77),(.055,1.48,.66),'Steel')
        for s in [-1,1]:
            for k in range(12): p.box((s*1.234,y-.53+k*.096,.77),(.012,.048,.42),'Under')
            p.box((s*1.25,y,1.075),(.012,1.27,.032),'Steel')
    p.box((-.57,0,.76),(1.17,2.02,.66),'Bogie')
    p.box((.75,0,.73),(.90,2.50,.61),'Grey')
    for y in [-.75,.75]:
        p.cylinder((-.93,y,.78),(.0,y,.78),.19,'Bogie',32)
    for s in [-1,1]:
        p.tube([(s*.61,-10.95,1.03),(s*.61,10.95,1.03)],.025,'PipeRed' if s<0 else 'PipeYellow')
        for y in [-4.65,4.65]:
            p.box((s*1.23,y,.99),(.22,.45,.22),'Bogie')
            p.cylinder((s*1.28,y,.82),(s*1.28,y,1.0),.035,'Steel',16)
        for y in [-.65,.65]:
            p.box((s*1.38,y,.72),(.16,.72,.46),'Bogie')
            for dy in [-.25,.25]: p.box((s*1.475,y+dy,.72),(.02,.09,.14),'Yellow')
    p.finish(.014)
    roof=Parts('Roof_RMPU_and_service_panels',b.ROOT)
    for e in [-1,1]:
        y=e*9.33
        roof.box((0,y,4.025),(2.27,2.49,.34),'Grey')
        for s in [-1,1]:
            for k in range(19): roof.box((s*1.143,y-1.10+k*.121,4.02),(.022,.05,.22),'Dark')
            roof.cylinder((s*.55,y,4.19),(s*.55,y,4.21),.38,'Dark',48)
            for r in [.1,.18,.26,.35,.38]: roof.ring((s*.55,y,4.224),r,.006,'Steel','Z',48)
            for a in range(16):
                an=a*math.tau/16
                roof.cylinder((s*.55,y,4.23),(s*.55+.38*math.cos(an),y+.38*math.sin(an),4.23),.004,'Steel',6)
        for dy in [-1.16,1.16]: roof.box((0,y+dy,4.201),(2.1,.016,.012),'Seam')
    for y in [-6,-3,0,3,6]:
        roof.box((0,y,4.258),(.92,.032,.012),'Seam')
        for x in [-.45,.45]: roof.cylinder((x,y,4.25),(x,y,4.266),.012,'Steel',6)
    roof.finish(.01)


def ends():
    for e in [-1,1]:
        p=Parts('Gangway_%s'%e,b.ROOT)
        # Bellows frame is hollow and the vestibule door is glazed.
        for k in range(6):
            y=e*(11.80+k*.028)
            p.tube([(-.61,y,1.34),(-.61,y,3.45),(.61,y,3.45),(.61,y,1.34)],.037,'Rubber')
        p.box((0,e*11.90,1.34),(1.16,.23,.055),'Steel')
        for s in [-1,1]:
            p.box((s*.46,e*11.68,2.38),(.12,.055,2.08),'Steel')
        p.box((0,e*11.68,1.75),(.8,.055,.8),'Grey')
        p.box((0,e*11.68,3.35),(.8,.055,.14),'Grey')
        p.box((0,e*11.68,2.73),(.79,.03,1.08),'Glass')
        p.box((0,e*11.84,1.04),(.23,.22,.18),'Under')
        p.box((0,e*11.975,1.04),(.29,.05,.24),'Bogie')
        p.box((.105,e*11.98,1.055),(.07,.055,.17),'Steel')
        p.cylinder((-.10,e*11.89,.90),(-.10,e*11.89,1.18),.025,'Steel',16)
        for s in [-1,1]:
            p.tube([(s*.47,e*11.7,1.13),(s*.50,e*11.83,.88),(s*.37,e*11.96,.61),(s*.31,e*11.98,.84)],.027,'Rubber')
            p.cylinder((s*.47,e*11.67,1.12),(s*.47,e*11.79,1.12),.046,'PipeRed' if s<0 else 'PipeYellow',16)
            p.box((s*.45,e*11.79,1.20),(.15,.026,.025),'Steel')
            p.ring((s*1.20,e*11.783,2.88),.070,.018,'Rubber','Y',24)
        p.finish(.008)
        tail=Parts('TailMarker_%s'%e,b.ROOT)
        for s in [-1,1]: tail.cylinder((s*1.20,e*11.775,2.88),(s*1.20,e*11.805,2.88),.052,'Tail',24)
        tail.finish()
        label('End_warning','CAUTION\n25000 V',(.99,e*11.78,3.33),.047,'Ink','FRONT' if e>0 else 'REAR')
    tail=Parts('LastVehicleBoard',b.ROOT)
    tail.box((.97,-11.80,2.1),(.35,.025,.35),'Yellow')
    tail.finish(.015)
    label('LastVehicleLetters','LV',(.97,-11.817,2.10),.20,'Ink','REAR',tail.parent)


def berth(name,p,size,parent):
    q=Parts(name,parent)
    q.box((p[0],p[1],p[2]-.067),(size[0]+.025,size[1]+.025,.055),'Steel')
    q.box(p,(*size,.12),'Blue')
    ob=q.finish(.04)
    return ob


def interior(kind):
    root=b.empty('Interior',b.ROOT)
    p=Parts('Interior_lining_floor',root)
    p.box((0,0,1.31),(3.00,23.3,.035),'Floor')
    p.box((0,0,3.91),(2.87,23.3,.09),'Lining')
    for s in [-1,1]:
        p.box((s*1.478,0,1.717),(.04,23.4,.76),'Lining')
        p.box((s*1.478,0,3.44),(.04,23.4,.90),'Lining')
        bounds=[-9.25]+[v for y in CENTRES for v in (y-.66,y+.66)]+[9.25]
        for a,c in zip(bounds[::2],bounds[1::2]): p.box((s*1.478,(a+c)/2,2.545),(.04,c-a,.89),'Lining')
        for y in [-10.5,10.5]: p.box((s*1.48,y,2.53),(.04,2.48,2.35),'Lining')
        p.box((s*1.438,0,1.37),(.035,23.35,.10),'Steel')
    p.finish(.008)
    furniture=Parts('Partitions_ladders_tables_racks',root)
    fixtures=Parts('Reading_lights_sockets_bottles',root)
    for idx,y in enumerate(CENTRES):
        # Main transverse bay: six berths for 3A; four for 2A.
        for e in [-1,1]:
            yy=y+e*.935
            furniture.box((-.545,yy,2.53),(1.84,.055,2.37),'Partition')
            furniture.box((.365,yy,2.50),(.035,.09,2.31),'Steel')
            furniture.box((-.57,yy,1.51),(1.73,.09,.34),'Dark')
            if kind=='2a' and not (idx==8 and e>0):
                back=Parts('Seat_backrest_%d_%d'%(idx,e),root)
                back.box((-.545,yy-e*.095,2.24),(1.76,.115,.68),'Blue')
                back.finish(.04)
            levels=[1.81,2.51,3.22] if kind=='3a' else [1.81,3.02]
            for tier,z in enumerate(levels):
                num=idx*(8 if kind=='3a' else 6)+(0 if e<0 else len(levels))+tier+1
                if kind=='2a' and idx==8 and e>0:
                    # Final four-berth bay: one pair across and one side pair.
                    continue
                if kind=='3a' and tier==1:
                    hinge=b.empty('MiddleBerth_%02d'%num,root)
                    hinge.location=(-.545,yy-e*.04,z)
                    berth('Berth_%02d'%num,(0,-e*.325,0),(1.78,.65),hinge)
                    hinge.rotation_euler.x=e*math.pi/2
                    hinge['deployed_x']=0.0; hinge['folded_x']=e*math.pi/2
                else:
                    berth('Berth_%02d'%num,(-.545,yy-e*.365,z),(1.78,.65),root)
                # Number plates, reading lamp and socket above each berth.
                fixtures.box((.33,yy-e*.044,z+.12),(.13,.014,.095),'Blue')
                label('Berth_number_%02d'%num,str(num),(.33,yy-e*.055,z+.12),.055,'Letter','REAR' if e>0 else 'FRONT',root)
                fixtures.box((-1.31,yy-e*.043,z+.19),(.15,.025,.085),'White')
                fixtures.box((-1.31,yy-e*.06,z+.19),(.10,.008,.025),'Light')
                fixtures.box((-1.07,yy-e*.043,z+.18),(.10,.03,.11),'White')
                for dx in [-.023,.023]: fixtures.cylinder((-1.07+dx,yy-e*.063,z+.18),(-1.07+dx,yy-e*.071,z+.18),.009,'Dark',8)
                if tier>0:
                    furniture.tube([(.34,yy-e*.16,z+.05),(.34,yy-e*.16,z+.26),(.34,yy-e*.58,z+.26),(.34,yy-e*.58,z+.05)],.014,'Steel')
            # Ladder sits at the aisle boundary, outside the middle berth sweep.
            furniture.tube([(.40,yy-e*.14,1.48),(.40,yy-e*.14,3.31),(.40,yy-e*.29,3.40)],.018,'Steel')
            furniture.tube([(.40,yy-e*.51,1.48),(.40,yy-e*.51,3.31),(.40,yy-e*.37,3.40)],.018,'Steel')
            for zz in [1.67,2.01,2.35,2.69,3.03]:
                furniture.cylinder((.4,yy-e*.14,zz),(.4,yy-e*.51,zz),.018,'Steel',12)
            furniture.box((-.55,yy-e*.27,1.55),(1.50,.48,.045),'Steel')
            for xx in [-1.21,-.90,-.59,-.28,.03]:
                furniture.cylinder((xx,yy-e*.06,1.58),(xx,yy-e*.51,1.58),.012,'Steel',8)
        # A folding window table and wall-mounted wire bottle holders.
        furniture.box((-1.30,y,2.00),(.30,.40,.045),'Partition')
        furniture.tube([(-1.44,y,1.71),(-1.17,y,1.98)],.014,'Steel')
        for dy in [-.30,.30]:
            fixtures.ring((-1.38,y+dy,2.39),.055,.005,'Steel','Z',20)
            fixtures.ring((-1.38,y+dy,2.25),.055,.005,'Steel','Z',20)
            fixtures.cylinder((-1.43,y+dy,2.25),(-1.43,y+dy,2.42),.005,'Steel',6)
        # Side berths run longitudinally, separated by the clear aisle.
        for tier,z in enumerate([1.81,3.02]):
            num=idx*(8 if kind=='3a' else 6)+(7 if kind=='3a' else 5)+tier
            if kind=='2a' and idx==8: num=51+tier
            berth('Berth_%02d'%num,(1.14,y,z),(.62,1.84),root)
            if tier==1:
                furniture.tube([(.815,y-.75,z+.02),(.815,y-.75,z+.28),(.815,y+.75,z+.28),(.815,y+.75,z+.02)],.014,'Steel')
            label('Side_berth_number',str(num),(1.44,y+.81,z+.14),.055,'Ink','LEFT',root)
        for e in [-1,1]:
            furniture.box((1.15,y+e*.955,2.43),(.64,.035,2.20),'Partition')
        # Two-tier curtains gathered at each bay edge; waves are actual geometry.
        if kind=='2a':
            for e in [-1,1]:
                q=Parts('Curtain_%d_%d'%(idx,e),root)
                vs=[]
                for z in [1.47,3.52]:
                    for k in range(41):
                        yy=y+e*(.64+k*.0067)
                        vs.append((.46+.035*math.sin(k*math.pi/4),yy,z))
                q.mesh(vs,[(k,k+1,k+42,k+41) for k in range(40)],'Curtain',True)
                q.finish()
            furniture.cylinder((.46,y-.95,3.56),(.46,y+.95,3.56),.013,'Steel',12)
        # Twin ceiling ducts and the aisle light.
        fixtures.box((.60,y,3.85),(.26,.84,.055),'Steel')
        fixtures.box((.60,y,3.816),(.21,.77,.012),'Light')
        for x in [-.85,1.12]:
            fixtures.box((x,y,3.844),(.21,.52,.025),'Grey')
            for k in range(9): fixtures.box((x,y-.22+k*.055,3.827),(.18,.012,.007),'Dark')
        # Compact ceiling fans with wire cages, typical of classic LHB interiors.
        for x in [-.24,.92]:
            fixtures.cylinder((x,y,3.86),(x,y,3.71),.045,'White',16)
            for rad in [.07,.12,.175]: fixtures.ring((x,y,3.70),rad,.004,'Steel','Z',32)
            for k in range(12):
                a=k*math.tau/12
                fixtures.cylinder((x,y,3.694),(x+.18*math.cos(a),y+.18*math.sin(a),3.694),.003,'Steel',6)
            for k in range(3):
                a=k*math.tau/3
                fixtures.box((x+.08*math.cos(a),y+.08*math.sin(a),3.714),(.14,.05,.012),'Grey',Matrix.Rotation(a,3,'Z'))
    furniture.finish(.009); fixtures.finish(.003)
    vestibules(root,kind)


def vestibules(root,kind):
    p=Parts('Vestibules_toilets_washbasins',root)
    for e in [-1,1]:
        y=e*9.14
        # Passenger compartment end wall with a central clear glazed door.
        for x in [-1.10,1.10]: p.box((x,y,2.56),(.78,.075,2.43),'Lining')
        p.box((0,y,3.62),(1.44,.075,.32),'Lining')
        for x in [-.62,.62]: p.box((x,y,2.49),(.06,.08,2.26),'Steel')
        p.box((0,y,1.65),(1.18,.045,.61),'Grey')
        p.box((0,y,3.55),(1.18,.045,.13),'Grey')
        p.box((0,y,2.59),(1.18,.015,1.28),'Glass')
        p.cylinder((.42,y-e*.10,2.28),(.42,y-e*.10,2.65),.015,'Steel',12)
        label('Vestibule_sign','VESTIBULE  /  TOILETS',(0,y-e*.05,3.69),.075,'Ink','REAR' if e>0 else 'FRONT',root)
        # Toilet modules beyond the entry space. Doors open onto a centre passage.
        for s in [-1,1]:
            ty=e*11.03
            p.box((s*1.01,ty-e*.66,2.53),(.94,.04,2.40),'Partition')
            p.box((s*.54,ty,1.75),(.04,1.26,.80),'Partition')
            p.box((s*.54,ty,3.32),(.04,1.26,.73),'Partition')
            p.box((s*.54,ty+e*.43,2.55),(.04,.41,.80),'Partition')
            # Half-open toilet door permits inspection from the vestibule.
            p.box((s*.56,ty-e*.20,2.48),(.035,.70,2.18),'Lining',Matrix.Rotation(s*.50,3,'Z'))
            p.box((s*.51,ty-e*.28,2.49),(.045,.13,.03),'Steel')
            p.box((s*1.02,ty,1.53),(.39,.53,.34),'Ceramic')
            p.ring((s*1.02,ty,1.74),.21,.045,'Ceramic','Z',36)
            p.cylinder((s*1.02,ty,1.72),(s*1.02,ty,1.734),.165,'Dark',36)
            p.box((s*1.02,ty+e*.30,1.99),(.42,.11,.50),'Ceramic')
            p.box((s*1.40,ty,2.36),(.015,.35,.48),'Mirror')
            p.cylinder((s*1.42,ty-e*.29,1.76),(s*1.42,ty-e*.29,2.11),.02,'Steel',12)
        # Washbasin, tap, mirror and extinguisher at opposite entry corners.
        for dx in [-.335,.335]:
            p.box((-.99+dx,e*9.73,2.00),(.10,.48,.085),'Grey')
        for dy in [-.22,.22]:
            p.box((-.99,e*9.73+dy,2.00),(.77,.04,.085),'Grey')
        p.cylinder((-.99,e*9.73,1.87),(-.99,e*9.73,2.07),.19,'Steel',40,r2=.27)
        p.cylinder((-.99,e*9.73,2.071),(-.99,e*9.73,2.073),.21,'Dark',40)
        p.tube([(-1.24,e*9.73,2.04),(-1.24,e*9.73,2.27),(-1.09,e*9.73,2.27),(-1.09,e*9.73,2.20)],.018,'Steel')
        p.box((-1.446,e*9.73,2.72),(.018,.55,.62),'Mirror')
        p.cylinder((1.23,e*9.73,1.45),(1.23,e*9.73,2.04),.093,'Red',24)
        p.box((1.23,e*9.73,2.09),(.14,.055,.035),'Dark')
        p.box((.80,e*9.31,2.72),(.34,.045,.47),'Yellow')
        label('Emergency_notice','EMERGENCY\nALARM',( .80,e*9.278,2.83),.044,'Ink','REAR' if e>0 else 'FRONT',root)
        p.box((.80,e*9.265,2.58),(.12,.045,.035),'Red')
        p.box((0,e*10.39,3.84),(.29,.75,.035),'Light')
    p.finish(.012)


def studio(kind):
    sc=bpy.context.scene
    studio=bpy.data.collections.new('STUDIO_Not_exported'); sc.collection.children.link(studio)
    sc.world=bpy.data.worlds.new('LHB daylight'); sc.world.use_nodes=True
    sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.55,.66,.77,1)
    sc.world.node_tree.nodes['Background'].inputs[1].default_value=.5
    p=Parts('Ground',collection=studio); p.box((0,0,-.25),(200,200,.10),'Grey'); p.finish()
    for name,loc,power,size in [('Key',(-9,4,18),6000,12),('Fill',(8,-8,10),4200,10),('Rim',(3,15,11),3200,8)]:
        d=bpy.data.lights.new(name,'AREA'); d.energy=power; d.size=size
        o=bpy.data.objects.new(name,d); studio.objects.link(o); o.location=loc
        o.rotation_euler=(Vector((0,0,1.8))-o.location).to_track_quat('-Z','Y').to_euler()
    for y in CENTRES+[-10.4,10.4]:
        d=bpy.data.lights.new('Interior bounce','AREA'); d.energy=38; d.shape='RECTANGLE'; d.size=2.2; d.size_y=.8
        o=bpy.data.objects.new('Interior bounce',d); studio.objects.link(o); o.location=(0,y,3.77)
    cameras=[('Hero',(-19,25,10),(0,0,1.9),42),('Bogie',(-4.0,10.4,1.5),(0,7.45,.65),46),
             ('Aisle',(.60,-6.72,2.92),(.61,7,2.65),20),
             ('Compartment',(.70,-7.91,2.77),(-1.03,-7.87,2.38),18),
             ('Vestibule',(.15,9.43,2.91),(-.40,11.3,2.13),19)]
    for name,loc,target,lens in cameras:
        d=bpy.data.cameras.new(name); d.lens=lens; d.clip_start=.03
        o=bpy.data.objects.new(name,d); studio.objects.link(o); o.location=loc
        o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler()
    sc.camera=bpy.data.objects['Hero']; sc.render.engine='CYCLES'; sc.cycles.samples=24; sc.cycles.use_denoising=True
    sc.render.resolution_x=1600; sc.render.resolution_y=1000; sc.render.resolution_percentage=100
    sc.view_settings.view_transform='AgX'


def build(kind):
    for ob in list(bpy.data.objects): bpy.data.objects.remove(ob,do_unlink=True)
    for col in list(bpy.data.collections): bpy.data.collections.remove(col)
    for data in [bpy.data.meshes,bpy.data.materials,bpy.data.curves]:
        for item in list(data): data.remove(item)
    b.M={}; b.GROUPS=[]
    b.ASSET=bpy.data.collections.new('LHB_'+kind.upper()); bpy.context.scene.collection.children.link(b.ASSET)
    b.ROOT=b.empty('LHB_'+kind.upper()); b.ROOT['length_over_couplers_m']=24.0
    b.ROOT['body_length_m']=23.54; b.ROOT['bogie_centres_m']=14.9
    b.ROOT['berths']=72 if kind=='3a' else 52
    b.FONT=bpy.data.fonts.load('C:/Windows/Fonts/bahnschrift.ttf')
    palette(); body(kind); bogie(1,7.45); bogie(2,-7.45); equipment(); ends(); interior(kind)
    bpy.ops.object.select_all(action='DESELECT')
    for ob in b.ASSET.objects: ob.select_set(True)
    bpy.context.view_layer.objects.active=b.ROOT
    dest=os.path.join(MODELS,'lhb_'+kind+'.glb')
    bpy.ops.export_scene.gltf(filepath=dest,export_format='GLB',use_selection=True,export_apply=True,export_extras=True)
    stats={'variant':kind,'berths':b.ROOT['berths'],'objects':len(b.ASSET.objects),'glb_bytes':os.path.getsize(dest)}
    studio(kind)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'lhb_'+kind+'.blend'),compress=True)
    if '--render' in sys.argv:
        for name in ['Hero','Bogie','Aisle','Compartment','Vestibule']:
            if kind=='2a' and name in ['Bogie','Vestibule']: continue
            sc=bpy.context.scene; sc.camera=bpy.data.objects[name]
            sc.render.filepath=os.path.join(OUT,kind+'_'+name.lower()+'.png')
            bpy.ops.render.render(write_still=True)
    print('LHB_COMPLETE '+json.dumps(stats),flush=True)


if __name__=='__main__':
    if not bpy.app.background: raise RuntimeError('Background Blender only.')
    os.makedirs(OUT,exist_ok=True)
    for kind in ['3a','2a']: build(kind)
