"""Original metre-scale MEMU detail kit, called only by the background builder."""
import math
import bpy
import bmesh
from mathutils import Vector, Matrix


class Kit:
    def __init__(self, api, scene, parent, name):
        self.api, self.scene, self.parent, self.name = api, scene, parent, name
        self.parts = {}

    def bm(self, material):
        if material not in self.parts:
            self.parts[material] = bmesh.new()
        return self.parts[material]

    def box(self, material, p, size):
        self.api.box(self.bm(material), p, size)

    def cylinder(self, material, a, b, radius, segments=20, radius2=None):
        a, b = Vector(a), Vector(b)
        matrix = Matrix.Translation((a+b)/2) @ (b-a).to_track_quat('Z','Y').to_matrix().to_4x4()
        bmesh.ops.create_cone(self.bm(material), cap_ends=True, segments=segments,
            radius1=radius, radius2=radius if radius2 is None else radius2, depth=(b-a).length, matrix=matrix)

    def tube(self, material, points, radius=.012, sides=8):
        for a,b in zip(points, points[1:]):
            self.cylinder(material,a,b,radius,sides)

    def spring(self, p, radius=.10, height=.23):
        points=[]
        for i in range(97):
            angle=math.tau*5*i/96
            points.append((p[0]+radius*math.cos(angle),p[1]+radius*math.sin(angle),p[2]+height*i/96))
        self.tube('Spring',points,.015,6)

    def finish(self, bevel=0):
        for material,bm in self.parts.items():
            bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
            ob=self.api.new_object(self.name+'_'+material,bm,self.scene,self.parent)
            self.api.assign(ob,[material])
            if bevel and material in ('Frame','Under','Blue','Roof','Door'):
                modifier=ob.modifiers.new('Formed edges','BEVEL')
                modifier.width=bevel
                modifier.segments=2
                modifier.limit_method='ANGLE'
            normal=ob.modifiers.new('Weighted face normals','WEIGHTED_NORMAL')
            normal.keep_sharp=True


def empty(scene,name,parent,p):
    ob=bpy.data.objects.new(name,None)
    scene.collection.objects.link(ob)
    ob.parent=parent
    ob.location=p
    return ob


def materials(api):
    for name,color,rough,metal in [
        ('Frame',(.05,.06,.055),.71,.45),('WheelTread',(.27,.29,.29),.25,.95),
        ('WheelFace',(.062,.07,.06),.72,.65),('Spring',(.095,.087,.067),.64,.55),
        ('BrakeDust',(.15,.10,.058),.84,.2),('Grille',(.025,.032,.027),.73,.45),
        ('Copper',(.26,.12,.043),.42,.85),('Ceramic',(.17,.068,.03),.24,.08),
        ('Gasket',(.007,.009,.008),.83,0),('Grease',(.018,.02,.015),.35,.2)]:
        api.material(name,color,rough,metal)


def running_gear(api,scene,name,parent,motor):
    for index,by in enumerate((-14.783/2,14.783/2)):
        bogie=empty(scene,name+'_Bogie%d'%index,parent,(0,by,0))
        kit=Kit(api,scene,bogie,name+'_Bogie%d'%index)
        for side in (-1,1):
            x=side*1.06
            # Open fabricated side frame: individual chords and pedestals.
            kit.box('Frame',(x,0,.88),(.19,3.38,.17))
            kit.box('Frame',(x,0,.59),(.15,2.78,.13))
            for y in (-1.448,1.448):
                kit.box('Frame',(x,y,.65),(.29,.42,.36))
                kit.cylinder('Grease',(x-side*.15,y,.46),(x+side*.16,y,.46),.115)
                for dy in (-.26,.26):
                    kit.spring((x,y+dy,.60),.075,.22)
                # Brake blocks sit next to tread, with pull rods and hangers.
                for dy in (-.31,.31):
                    kit.box('BrakeDust',(side*.88,y+dy,.44),(.15,.09,.27))
                    kit.cylinder('Frame',(x,y+dy,.48),(x,y+dy,.82),.028,10)
            for y in (-.40,.40):
                kit.spring((x,y,.86),.115,.20)
            kit.cylinder('Steel',(x+side*.12,-.55,.63),(x+side*.12,.55,.89),.035)
            kit.cylinder('Frame',(x+side*.12,-.55,.63),(x+side*.12,.08,.78),.065)
            kit.cylinder('Frame',(x,-1.65,.33),(x,1.65,.33),.025,10)
        kit.box('Frame',(0,0,.95),(2.38,.38,.23))
        for y in (-1.15,1.15): kit.box('Frame',(0,y,.78),(2.1,.18,.19))
        if motor:
            for y in (-1.0,1.0): kit.cylinder('Under',(-.55,y,.6),(.55,y,.6),.27,24)
        kit.finish(.008)
        for axle_index,ay in enumerate((-2.896/2,2.896/2)):
            axle=empty(scene,name+'_Axle%d%d'%(index,axle_index),bogie,(0,ay,.46))
            wheel=Kit(api,scene,axle,name+'_Wheel%d%d'%(index,axle_index))
            wheel.cylinder('Steel',(-1.08,0,0),(1.08,0,0),.075)
            for side in (-1,1):
                # Tread centred over the 1676 mm gauge; flange on the inside.
                wheel.cylinder('WheelTread',(side*.83,0,0),(side*.95,0,0),.46,48)
                wheel.cylinder('WheelFace',(side*.815,0,0),(side*.835,0,0),.488,48)
                wheel.cylinder('WheelFace',(side*.952,0,0),(side*.964,0,0),.39,48)
                wheel.cylinder('Steel',(side*.956,0,0),(side*1.02,0,0),.125,24)
                for i in range(8):
                    angle=i*math.tau/8
                    y,z=.24*math.sin(angle),.24*math.cos(angle)
                    wheel.cylinder('Grease',(side*.965,y,z),(side*.969,y,z),.037,12)
            wheel.finish()
    kit=Kit(api,scene,parent,name+'_UnderfloorDetails')
    for side in (-1,1):
        kit.box('Frame',(side*1.33,0,1.075),(.13,19.8,.15))
        kit.cylinder('Under',(side*.63,-3.8,.72),(side*.63,-2.15,.72),.22,28)
        kit.tube('Frame',[(side*1.43,-8,.92),(side*1.43,-4,.92),(side*1.43,-4,.6),(side*.63,-3.8,.6)],.025)
        for y in (-1.2,1.0,3.2):
            kit.box('Under',(side*.82,y,.69),(1.15,1.55,.58))
            kit.box('Frame',(side*1.405,y,.69),(.018,1.42,.47))
            for z in (.51,.86):
                for dy in (-.62,.62):
                    kit.cylinder('Steel',(side*1.42,y+dy,z),(side*1.436,y+dy,z),.018,6)
            for j in range(10):
                kit.box('Grille',(side*1.426,y-.5+j*.105,.70),(.02,.025,.24))
    for end in (-1,1):
        y=end*(api.L/2+.19)
        kit.box('Frame',(0,y,.92),(.28,.39,.30))
        kit.box('Grease',(0,y+end*.09,.92),(.40,.19,.35))
        for side in (-1,1):
            kit.cylinder('Frame',(side*.95,y-end*.3,1.0),(side*.95,y,1.0),.115)
            kit.box('Steel',(side*.95,y+end*.03,1.0),(.38,.075,.25))
            kit.tube('Rubber',[(side*.48,y-end*.2,1.0),(side*.55,y+end*.07,.77),(side*.38,y+end*.1,.48)],.026)
    kit.finish(.008)


def exterior(api,scene,name,parent,cab,motor):
    kit=Kit(api,scene,parent,name+'_ExteriorDetails')
    doors=(-api.L/2+4.2,api.L/2-4.2)
    for side in (-1,1):
        x=side*(api.HALF_W+.025)
        # Rain gutter and a raised pressed sill create long, readable highlights.
        kit.box('Roof',(x,0,3.39),(.035,api.L-.25,.035))
        kit.box('Blue',(x,0,1.31),(.026,api.L-.20,.055))
        for y in doors:
            for edge in (-.7,.7):
                kit.box('Gasket',(x,y+edge,2.22),(.026,.026,2.03))
                kit.tube('Steel',[(x,y+edge*1.18,1.55),(x+side*.065,y+edge*1.18,1.63),
                    (x+side*.065,y+edge*1.18,2.56),(x,y+edge*1.18,2.64)],.016)
            kit.box('Gasket',(x,y,2.22),(.035,.014,1.98))
            for z in (.65,.90,1.16):
                kit.box('Frame',(side*1.75,y,z),(.22,1.37,.048))
                for dy in (-.58,.58): kit.box('Steel',(side*1.845,y+dy,z+.014),(.018,.06,.018))
        spans=[(-api.L/2+.9,doors[0]-.675-.4),(doors[0]+.675+.4,doors[1]-.675-.4),
            (doors[1]+.675+.4,api.L/2-(2.2 if cab else .9))]
        for start,end in spans:
            count=max(1,round((end-start)/1.45))
            for i in range(count):
                a=start+i*(end-start)/count+.12
                b=start+(i+1)*(end-start)/count-.12
                if b-a<.3: continue
                for y in (a,b): kit.box('Rubber',(x,y,2.715),(.028,.032,.77))
                for z in (2.35,3.08): kit.box('Rubber',(x,(a+b)/2,z),(.028,b-a+.035,.032))
                # Indian commuter protective bars and sliding-window mullion.
                for z in (2.52,2.75,2.97): kit.cylinder('Steel',(x+side*.028,a,z),(x+side*.028,b,z),.008,8)
                kit.box('Door',(x+side*.017,(a+b)/2,2.72),(.022,.025,.70))
    for i in range(6):
        y=-api.L/2+2.5+i*(api.L-5)/5
        for side in (-1,1):
            for k in range(8): kit.box('Grille',(side*.309,y-.35+k*.10,4.015),(.018,.028,.07))
    for y in [v*2.0 for v in range(-4,5)]:
        for side in (-1,1):
            kit.tube('Roof',[(side*.03,y,3.965),(side*.65,y,3.935),(side*1.29,y,3.817),(side*1.61,y,3.668)],.010,6)
    if cab:
        for side in (-1,1):
            # Windscreen gaskets follow the sloping face.
            x0,x1=(.06,1.55) if side>0 else (-1.55,-.06)
            pts=[(x0,api.L/2-(z-api.CAB_SLOPE_FROM)*api.CAB_SLOPE+.030,z) for z in (2.45,3.3)]
            pts += [(x1,api.L/2-(z-api.CAB_SLOPE_FROM)*api.CAB_SLOPE+.030,z) for z in (3.3,2.45)]
            kit.tube('Rubber',pts+[pts[0]],.024,10)
            kit.tube('Frame',[(side*.55,api.L/2-.04,2.38),(side*.81,api.L/2-.14,2.77),(side*1.24,api.L/2-.17,2.88)],.012)
            kit.cylinder('Frame',(side*1.1,api.L/2-.7,3.76),(side*1.1,api.L/2-.23,3.77),.055,20,.11)
            for k in range(5): kit.box('Grille',(side*1.18,api.L/2+.027,1.36+k*.052),(.51,.026,.023))
        kit.box('Frame',(0,api.L/2+.14,.46),(2.74,.11,.16))
        for x in [-1.15,-.77,-.39,0,.39,.77,1.15]:
            kit.tube('Frame',[(x,api.L/2+.08,.85),(x,api.L/2+.22,.4)],.024,8)
    if motor:
        for x in (-.65,.65):
            for y in (-.7,.7):
                for i in range(4): kit.cylinder('Ceramic',(x,y,4.07+i*.045),(x,y,4.09+i*.045),.09,16)
        kit.tube('Copper',[(.55,-.7,4.25),(.55,-2,4.25),(.55,-3,4.18)],.022)
    kit.finish(.003)
