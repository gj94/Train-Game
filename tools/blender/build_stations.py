"""Photo-referenced Southern Railway architecture. Background Blender only.

Original geometry; references and deliberate layout adaptations: docs/stations.md.
Input coordinates below are game metres (x along track, z across, h above ground).
The exported kits have 600 m platforms, not a uniformly scaled miniature station.
"""
import os, sys, math
import bpy
from mathutils import Vector, Matrix
sys.path.insert(0, os.path.dirname(__file__))
import build_wap7 as b

OUT = os.path.join(b.P, 'art', 'stations')
MODELS = os.path.join(b.P, 'assets', 'models', 'stations')
SURFACE = 1.3  # rail top .5 + .8 m high-level platform


def xyz(p):
    x, z, h = p
    return (x, -z, h)


class Assembly:
    def __init__(self, name): self.p = b.Parts(name, b.ROOT)
    def box(self, p, size, mat):
        x, z, h = size
        self.p.box(xyz(p), (x, z, h), mat)
    def beam(self, a, c, width, mat):
        a, c = Vector(xyz(a)), Vector(xyz(c))
        self.p.box((a+c)/2, (width, width, (c-a).length), mat, (c-a).to_track_quat('Z','Y').to_matrix())
    def pipe(self, a, c, radius, mat): self.p.cylinder(xyz(a), xyz(c), radius, mat, 10)
    def finish(self, bevel=0): return self.p.finish(bevel)


def palette():
    for n,c,r,m in [
        ('Concrete',(.49,.47,.42),.94,0), ('Coping',(.74,.72,.64),.86,0),
        ('Paver',(.48,.20,.14),.9,0), ('PaverPale',(.68,.60,.45),.86,0),
        ('Cream',(.78,.70,.49),.85,0), ('Ivory',(.87,.83,.68),.86,0),
        ('Maroon',(.29,.065,.046),.8,0), ('RoofBlue',(.18,.43,.59),.56,.3),
        ('RoofRed',(.48,.12,.065),.75,.25), ('RoofGrey',(.36,.39,.39),.78,.25),
        ('Steel',(.44,.49,.47),.65,.7), ('DarkSteel',(.12,.19,.18),.7,.65),
        ('White',(.8,.81,.74),.7,.1), ('Blue',(.025,.19,.39),.55,.3),
        ('Yellow',(.93,.61,.035),.66,0), ('Black',(.022,.028,.026),.82,0),
        ('Glass',(.065,.14,.16),.26,.3), ('TileBlue',(.075,.28,.50),.34,0),
        ('TileWhite',(.78,.81,.76),.36,0), ('Green',(.035,.32,.14),.73,0),
        ('Pink',(.70,.35,.36),.8,0), ('Sandstone',(.73,.51,.36),.88,0),
        ('Asphalt',(.105,.12,.115),.98,0), ('Tyre',(.021,.023,.02),.96,0),
        ('Shadow',(.025,.031,.023),.94,0),
    ]:
        mat=b.mat(n,c,r,m); mat.name='SR_'+n


def corrugated(a, x0, x1, z0, z1, h0, h1, mat):
    # Actual profiled sheet with closed underside; ribs run down the fall.
    step=.24; count=round((x1-x0)/step)
    for i in range(count):
        x=x0+(x1-x0)*i/count; nx=x0+(x1-x0)*(i+1)/count
        pts=[(x,z0,h0),(x+(nx-x)*.35,z0,h0+.035),(x+(nx-x)*.65,z0,h0+.035),(nx,z0,h0),
             (x,z1,h1),(x+(nx-x)*.35,z1,h1+.035),(x+(nx-x)*.65,z1,h1+.035),(nx,z1,h1)]
        # Separate top/bottom vertices: coincident reversed faces were removed by
        # Godot's mesh optimisation. A closed 40 mm sheet survives generated LODs.
        pts += [(x,z,h-.04) for x,z,h in pts]
        faces=[(4,5,1,0),(5,6,2,1),(6,7,3,2),
               (8,9,13,12),(9,10,14,13),(10,11,15,14),
               (0,8,12,4),(3,7,15,11)]
        for j in range(3):
            faces.extend([(j,j+1,j+9,j+8),(j+4,j+12,j+13,j+5)])
        sheet_mat = ('RoofRed' if int((x+300)/6)%2 else 'White') if mat=='RoofRedStripe' else mat
        a.p.mesh([xyz(v) for v in pts],faces,sheet_mat)


def platform(z0,z1,idx):
    a=Assembly('Platform_%d_600m'%idx)
    a.box((0,(z0+z1)/2,.62),(600,z1-z0,1.24),'Maroon')
    a.box((0,(z0+z1)/2,1.26),(600,z1-z0,.08),'Concrete')
    for z in [z0,z1]:
        sign=1 if z==z0 else -1
        a.box((0,z+sign*.20,1.32),(600,.4,.04),'Coping')
        a.box((0,z+sign*.95,1.308),(600,.1,.016),'Yellow')
        a.box((0,z+sign*.52,.65),(600,.015,.10),'Maroon')
        for x in range(-300,300,2):
            a.box((x+.99,z+sign*.42,.98),(1.95,.045,.48),'Paver')
        for x in range(-300,300,3):
            a.box((x+1.49,z+sign*1.7,1.306),(2.98,1.1,.014),'Paver')
            a.box((x+1.5,z+sign*1.7,1.317),(.72,.72,.012),'PaverPale')
        # Watering pipe recessed below the platform coping, with hose valves.
        a.pipe((-299,z,.93),(299,z,.93),.035,'Blue')
        for x in range(-288,295,24):
            a.pipe((x,z,.93),(x,z,1.18),.028,'Steel')
            a.pipe((x-.12,z,1.19),(x+.12,z,1.19),.019,'Yellow')
    for x in range(-300,301,6):
        a.box((x,(z0+z1)/2,1.304),(.018,z1-z0-.85,.007),'RoofGrey')
    # Ramped ends beyond the 600 m usable level platform.
    for s in [-1,1]:
        a.p.mesh([xyz(p) for p in [(s*300,z0,0),(s*308,z0,0),(s*300,z0,1.3),
                    (s*300,z1,0),(s*308,z1,0),(s*300,z1,1.3)]],
                    [(0,2,1),(3,4,5),(2,5,4,1),(0,3,5,2),(0,1,4,3)],'Concrete')
    a.finish()


def canopy(z, width, x0, x1, material, name):
    a=Assembly(name)
    trim='RoofRed' if material=='RoofRedStripe' else material
    eave=5.35; ridge=6.05
    corrugated(a,x0,x1,z-width/2,z,eave,ridge,material)
    corrugated(a,x0,x1,z,z+width/2,ridge,eave,material)
    for side in [-1,1]:
        edge=z+side*width/2
        a.box(((x0+x1)/2,edge,eave-.17),(x1-x0,.08,.36),trim)
        a.pipe((x0,edge,eave),(x1,edge,eave),.065,'RoofGrey')
    for x in range(int(x0)+3,int(x1),6):
        a.box((x,z,1.53),(.68,.68,.46),'DarkSteel')
        a.box((x,z,3.43),(.13,.23,3.6),'Steel')
        for dx in [-.14,.14]: a.box((x+dx,z,3.43),(.055,.32,3.6),'Steel')
        for side in [-1,1]:
            end=z+side*(width/2-.2)
            a.beam((x,z,4.05),(x,end,5.28),.095,'Steel')
            a.beam((x,z,5.97),(x,end,5.28),.095,'Steel')
            a.beam((x,z,5.28),(x,end,5.28),.095,'Steel')
            a.beam((x,z+side*width*.23,5.28),(x,z+side*width*.18,5.69),.065,'Steel')
        for dz in [-width*.4,0,width*.4]:
            a.box(((x0+x1)/2,z+dz,5.8 if dz==0 else 5.39),(x1-x0,.065,.085),'DarkSteel') if x==int(x0)+3 else None
        if x%18==int(x0+3)%18:
            a.box((x+.8,z,5.04),(1.25,.20,.09),'White')
            a.pipe((x,z,5.2),(x,z,4.65),.025,'DarkSteel')
            a.box((x,z,4.63),(1.06,.13,.035),'DarkSteel')
    a.finish()


def furniture(z0,z1):
    a=Assembly('Benches_drinking_water_and_lighting')
    z=(z0+z1)/2
    for x in range(-264,277,24):
        if -78 < x < -44: continue  # footbridge stair circulation
        for side in [-1,1]:
            for j in range(5): a.box((x,z+side*.6+j*.09,1.78),(2.1,.065,.055),'Steel')
            for j in range(4): a.box((x,z+side*.6,1.9+j*.12),(2.1,.06,.075),'Steel')
            for dx in [-.82,.82]:
                a.beam((x+dx,z+side*.6,1.31),(x+dx,z+side*.6,2.28),.075,'DarkSteel')
                a.box((x+dx,z+side*.78,1.33),(.12,.6,.06),'DarkSteel')
        for dz,mat in [(-.6,'Blue'),(.2,'Green')]:
            a.box((x+3,z+dz,1.74),(.45,.45,.85),mat)
            a.box((x+3,z+dz,2.18),(.51,.51,.08),'DarkSteel')
    for x in [-218,-122,116,236]:
        a.box((x,z,1.8),(2.4,.95,1.0),'TileWhite')
        for j in range(8):
            for k in range(3):
                a.box((x-1.05+j*.3,z+.485,1.4+k*.3),(.28,.015,.28),'TileBlue' if (j+k)%2 else 'TileWhite')
        a.box((x,z,2.32),(2.5,1.0,.09),'Coping')
        for dx in [-.8,0,.8]:
            a.pipe((x+dx,z+.3,2.35),(x+dx,z+.3,2.57),.021,'Steel')
            a.pipe((x+dx,z+.3,2.57),(x+dx,z+.53,2.57),.021,'Steel')
    for x in range(-285,300,30):
        a.box((x,z,1.5),(.38,.38,.4),'Concrete')
        a.pipe((x,z,1.5),(x,z,7.25),.055,'Steel')
        a.beam((x,z-1.5,7.25),(x,z+1.5,7.25),.07,'Steel')
        for side in [-1,1]: a.box((x,z+side*1.3,7.22),(.3,.65,.10),'White')
    a.finish(.014)


def footbridge(zs, colour):
    a=Assembly('Covered_FOB_with_connected_platform_stairs')
    x=-64; lo=min(zs); hi=max(zs); deck=8.25
    a.box((x,(lo+hi)/2,deck),(3.6,hi-lo+3.2,.3),'Concrete')
    for dx in [-1.72,1.72]:
        a.box((x+dx,(lo+hi)/2,deck-.27),(.18,hi-lo+3.2,.6),'Maroon')
        for z in range(int(lo)-1,int(hi)+2,2):
            a.beam((x+dx,z,deck),(x+dx,z,deck+2.45),.075,'White')
        for h in [.5,.95,1.35]: a.beam((x+dx,lo-1.6,deck+h),(x+dx,hi+1.6,deck+h),.05,'White')
    corrugated(a,x-2.1,x,lo-2,hi+2,deck+2.75,deck+2.75,colour)
    corrugated(a,x,x+2.1,lo-2,hi+2,deck+2.75,deck+2.75,colour)
    for z in zs:
        for dx in [-1.45,1.45]:
            a.beam((x+dx,z,1.3),(x+dx,z,deck),.21,'Steel')
        # A real, connected 40-riser flight, 175 mm rise and 300 mm going.
        for i in range(40):
            xx=x+1.8+(i+.5)*.30; h=deck-(i+1)*(deck-SURFACE)/40
            a.box((xx,z,h-.08),(.31,2.6,.16),'Concrete')
        for side in [-1,1]:
            zz=z+side*1.35
            a.beam((x+1.8,zz,deck-.22),(x+13.8,zz,1.1),.17,'Maroon')
            for i in range(0,41,4):
                xx=x+1.8+i*.30; h=deck-i*(deck-SURFACE)/40
                a.beam((xx,zz,h),(xx,zz,h+2.4),.065,'White')
            for h in [.5,1.0,1.3]: a.beam((x+1.8,zz,deck+h),(x+13.8,zz,SURFACE+h),.045,'White')
        # Roof panels follow the stair slope.
        for i in range(40):
            xx=x+1.8+i*.3; h=deck-i*(deck-SURFACE)/40+2.55
            corrugated(a,xx,xx+.3,z-1.7,z+1.7,h,h,colour)
    a.finish()


def building(z, variant):
    a=Assembly('Station_building_'+variant)
    outward=-1 if z<0 else 1
    front=z+outward*7
    width=84 if variant=='thanjavur' else (72 if variant=='mayiladuthurai' else 66)
    a.box((0,z,.65),(width+4,17,1.3),'Concrete')
    # Bays have recessed doors and actual masonry piers, not a featureless box.
    a.box((0,z,6.3),(width,13,1.8),'Cream')
    for x in range(-int(width/2)+3,int(width/2),6):
        a.box((x,z,3.2),(.7,13,4),'Ivory')
        if abs(x+2.7)<5: continue  # open booking-hall passage under the central portico
        a.box((x+2.7,z,1.72),(4.7,12,.85),'Cream')
        for side in [-1,1]:
            face=z+side*6.52
            a.box((x+2.7,face,3.5),(3.8,.12,2.8),'DarkSteel')
            a.box((x+2.7,face+side*.08,3.5),(3.45,.05,2.5),'Shadow' if variant=='thanjavur' else 'Glass')
            for dx in [-1.3,-.65,0,.65,1.3]: a.box((x+2.7+dx,face+side*.12,3.5),(.04,.04,2.65),'Steel')
            a.box((x+2.7,face+side*.55,5.12),(4.5,1.2,.14),'Maroon')
            a.box((x+2.7,face+side*.1,5.8),(3.8,.09,.55),'Paver')
            if variant=='thanjavur':
                # Segmental fanlights and raised plaster surrounds seen at TJ.
                arc=[xyz((x+2.7+1.85*math.cos(i*math.pi/24),face+side*.16,5.2+.75*math.sin(i*math.pi/24))) for i in range(25)]
                a.p.tube(arc,.09,'Sandstone',8)
                for j in range(7):
                    dx=(j-3)*.46
                    a.box((x+2.7+dx,face+side*.15,3.5),(.026,.045,2.65),'Maroon')
                for h in [2.4,2.85,3.3,3.75,4.2,4.65]:
                    a.box((x+2.7,face+side*.18,h),(3.6,.03,.028),'Maroon')
    for h in [1.32,5.35,6.7]: a.box((0,z,h),(width+.6,13.5,.18),'Maroon')
    # Long open trackside verandah and raised roof above the clerestory.
    for x in range(-int(width/2),int(width/2)+1,6):
        a.box((x,z-outward*8.5,3.45),(.24,.24,4.3),'Steel')
    extra=2.1 if variant=='thanjavur' else 0
    if extra:
        for xx in range(-42,43,6):
            for side in [-1,1]:
                a.box((xx,z+side*6.9,7.72),(.13,.13,2.3),'Blue')
        a.box((0,z,7.0),(84,12,.35),'Cream')
    corrugated(a,-width/2-2,width/2+2,z-9,z,6.8+extra,8.0+extra,'RoofRed')
    corrugated(a,-width/2-2,width/2+2,z,z+9,8.0+extra,6.8+extra,'RoofRed')
    if variant=='kumbakonam':
        # KMU's yellow central fascia, blue wings, circular piers and maroon crown.
        for x in [-18,0,18]:
            a.pipe((x,front+outward*8,.2),(x,front+outward*8,5.2),.46,'Ivory')
            a.box((x,front+outward*8,.25),(1.25,1.25,.35),'Concrete')
            for side in [-1,1]:
                # Curved brackets flare from the round pier into the sign beam.
                profile=[(0,4.0),(0,5.15),(2.7,5.15)]
                profile += [(2.7-2.25*math.sin(i*math.pi/16),4.0+1.15*math.cos(i*math.pi/16)) for i in range(1,9)]
                verts=[xyz((x+side*dx,front+outward*8+dz,h)) for dz in [-.48,.48] for dx,h in profile]
                n=len(profile)
                faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
                faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
                a.p.mesh(verts,faces,'Maroon')
        a.box((0,front+outward*8,6.1),(39,1.3,2.0),'Yellow')
        for h in [5.1,7.1]: a.box((0,front+outward*8,h),(40,1.5,.18),'Maroon')
        for x in [-16.2,16.2]:
            a.box((x,front+outward*8.69,6.1),(6.1,.08,1.55),'Blue')
        for x in range(-12,13,3):
            a.box((x,front+outward*8.665,6.1),(.025,.025,1.8),'Sandstone')
        crown=[(-5.4,7.2),(5.4,7.2),(1.85,10.5),(-1.85,10.5)]
        a.p.mesh([xyz((x,front+outward*8+dz,h)) for dz in [-.45,.45] for x,h in crown],
                 [(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],'Maroon')
    elif variant=='thanjavur':
        # The station's characteristic entrance portico and stepped temple tower.
        for x in [-9,-3,3,9]:
            a.box((x,front+outward*5,3.4),(.65,.7,5.2),'DarkSteel')
            for h in [1.5,3,4.5]: a.box((x,front+outward*5,h),(.68,.74,.09),'Maroon')
        a.box((0,front+outward*2.5,6.1),(23,8,.42),'Green')
        for x in range(-11,12):
            a.box((x,front+outward*6.53,6.32),(.76,.12,.48),['Yellow','Blue','Pink'][x%3])
        a.box((0,front+outward*1.5,7.05),(6,3.5,1.4),'Sandstone')
        for i in range(7):
            h=7.8+i*.68; w=5.8-i*.65; d=3.6-i*.3
            a.box((0,front+outward*1.5,h),(w,d,.52),'Sandstone')
            a.box((0,front+outward*1.5,h+.29),(w+.25,d+.18,.12),'Ivory')
            for dx in [-w*.38,0,w*.38]:
                a.box((dx,front+outward*(1.5+d/2+.06),h),(.16,.18,.42),'Maroon')
                a.box((dx,front+outward*(1.5+d/2+.16),h+.22),(.4,.24,.095),'Ivory')
                a.pipe((dx,front+outward*(1.5+d/2+.16),h+.28),(dx,front+outward*(1.5+d/2+.16),h+.40),.07,'Sandstone')
        for x in [-.8,0,.8]: a.pipe((x,front+outward*1.5,12.3),(x,front+outward*1.5,12.85),.1,'Sandstone')
        for x in [-23,0,23]: a.box((x,front+.1*outward,9.65),(17,.22,1.1),'Ivory')
    else:
        # Long cream booking block, maroon bands, wide shaded public verandah.
        for x in [-12,-6,0,6,12]: a.box((x,front+outward*4,3.5),(.4,.4,4.5),'Ivory')
        a.box((0,front+outward*2,5.9),(30,6,.24),'Maroon')
        a.box((0,front+outward*4.5,6.6),(24,.3,1.3),'Cream')
    a.finish(.025)
    a=Assembly('Station_forecourt_and_approach')
    a.box((0,front+outward*18,.12),(116,30,.22),'Concrete')
    a.box((0,front+outward*36,.06),(600,8,.12),'Asphalt')
    for x in range(-300,300,8): a.box((x+2,front+outward*36,.126),(4,.12,.012),'Coping')
    for x in range(-54,55): a.box((x,front+outward*29,.25),(.97,.3,.4),'Yellow' if x%2 else 'Black')
    for x in [-49,49]:
        for zz in [front+outward*8,front+outward*23]:
            a.box((x,zz,.34),(3.8,3.8,.62),'Maroon')
            a.box((x,zz,.68),(3.9,3.9,.12),'Coping')
            a.box((x,zz,.76),(3.3,3.3,.10),'Shadow')
    for x in [-54,54]:
        for i in range(4): a.box((x,z-outward*(7+i*.34),1.15-i*.23),(5,.36,.25),'Concrete')
    # Small recognisable autorickshaws, independently batched in the forecourt.
    for x in [-24,-18,-12,12,18,24]:
        zz=front+outward*24
        auto_rickshaw(a,x,zz,outward)
    a.finish(.025)


def auto_rickshaw(a,x,z,forward):
    def p(dx,dz,h): return (x+dx,z+forward*dz,h)
    a.box(p(0,-.1,.65),(1.4,2.6,.38),'Yellow')
    a.box(p(0,-1.23,1.22),(1.42,.12,1.14),'Yellow')
    a.box(p(0,-1.3,1.36),(.96,.025,.44),'Black')
    for side in [-1,1]:
        a.box(p(side*.68,-.74,1.35),(.055,.9,1.0),'Black')
        a.box(p(side*.702,-.74,1.35),(.016,.64,.5),'Glass')
        a.beam(p(side*.62,.62,.84),p(side*.57,.36,1.79),.06,'Black')
        a.pipe(p(side*.57,-.80,.36),p(side*.77,-.80,.36),.245,'Tyre')
        a.pipe(p(side*.775,-.80,.36),p(side*.79,-.80,.36),.13,'Steel')
        a.box(p(side*.60,1.13,.79),(.20,.04,.15),'White')
    # Narrow rounded front apron, raked glazed windscreen and canvas canopy.
    a.box(p(0,1.03,.80),(1.1,.33,.54),'Yellow')
    a.beam(p(0,.7,.85),p(0,1.06,.34),.12,'Steel')
    a.pipe(p(-.12,1.0,.30),p(.12,1.0,.30),.245,'Tyre')
    vertices=[xyz(p(dx,dz,h)) for dx,dz,h in [(-.57,.65,1.08),(.57,.65,1.08),(.54,.34,1.79),(-.54,.34,1.79)]]
    a.p.mesh(vertices,[(0,1,2,3),(3,2,1,0)],'Glass')
    roof=[]
    for dz in [-1.32,.52]:
        for i in range(13):
            t=i*math.pi/12
            roof.append(xyz(p(.74*math.cos(t),dz,1.79+.19*math.sin(t))))
    a.p.mesh(roof,[(i,i+1,i+14,i+13) for i in range(12)],'Black')
    a.box(p(0,.06,1.05),(1.1,.4,.15),'Black')
    a.box(p(0,1.21,.57),(.4,.025,.14),'Yellow')
    for side in [-1,1]: a.pipe(p(side*.29,.5,1.07),p(side*.29,.43,1.23),.018,'Steel')


def kiosk(z):
    a=Assembly('Tea_stall_and_bookstall')
    for x,mat in [(62,'Maroon'),(-104,'Green')]:
        a.box((x,z,2.5),(5,2.6,2.4),'Cream')
        for side in [-1,1]:
            a.box((x,z+side*1.31,2.68),(4.3,.07,1.3),'Black')
            a.box((x,z+side*1.45,2.18),(4.4,.5,.12),'Steel')
            a.box((x,z+side*1.36,3.83),(5,.09,.6),mat)
        a.box((x,z,4.15),(5.8,3.2,.16),mat)
        for j in range(12):
            a.box((x-1.9+j*.32,z+1.32,2.43),(.16,.18,.35),['Blue','Yellow','Green'][j%3])
    a.finish(.012)


def build(variant, platforms, bz, export_name=None):
    export_name = export_name or variant
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    for col in list(bpy.data.collections): bpy.data.collections.remove(col)
    b.M={}; b.GROUPS=[]
    b.ASSET=bpy.data.collections.new('SR_'+variant); bpy.context.scene.collection.children.link(b.ASSET)
    b.ROOT=b.empty('Station_'+variant); palette()
    for i,(z0,z1) in enumerate(platforms):
        platform(z0,z1,i+1); furniture(z0,z1); z=(z0+z1)/2
        canopy(z,z1-z0-1.2,-245,-82,'RoofBlue' if variant=='kumbakonam' else 'RoofGrey','Canopy_west_%d'%i)
        canopy(z,z1-z0-1.2,-44,245,'RoofBlue' if variant=='kumbakonam' else ('RoofRedStripe' if variant=='mayiladuthurai' else 'RoofRed'),'Canopy_east_%d'%i)
        kiosk(z)
    footbridge([(p[0]+p[1])/2 for p in platforms]+[bz], 'RoofBlue' if variant=='kumbakonam' else 'RoofGrey')
    building(bz,variant)
    b.ROOT['reference_station']=variant; b.ROOT['platform_length_m']=600.0; b.ROOT['platform_surface_world_m']=SURFACE
    bpy.ops.object.select_all(action='DESELECT')
    for ob in b.ASSET.objects: ob.select_set(True)
    bpy.context.view_layer.objects.active=b.ROOT
    bpy.ops.export_scene.gltf(filepath=os.path.join(MODELS,export_name+'.glb'),export_format='GLB',use_selection=True,export_apply=True,export_extras=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,export_name+'.blend'),compress=True)
    print('STATION_COMPLETE',export_name,len(b.ASSET.objects),flush=True)


if __name__=='__main__':
    if not bpy.app.background: raise RuntimeError('Background Blender only')
    os.makedirs(OUT,exist_ok=True); os.makedirs(MODELS,exist_ok=True)
    open(os.path.join(OUT,'.gdignore'),'w').close()
    if '--yards' in sys.argv:
        for variant,bz in [('kumbakonam',-36),('mayiladuthurai',-36),('thanjavur',36)]:
            build(variant,[(-19.1,-10.9),(10.9,19.1)],bz,variant+'_yard')
    else:
        build('kumbakonam',[(-10.1,-1.9),(-25.9,-13.9)],-34)
        build('mayiladuthurai',[(1.9,10.1),(-13.9,-1.9)],-22)
        build('thanjavur',[(1.9,13.9)],22)
