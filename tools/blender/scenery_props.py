"""Original street/railside props, built through build_scenery.py in background."""
import math, random
from mathutils import Vector, Matrix
from build_scenery import Geometry, IVORY, CONCRETE, DARK, STEEL, GLASS, WOOD

def wheel(g,x,y,z,r=.31,width=.17):
    # Rounded rubber casing, a recessed steel rim and separate hub/spokes.
    vertices=[]; segments=24; rings=8
    for i in range(segments):
        angle=i*math.tau/segments
        for j in range(rings):
            cross=j*math.tau/rings
            radial=r*(.82+.18*math.cos(cross))
            vertices.append((x+math.sin(cross)*width*.51,y+math.cos(angle)*radial,z+math.sin(angle)*radial))
    faces=[]
    for i in range(segments):
        for j in range(rings):
            faces.append((i*rings+j,((i+1)%segments)*rings+j,((i+1)%segments)*rings+(j+1)%rings,i*rings+(j+1)%rings))
    g.mesh(vertices,faces,'detail',(.018,.021,.019),True)
    g.cylinder((x-width*.30,y,z),(x+width*.30,y,z),r*.67,'metal',(.19,.21,.19),24)
    for side in [-1,1]:
        face=x+side*width*.39
        g.cylinder((face,y,z),(face+side*.012,y,z),r*.19,'metal',(.26,.28,.25),12)
        for i in range(6):
            a=i*math.tau/6
            g.beam((face,y+math.cos(a)*r*.17,z+math.sin(a)*r*.17),(face,y+math.cos(a)*r*.57,z+math.sin(a)*r*.57),r*.080,'metal',(.33,.35,.31))
            g.cylinder((face,y+math.cos(a)*r*.25,z+math.sin(a)*r*.25),(face+side*.018,y+math.cos(a)*r*.25,z+math.sin(a)*r*.25),r*.030,'metal',(.07,.09,.08),6)

def body_loft(g,sections,colour,kind='metal',smooth=False):
    # z, half-width, lower sill, shoulder; bevelled octagonal sections.
    vertices=[]
    for z,w,bottom,top in sections:
        cut=min(.09,(top-bottom)*.22)
        vertices.extend([(-w+cut,bottom,z),(-w,bottom+cut,z),(-w,top-cut,z),(-w+cut,top,z),(w-cut,top,z),(w,top-cut,z),(w,bottom+cut,z),(w-cut,bottom,z)])
    faces=[tuple(range(8)),tuple(reversed(range((len(sections)-1)*8,len(sections)*8)))]
    for row in range(len(sections)-1):
        for i in range(8):
            a=row*8+i;b=row*8+(i+1)%8
            faces.append((a,a+8,b+8,b))
    g.mesh(vertices,faces,kind,colour,smooth)

def cabin(g,width,length,height,base,kind='metal',colour=(.39,.43,.44)):
    w=width/2; z=length/2; h=base+height
    verts=[(-w,base,-z),(w,base,-z),(w,base,z),(-w,base,z),(-w*.83,h,-z*.63),(w*.83,h,-z*.63),(w*.86,h,z*.75),(-w*.86,h,z*.75)]
    faces=[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
    g.mesh(verts,[tuple(reversed(face)) for face in faces],kind,colour)
    # Windscreens project a few millimetres above the sloping body surfaces.
    g.mesh([(-w*.83,base+.16,-z-.008),(w*.83,base+.16,-z-.008),(w*.74,h-.09,-z*.63-.008),(-w*.74,h-.09,-z*.63-.008)],[(3,2,1,0)],'glass',GLASS)
    g.mesh([(-w*.80,base+.18,z+.008),(-w*.74,h-.10,z*.75+.008),(w*.74,h-.10,z*.75+.008),(w*.80,base+.18,z+.008)],[(3,2,1,0)],'glass',GLASS)
    for side in [-1,1]:
        for a,b in [(-.79,-.06),(.03,.78)]:
            g.mesh([(side*(w+.01),base+.12,z*a),(side*(w+.01),base+.12,z*b),(side*(w*.85+.018),h-.10,z*b*.79),(side*(w*.85+.018),h-.10,z*a*.79)],[(0,1,2,3),(3,2,1,0)],'glass',GLASS)

def hatchback():
    g=Geometry('hatchback'); paint=(.48,.49,.43)
    samples={-1.93,-1.80,-1.62,-.73,.50,1.74,1.93}
    for centre in [-1.14,1.20]:
        for i in range(13): samples.add(centre-.37+(.74*i/12))
    sections=[]
    for z in sorted(samples):
        w=.83-min(.10,max(0,abs(z)-1.64)*.30)
        top=.93-min(.12,max(0,abs(z)-1.5)*.22)
        bottom=.40
        for centre in [-1.14,1.20]:
            if abs(z-centre)<.365: bottom=max(bottom,.34+math.sqrt(.37**2-(z-centre)**2))
        sections.append((z,w,bottom,top))
    body_loft(g,sections,paint,smooth=True)
    cabin(g,1.59,2.24,.65,.88,colour=paint)
    # Roof curvature and door shut-lines break the monolithic block silhouette.
    body_loft(g,[(-.66,.55,1.49,1.52),(-.52,.64,1.50,1.56),(.43,.64,1.50,1.56),(.78,.52,1.46,1.50)],paint,smooth=True)
    for x in [-.77,.77]:
        for z in [-1.14,1.2]: wheel(g,x,.34,z,.32,.19)
        g.box((x*.78,.76,-1.93),(.39,.14,.045),'glass',(.55,.58,.47))
        g.box((x*.87,.75,1.915),(.20,.20,.045),'glass',(.32,.035,.018))
        g.box((x*1.08,.90,.0),(.027,.035,.17),'metal',(.20,.22,.19))
        g.box((x*1.19,1.12,-.90),(.17,.12,.21),'metal',paint)
        for z in [-.75,.18,1.02]: g.beam((x*1.08,.48,z),(x*1.08,.93,z),.011,'detail',(.10,.115,.10))
        g.beam((x*1.08,.48,-.73),(x*1.08,.48,1.0),.014,'detail',(.12,.13,.11))
    for z in [-1.94,1.94]:
        body_loft(g,[(z-.026,.73,.42,.57),(z,.77,.42,.57),(z+.026,.73,.42,.57)],(.10,.115,.10),'detail')
        g.box((0,.61,z*1.025),(.48,.12,.02),'sign',IVORY)
    for y in [.69,.73,.77]: g.box((0,y,-1.953),(.58,.018,.022),'detail',DARK)
    for side in [-1,1]: g.beam((side*.13,.96,-1.13),(side*.52,1.01,-1.07),.014,'detail',DARK)
    g.cylinder((.58,1.53,.55),(.58,1.94,.72),.009,'detail',DARK,6,.004)
    return g

def auto_rickshaw():
    g=Geometry('auto_rickshaw'); yellow=(.67,.49,.095); green=(.08,.25,.14)
    body_loft(g,[(-1.28,.45,.44,.59),(-1.10,.61,.41,.62),(.97,.65,.42,.65),(1.25,.55,.48,.67)],green,smooth=True)
    body_loft(g,[(-1.35,.36,.63,.98),(-1.25,.54,.60,1.13),(-1.05,.60,.60,1.20),(-.87,.60,.62,1.20)],yellow,smooth=True)
    for side in [-1,1]:
        g.box((side*.62,.87,.80),(.07,.53,.83),'metal',green)
        g.box((side*.59,.44,-.08),(.17,.10,.90),'metal',(.13,.16,.14))
    g.box((0,.73,.58),(1.12,.18,.72),'detail',DARK)
    g.box((0,1.06,.93),(1.12,.53,.15),'detail',DARK)
    for x in [-.64,.64]:
        wheel(g,x,.31,.71,.29,.14)
        for z in [-.64,1.12]: g.cylinder((x*.91,.89,z),(x*.86,1.82,z),.028,'metal',STEEL,6)
    wheel(g,0,.31,-.94,.29,.13)
    # Curved vinyl hood, stitched ribs and a rear curtain with glazed opening.
    vertices=[]
    for inner in [False,True]:
        for z in [-.88,1.24]:
            for i in range(13):
                a=i*math.pi/12
                vertices.append((math.cos(a)*(.637 if inner else .66),1.78+math.sin(a)*.28-(.025 if inner else 0),z))
    faces=[]
    for i in range(12):
        faces.extend([(i+1,i+14,i+13,i),(i+26,i+39,i+40,i+27),(i,i+26,i+27,i+1),(i+13,i+14,i+40,i+39)])
    faces.extend([(0,13,39,26),(12,38,51,25)])
    g.mesh(vertices,faces,'detail',(.035,.043,.035),True)
    for x in [-.51,0,.51]: g.beam((x,2.02-abs(x)*.17,-.87),(x,2.02-abs(x)*.17,1.24),.012,'detail',(.10,.12,.09))
    g.box((0,1.16,1.235),(1.24,.60,.055),'detail',(.038,.046,.038))
    g.box((0,1.65,1.235),(1.24,.37,.055),'detail',(.038,.046,.038))
    g.box((0,1.64,1.27),(.69,.25,.025),'glass',GLASS)
    g.mesh([(-.52,1.11,-1.25),(.52,1.11,-1.25),(.56,1.79,-.87),(-.56,1.79,-.87)],[(3,2,1,0)],'glass',GLASS)
    g.box((0,1.05,-1.30),(1.16,.14,.09),'metal',yellow)
    g.cylinder((0,.89,-1.36),(0,.89,-1.40),.14,'glass',(.72,.68,.46),12)
    g.beam((-.25,1.19,-.69),(.25,1.19,-.69),.034,'metal',DARK)
    for x in [-.70,.70]: g.box((x,1.59,-.77),(.13,.20,.065),'glass',GLASS)
    g.box((0,.5,-1.35),(.82,.14,.08),'detail',DARK)
    g.box((0,.71,-.37),(.40,.13,.43),'detail',(.04,.045,.037))
    # A seated driver is visible through the open side, without extra runtime nodes.
    from scenery_people import head, oval_limb
    head(g,(0,1.57,-.29))
    oval_limb(g,(0,.93,-.29),(0,1.37,-.29),.15,.17,'detail',(.50,.47,.34))
    for side in [-1,1]:
        oval_limb(g,(side*.15,1.30,-.30),(side*.20,1.17,-.67),.050,.035,'detail',(.30,.17,.105))
        oval_limb(g,(side*.11,.96,-.29),(side*.16,.66,-.72),.077,.062,'detail',(.08,.09,.07))
    return g

def local_bus():
    g=Geometry('local_bus'); paint=(.29,.40,.31); cream=(.72,.71,.58)
    g.box((0,1.10,0),(2.46,1.35,10.15),'metal',paint)
    g.box((0,2.29,.03),(2.42,1.06,9.90),'metal',cream)
    g.box((0,2.93,.03),(2.45,.23,9.97),'metal',cream)
    for side in [-1,1]:
        for z in [-3.46,3.32]: wheel(g,side*1.11,.53,z,.51,.27)
        for z in [-3.60,-2.48,-1.36,-.24,.88,2.0,3.12,4.24]:
            g.box((side*1.22,2.24,z),(.022,.79,.98),'glass',GLASS)
            g.box((side*1.24,2.22,z),(.018,.025,.98),'metal',IVORY)
        g.box((side*1.244,1.67,0),(.012,.10,9.8),'detail',(.70,.59,.32))
        g.box((side*1.34,2.50,-4.77),(.18,.35,.19),'glass',GLASS)
    for z in [-5.095,5.085]:
        g.box((0,2.20,z),(2.14,.91,.026),'glass',GLASS)
        g.box((0,2.82,z),(1.85,.28,.028),'sign',(.065,.10,.08))
        g.box((0,.74,z*1.012),(2.28,.16,.16),'metal',(.16,.19,.17))
        g.box((0,1.08,z*1.012),(.62,.18,.026),'sign',(.69,.52,.10))
    for x in [-.93,.93]: g.box((x,1.24,-5.12),(.36,.23,.028),'glass',(.68,.67,.50))
    g.box((-1.25,1.62,-3.89),(.032,1.99,.82),'detail',DARK)
    for y in [.57,.82,1.07]: g.box((-1.10,y,-3.89),(.37,.09,.79),'metal',(.28,.31,.27))
    for x in [-.15,.15]: g.box((x,2.20,-5.12),(.035,.92,.032),'metal',cream)
    return g

def goods_lorry():
    g=Geometry('goods_lorry'); blue=(.18,.32,.37); load=(.43,.30,.15)
    g.box((0,.71,0),(2.22,.25,7.06),'metal',DARK)
    with g.at((0,0,-2.36)):
        g.box((0,1.12,0),(2.24,1.13,2.22),'metal',blue)
        cabin(g,2.21,2.16,1.0,1.39,colour=blue)
        for x in [-.85,.85]: g.box((x,1.02,-1.14),(.32,.23,.035),'glass',(.72,.70,.57))
        g.box((0,.86,-1.18),(.92,.30,.04),'detail',DARK)
        g.box((0,.59,-1.25),(2.26,.15,.13),'metal',STEEL)
    g.box((0,1.02,1.05),(2.24,.28,4.50),'wood',load)
    for x in [-1.1,1.1]:
        for y in [1.28,1.57,1.86,2.15]: g.box((x,y,1.07),(.09,.24,4.55),'wood',load)
        for z in [-1.09,.05,1.20,2.33,3.34]: g.box((x*1.05,1.70,z),(.12,1.49,.13),'metal',(.21,.28,.22))
        for z in [-2.70,2.11,3.04]: wheel(g,x,.48,z,.46,.23)
    g.box((0,1.72,3.38),(2.25,1.26,.10),'wood',load)
    # Covered sacks: a gently peaked canvas load, secured with visible ropes.
    g.mesh([(-1.05,2.24,-1.06),(1.05,2.24,-1.06),(1.05,2.24,3.36),(-1.05,2.24,3.36),(-.68,2.89,-.92),(.68,2.89,-.92),(.68,2.89,3.20),(-.68,2.89,3.20)],[(0,1,5,4),(4,5,6,7),(1,2,6,5),(3,7,6,2),(0,4,7,3)],'detail',(.24,.30,.19))
    for z in [-.65,.55,1.75,2.95]:
        for side in [-1,1]: g.beam((side*1.12,1.17,z),(side*.68,2.92,z),.028,'detail',(.44,.38,.24))
        g.beam((-.68,2.92,z),(.68,2.92,z),.028,'detail',(.44,.38,.24))
    return g

def motorcycle():
    g=Geometry('motorcycle')
    for z in [-.71,.71]: wheel(g,0,.31,z,.30,.09)
    for x in [-.09,.09]:
        g.beam((x,.31,-.71),(x,.95,-.38),.045,'metal',STEEL)
        g.beam((x,.31,.71),(x,.60,.15),.037,'metal',DARK)
    g.box((0,.53,.03),(.34,.36,.39),'metal',(.19,.20,.18))
    g.box((0,.87,-.21),(.35,.28,.48),'metal',(.22,.13,.11),Matrix.Rotation(.16,3,'X'))
    g.box((0,.88,.37),(.32,.11,.72),'detail',DARK)
    g.beam((-.37,1.02,-.42),(.37,1.02,-.42),.031,'metal',DARK)
    g.cylinder((0,.91,-.61),(0,.91,-.69),.105,'glass',(.68,.66,.53),12)
    g.box((.23,.38,.46),(.13,.13,.65),'metal',(.40,.41,.36))
    for x in [-.36,.36]: g.box((x,1.25,-.39),(.14,.09,.025),'glass',GLASS)
    g.beam((-.13,.42,.06),(-.28,.015,.11),.028,'metal',DARK)
    return g

def motorcycle_rider():
    from scenery_people import person
    from scenery_landmarks import ellipsoid
    g=motorcycle(); g.name='motorcycle_rider'
    with g.at((0,.32,.20)):
        person(g,colour=(.27,.34,.31),pose='rider',bag=False)
        ellipsoid(g,(0,1.27,.005),(.121,.122,.116),'detail',(.042,.050,.048),16,10)
        ellipsoid(g,(0,1.245,-.089),(.093,.060,.047),'glass',(.07,.10,.105),12,6)
    return g

def produce_cart():
    from scenery_landmarks import ellipsoid
    g=Geometry('produce_cart'); frame=(.13,.22,.16); wood=(.30,.185,.09)
    for x in [-.72,.72]:
        wheel(g,x,.29,.18,.28,.10)
        g.beam((x,.21,-.48),(x,.92,-.48),.05,'metal',frame)
        for z in [-.48,.48]: g.beam((x,.53,z),(x,2.33,z),.032,'metal',frame)
    g.box((0,.87,0),(1.65,.14,1.15),'wood',wood)
    for x in [-.70,-.35,0,.35,.70]: g.box((x,.964,0),(.31,.055,1.06),'wood',(.38,.25,.14))
    for side in [-1,1]: g.box((side*.82,1.09,0),(.035,.30,1.13),'wood',wood)
    for z in [-.55,.55]: g.box((0,1.09,z),(1.65,.30,.035),'wood',wood)
    g.box((0,2.35,0),(2.10,.07,1.70),'detail',(.18,.29,.23),Matrix.Rotation(-.07,3,'X'))
    for x in [-.82,-.42,-.02,.38,.78]: g.box((x,2.393,0),(.19,.012,1.71),'detail',(.64,.61,.43),Matrix.Rotation(-.07,3,'X'))
    g.box((0,2.18,-.82),(2.10,.29,.024),'detail',(.21,.32,.25))
    for row in range(4):
        for col in range(12):
            x=-.72+col*.13; z=-.36+row*.22
            colour=(.42,.055,.020) if col<4 else ((.29,.36,.035) if col<8 else (.57,.32,.035))
            ellipsoid(g,(x,1.16+(row%2)*.025,z),(.064,.064,.063),'detail',colour,8,5)
    g.beam((-.65,.95,.48),(-.65,.93,1.10),.035,'metal',frame)
    g.beam((.65,.95,.48),(.65,.93,1.10),.035,'metal',frame)
    return g

def bus_shelter():
    g=Geometry('bus_shelter')
    g.box((0,.14,0),(6.8,.28,2.6),'masonry',CONCRETE)
    for x in [-3.0,3.0]:
        g.box((x,1.6,.85),(.18,3.2,.18),'metal',(.20,.28,.27))
        g.box((x,1.2,0),(.12,2.4,1.9),'masonry',(.55,.52,.42))
    g.box((0,1.34,1.05),(6.2,2.2,.16),'masonry',(.58,.60,.51))
    g.box((0,3.12,0),(7.1,.11,3.1),'metal',(.24,.35,.39),Matrix.Rotation(-.08,3,'X'))
    g.box((0,2.83,-1.52),(6.9,.39,.10),'sign',(.16,.29,.29))
    for x in [-2.3,0,2.3]:
        g.box((x,.74,.50),(1.92,.13,.46),'masonry',IVORY)
        for xx in [-.68,.68]: g.box((x+xx,.51,.50),(.16,.49,.32),'masonry',CONCRETE)
    return g

def utility_pole():
    g=Geometry('utility_pole')
    g.cylinder((0,0,0),(0,7.65,0),.16,'masonry',(.49,.50,.45),8,.095)
    for y in [6.42,7.08]:
        g.box((0,y,0),(1.75,.11,.12),'metal',(.18,.23,.21))
        for x in [-.70,0,.70]:
            g.cylinder((x,y+.05,0),(x,y+.34,0),.073,'detail',(.28,.22,.15),8)
            for yy in [.10,.18,.26]: g.cylinder((x,y+yy-.02,0),(x,y+yy+.02,0),.10,'detail',(.30,.24,.17),8)
    g.box((.20,3.38,0),(.43,.67,.29),'metal',(.43,.45,.41))
    g.beam((0,6.04,0),(.84,6.29,-.74),.038,'metal',STEEL)
    g.box((.85,6.29,-.78),(.28,.07,.61),'detail',(.65,.66,.60))
    return g

def transformer():
    g=Geometry('transformer')
    g.box((0,.26,0),(3.3,.52,2.7),'masonry',CONCRETE)
    g.box((0,1.24,0),(1.60,1.47,1.25),'metal',(.25,.32,.29))
    for side in [-1,1]:
        for i in range(10): g.box((side*1.02,1.22,-.55+i*.12),(.44,1.22,.045),'metal',(.26,.33,.29))
    for x in [-.5,0,.5]:
        g.cylinder((x,1.97,0),(x,2.63,0),.07,'detail',(.34,.22,.13),8)
        for y in [2.08,2.21,2.34,2.47]: g.cylinder((x,y-.024,0),(x,y+.024,0),.14,'detail',(.31,.23,.14),8)
    g.cylinder((-.75,2.12,.61),(.75,2.12,.61),.22,'metal',(.26,.33,.29),12)
    g.box((0,1.30,-.64),(.55,.36,.02),'sign',(.65,.50,.06))
    return g

def tea_kiosk():
    g=Geometry('tea_kiosk')
    g.box((0,1.24,.13),(3.7,2.48,2.4),'metal',(.25,.38,.32))
    g.box((0,1.64,-1.095),(3.24,.91,.028),'detail',DARK)
    g.box((0,1.14,-1.32),(3.55,.13,.57),'wood',(.31,.20,.10))
    g.box((0,2.62,-.16),(4.2,.095,3.5),'metal',(.48,.30,.18),Matrix.Rotation(-.06,3,'X'))
    g.box((0,2.31,-1.15),(3.5,.37,.035),'sign',(.65,.48,.18))
    for x in [-1.15,-.45]: g.cylinder((x,1.21,-1.24),(x,1.62,-1.24),.18,'metal',(.50,.53,.50),12)
    for x in [.30,.56,.82,1.08]: g.cylinder((x,1.22,-1.44),(x,1.34,-1.44),.049,'detail',IVORY,8)
    g.box((1.32,.38,-2.1),(.7,.76,.62),'wood',(.38,.26,.13))
    return g

FACTORIES=[hatchback,auto_rickshaw,local_bus,goods_lorry,motorcycle,motorcycle_rider,produce_cart,bus_shelter,utility_pole,transformer,tea_kiosk]
