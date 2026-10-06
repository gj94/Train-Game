"""Original small-town landmarks; invented designs, not replicas of sacred sites."""
import math
from build_scenery import Geometry, IVORY, CONCRETE, STEEL

def ellipsoid(g,p,size,kind,colour,segments=12,rings=7):
    vertices=[]
    for j in range(rings+1):
        lat=-math.pi/2+j*math.pi/rings
        for i in range(segments):
            angle=i*math.tau/segments
            vertices.append((p[0]+math.cos(lat)*math.cos(angle)*size[0],p[1]+math.sin(lat)*size[1],p[2]+math.cos(lat)*math.sin(angle)*size[2]))
    faces=[]
    for j in range(rings):
        for i in range(segments):
            a=j*segments+i; b=j*segments+(i+1)%segments
            faces.append((a,a+segments,b+segments,b))
    g.mesh(vertices,faces,kind,colour,True)

def niche(g,x,y,z,width,height,colour):
    # Deep arched niche with moulded surrounds; ornament remains abstract.
    g.box((x,y+height*.43,z),(width*.70,height*.86,.07),'detail',(.13,.15,.13))
    for side in [-1,1]:
        g.box((x+side*width*.43,y+height*.40,z-.08),(.13,height*.80,.20),'masonry',IVORY)
        g.box((x+side*width*.43,y+.11,z-.12),(.23,.20,.25),'masonry',colour)
        g.box((x+side*width*.43,y+height*.75,z-.12),(.22,.15,.24),'masonry',colour)
    for step in range(9):
        angle=step*math.pi/8
        g.box((x+math.cos(angle)*width*.43,y+height*.78+math.sin(angle)*width*.43,z-.10),(.16,.17,.22),'masonry',IVORY)
    # A carved floral rosette, without reproducing a particular deity or statue.
    for petal in range(8):
        a=petal*math.tau/8
        ellipsoid(g,(x+math.cos(a)*width*.17,y+height*.48+math.sin(a)*width*.17,z-.17),(.075,.11,.055),'masonry',colour,8,4)
    ellipsoid(g,(x,y+height*.48,z-.20),(.075,.08,.04),'masonry',(.62,.49,.24),8,4)

def temple_gateway():
    g=Geometry('temple_gateway')
    stone=(.44,.42,.35)
    for x in [-2.75,2.75]:
        g.box((x,2.05,0),(2.1,4.1,4.8),'masonry',(.63,.61,.52))
        for y in [.20,.52,1.30,2.12,3.35,3.90]: g.box((x,y,0),(2.22,.15,4.95),'masonry',stone)
        for side in [-1,1]:
            for z in [-2.45,2.45]:
                g.box((x+side*.73,2.03,z),(.25,3.70,.22),'masonry',IVORY)
    g.box((0,4.30,0),(7.75,.46,5.15),'masonry',stone)
    for layer in range(5):
        y=4.60+layer*1.91; width=7.6-layer*.85; depth=4.7-layer*.40
        colour=[(.49,.59,.57),(.61,.48,.43),(.62,.60,.47),(.46,.53,.59),(.60,.53,.61)][layer]
        g.box((0,y+.68,0),(width,1.36,depth),'masonry',colour)
        for height,extra in [(0,.26),(.18,.44),(1.39,.38),(1.55,.55),(1.70,.34)]:
            g.box((0,y+height,0),(width+extra,.14,depth+extra*.7),'masonry',IVORY if height<1.5 else colour)
        bays=max(3,7-layer)
        for facing in [0,math.pi]:
            with g.at(angle=facing):
                for i in range(bays): niche(g,-width*.43+(i+.5)*width*.86/bays,y+.26,-depth/2-.08,width*.74/bays,.93,colour)
        for side in [-1,1]:
            for z in [-depth*.30,depth*.30]:
                g.box((side*(width/2+.11),y+.73,z),(.20,1.23,.20),'masonry',IVORY)
    y=14.15
    g.box((0,y+.22,0),(3.7,.35,2.95),'masonry',(.54,.56,.50))
    # Barrel-like ridge with stepped end finials.
    for i in range(15):
        angle=i*math.pi/14
        g.box((0,y+.30+math.sin(angle)*.85,math.cos(angle)*1.45),(3.45,.18,.32),'masonry',(.56,.46,.37))
    for x in [-1.4,-.7,0,.7,1.4]:
        g.cylinder((x,y+1.03,0),(x,y+1.22,0),.20,'masonry',(.59,.46,.23),12)
        ellipsoid(g,(x,y+1.41,0),(.16,.22,.16),'masonry',(.64,.52,.28))
        g.cylinder((x,y+1.55,0),(x,y+1.80,0),.045,'metal',(.57,.45,.20),8,.009)
    return g

def temple_hall():
    g=Geometry('temple_hall'); stone=(.51,.49,.42)
    g.box((0,.35,0),(13.8,.70,19.5),'masonry',stone)
    for x in [-5.8,5.8]:
        for z in [-8,-4,0,4,8]:
            g.box((x,2.55,z),(.55,3.9,.55),'masonry',IVORY)
            for y in [.82,1.15,3.75,4.1]: g.box((x,y,z),(.79,.22,.79),'masonry',stone)
    g.box((0,2.3,6),(10.8,3.2,5.1),'masonry',(.59,.59,.49))
    g.box((0,2.20,3.42),(2.30,2.75,.07),'wood',(.12,.075,.032))
    for level in range(7):
        g.box((0,4.3+level*.33,0),(14.4-level*.50,.33,20.0-level*.50),'masonry',(.57,.52,.42))
    for step in range(6):
        g.box((0,.08+step*.08,-10.95+step*.22),(4.6,.16+step*.16,.46),'masonry',stone)
    return g

def telecom_mast():
    g=Geometry('telecom_mast')
    g.box((0,.22,0),(4.1,.44,4.1),'masonry',CONCRETE)
    for side in range(3):
        a=side*math.tau/3; b=(side+1)*math.tau/3
        for level in range(12):
            y=level*2.2; r=1.1-y*.019; r2=1.1-(y+2.2)*.019
            p=(math.cos(a)*r,y,math.sin(a)*r); q=(math.cos(a)*r2,y+2.2,math.sin(a)*r2)
            end=(math.cos(b)*r2,y+2.2,math.sin(b)*r2)
            paint=(.60,.61,.57) if level%4<2 else (.53,.20,.12)
            g.beam(p,q,.11,'metal',paint)
            g.beam(p,end,.055,'metal',paint)
            g.beam(q,end,.055,'metal',paint)
        with g.at(angle=a):
            g.box((0,24.6,-1.08),(.37,2.40,.18),'detail',(.71,.71,.64))
            g.box((.53,22.7,-.86),(.31,1.85,.18),'detail',(.70,.69,.63))
            g.cylinder((0,20.5,-.8),(0,20.5,-1.04),.46,'metal',(.64,.67,.64),20)
    for y in range(24):
        for x in [-.21,.21]: g.beam((x,y,.65),(x,y+1,.65),.03,'metal',STEEL)
        for yy in [.2,.5,.8]: g.beam((-.23,y+yy,.65),(.23,y+yy,.65),.03,'metal',STEEL)
    return g

FACTORIES=[temple_gateway,temple_hall,telecom_mast]
