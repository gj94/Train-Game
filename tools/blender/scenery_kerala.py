"""Original Kerala coastal details, authored in metres; no reference photo pixels.

See docs/kerala-scenery.md for geographic references and reconstruction limits.
Run through build_scenery.py in BACKGROUND Blender, never an interactive session.
"""
import math
import random
from mathutils import Vector, Matrix
from build_scenery import Geometry, facade, flat_building, tank, balcony, IVORY, CONCRETE, WOOD, DARK


def hip_roof(g, w, d, y, rise, colour=(.49,.25,.13)):
    x=w/2; z=d/2; ridge=max(.25,(w-d)/2)
    v=[(-x,y,-z),(x,y,-z),(x,y,z),(-x,y,z),(-ridge,y+rise,0),(ridge,y+rise,0)]
    # Winding faces upward. Eaves, hip caps and underside close the thin shell.
    g.mesh(v,[(0,4,5,1),(1,5,2),(2,5,4,3),(3,4,0)],'roof',colour)
    for a,b in [(0,1),(1,2),(2,3),(3,0)]:
        g.beam(v[a],v[b],.13,'wood',(.19,.105,.055),.19)
        length=(Vector(v[b])-Vector(v[a])).length
        for i in range(int(length/.32)):
            p=Vector(v[a]).lerp(Vector(v[b]),(i+.5)/max(1,int(length/.32)))
            inward=Vector((0,0,0))-Vector((p.x,0,p.z)); inward.normalize()
            g.cylinder(p+Vector((0,.035,0)),p+inward*.25+Vector((0,.12,0)),.057,'roof',colour,6)
    for a,b in [(0,4),(1,5),(2,5),(3,4),(4,5)]:
        start,end=Vector(v[a]),Vector(v[b]); n=max(1,int((end-start).length/.35))
        for i in range(n):
            g.cylinder(start.lerp(end,i/n)+Vector((0,.06,0)),start.lerp(end,(i+.96)/n)+Vector((0,.06,0)),.09,'roof',(.54,.29,.16),7)


def shell(g,w,d,paint,shop=False):
    g.box((0,.22,0),(w+.35,.44,d+.35),'masonry',CONCRETE)
    doors=[(-w*.27,2.2,0,2.35,'shutter'),(w*.27,2.2,0,2.35,'shutter')] if shop else [(-w*.30,1.25,.85,1.3,'window'),(0,1.10,0,2.12,'door'),(w*.30,1.25,.85,1.3,'window')]
    facade(g,w,.44,-d/2,2.85,doors,paint)
    with g.at(angle=math.pi): facade(g,w,.44,-d/2,2.85,[(-w*.25,1.05,.95,1.15,'window'),(w*.25,1.05,.95,1.15,'window')],paint)
    for s in [-1,1]:
        with g.at((s*w/2,0,0),-s*math.pi/2):
            facade(g,d,.44,0,2.85,[(-d*.22,1.0,.9,1.25,'window'),(d*.22,1.0,.9,1.25,'window')],paint)


def kerala_veranda():
    g=Geometry('kerala_veranda'); w=9;d=6.6
    shell(g,w,d,(.76,.69,.51))
    g.box((0,.34,-4.27),(10.2,.3,2.2),'masonry',(.40,.22,.14))
    # A continuous low, shaded verandah with timber columns and a sitting ledge.
    hip_roof(g,11.2,10.5,3.35,1.85)
    for x in [-4.85,-2.5,2.5,4.85]:
        g.box((x,.56,-5.0),(.35,.22,.35),'masonry',CONCRETE)
        g.cylinder((x,.65,-5),(x,3.25,-5),.083,'wood',WOOD,10)
        for y in [.8,2.9,3.18]: g.box((x,y,-5),(.22,.10,.22),'wood',(.30,.17,.08))
        for s in [-1,1]: g.beam((x,2.78,-5),(x+s*.38,3.25,-5),.06,'wood',WOOD)
    for s in [-1,1]:
        g.box((s*3.5,.91,-4.93),(2.2,.10,.45),'wood',(.28,.14,.065))
        for x in [s*2.6,s*4.35]:g.box((x,.69,-4.9),(.13,.46,.30),'masonry',CONCRETE)
    for i in range(3):g.box((0,.07+i*.12,-5.75+i*.26),(2.1,.14+i*.24,.48),'masonry',(.48,.36,.26))
    for s in [-1,1]:g.cylinder((s*5,.1,4.6),(s*5,3.3,4.6),.045,'metal',(.31,.34,.29),7)
    return g


def laterite_cottage():
    g=Geometry('laterite_cottage'); shell(g,6.8,6.2,(.66,.60,.46))
    # Exposed coursed laterite on the plinth and side walls, with real mortar gaps.
    rng=random.Random(64)
    for s in [-1,1]:
        for row in range(4):
            for col in range(10):
                z=-2.85+col*.59+(row%2)*.15
                c=rng.uniform(.82,1.12)
                g.box((s*3.425,.59+row*.17,z),(.04,.155,.56),'detail',(.43*c,.205*c,.105*c))
    hip_roof(g,8.1,8.7,3.25,1.5,(.40,.22,.12))
    g.box((0,.30,-3.75),(6.6,.25,1.4),'masonry',(.40,.26,.16))
    for x in [-2.9,2.9]:g.cylinder((x,.42,-4.1),(x,3.18,-4.1),.075,'wood',WOOD,8)
    for i in range(2):g.box((0,.08+i*.13,-4.65+i*.27),(1.8,.16+i*.26,.50),'masonry',CONCRETE)
    # Kitchen lean-to in the rear roof silhouette.
    g.box((1.65,2.8,1.7),(.28,1.8,.28),'masonry',(.38,.31,.23))
    g.box((1.65,3.77,1.7),(.48,.10,.48),'masonry',CONCRETE)
    return g


def coastal_shop():
    g=Geometry('coastal_shop');shell(g,9,5.6,(.56,.67,.62),True)
    hip_roof(g,10.1,7.1,3.35,1.32)
    g.box((0,.27,-3.65),(9.3,.25,1.8),'masonry',CONCRETE)
    g.box((0,2.90,-3.05),(8.6,.48,.12),'sign',(.12,.32,.29))
    # Weathered striped fabric awning, suspended above the shop threshold.
    for i in range(18):
        c=(.70,.63,.43) if i%2 else (.26,.40,.34)
        g.box((-4.25+i*.5,2.64,-3.87),(.50,.045,1.8),'detail',c,Matrix.Rotation(-.12,3,'X'))
        g.box((-4.25+i*.5,2.48,-4.75),(.50,.22,.035),'detail',c)
    for x in [-4.3,4.3]:g.cylinder((x,.4,-4.6),(x,2.6,-4.6),.027,'metal',DARK,7)
    for x in [-3.4,-2.7,3.1]:
        g.box((x,.72,-3.4),(.62,.60,.55),'wood',(.33,.21,.10))
        for i in range(4):
            g.cylinder((x-.22+i*.14,1.03,-3.56),(x-.22+i*.14,1.07,-3.3),.067,'detail',(.51,.54,.15),6)
    g.box((.2,.60,-3.45),(1.5,.08,.38),'wood',WOOD)
    for x in [-.4,.8]:g.box((x,.44,-3.45),(.07,.35,.30),'metal',DARK)
    return g


def balcony_villa():
    g=flat_building('balcony_villa',9.2,8.4,2,2)
    balcony(g,0,3.48,-4.25,7.5,1.45)
    for x in [-3.6,3.6]:g.box((x,4.88,-5.5),(.20,2.7,.20),'masonry',(.68,.75,.69))
    with g.at((0,0,-4.9)):hip_roof(g,8.2,2.5,6.27,.85,(.39,.25,.20))
    # Separate porch canopy down at street level and cylindrical corner columns.
    g.box((0,3.10,-5.4),(4.2,.17,2.6),'masonry',IVORY)
    for x in [-1.9,1.9]:g.cylinder((x,.4,-6.5),(x,3.02,-6.5),.14,'masonry',IVORY,12)
    g.box((0,.2,-5.65),(4.4,.40,3.1),'masonry',CONCRETE)
    # Rooftop solar hot-water panel and antenna, plausible domestic silhouettes.
    with g.at((1.8,6.65,1.9)):
        g.box((0,.30,0),(2,.09,1.55),'glass',(.09,.19,.24),Matrix.Rotation(.28,3,'X'))
        for x in [-.94,0,.94]:g.beam((x,.09,-.72),(x,.51,.72),.035,'metal',(.48,.51,.49))
    g.cylinder((-3.6,6.5,2.9),(-3.6,8.0,2.9),.022,'metal',(.39,.43,.41),6)
    for y in [7.7,7.9]:g.beam((-4.05,y,2.9),(-3.15,y,2.9),.016,'metal',(.39,.43,.41))
    return g


def banana_clump():
    g=Geometry('banana_clump'); rng=random.Random(720)
    for plant,(x,z,h) in enumerate([(0,0,2.8),(.9,.65,2.25),(-.75,.40,1.55)]):
        with g.at((x,0,z),plant*1.3):
            g.cylinder((0,0,0),(.10,h,0),.13,'bark',(.38,.42,.20),9,.055)
            for i in range(8):
                angle=i*2.4; length=rng.uniform(1.25,2.25); width=rng.uniform(.27,.42)
                with g.at((.1,h-.16*(i%3),0),angle):
                    # Curved central rib and torn tapered lamina; each segment is
                    # slightly separated, giving banana leaves their split edges.
                    for j in range(14):
                        t0=j/14;t1=(j+1)/14
                        a=Vector((0,math.sin(t0*math.pi)*.42-t0*t0*.6,t0*length))
                        b=Vector((0,math.sin(t1*math.pi)*.42-t1*t1*.6,t1*length))
                        g.cylinder(a,b,.013,'leaves',(.24,.36,.085),5,.008)
                        for side in [-1,1]:
                            w0=width*math.sin(math.pi*max(.025,t0))**.6
                            w1=width*math.sin(math.pi*t1)**.6
                            tear=.065 if j in [4,8,11] else .004
                            c=a+Vector((side*w0,-.07,t0*.02));d=b+Vector((side*w1,-.085,-tear))
                            color=(.075+.01*(i%3),.215+.013*(i%3),.025+.004*(i%2))
                            g.mesh([a,b,d,c],[(0,1,2,3)],'banana_leaf',color,True,[(.5,t0),(.5,t1),(.5+side*.5,t1),(.5+side*.5,t0)])
            g.cylinder((.1,h-.12,0),(.17,h+.62,.10),.037,'leaves',(.23,.35,.075),8,.015)
            # A couple of hanging senescent leaves and layered leaf sheaths.
            for i in range(3):
                with g.at(angle=i*2.1):
                    g.mesh([(0,h*.65,0),(.16,h*.54,.24),(.12,.42,.42),(-.08,.52,.41)],[(0,1,2,3)],'leaves',(.37,.29,.12))
    return g


def boat(name,length,width,paint):
    g=Geometry(name); n=16
    # Open hull: curved chine, upturned ends, inside skin; no solid box deck.
    for i in range(n):
        def section(t,inside=False):
            z=(t-.5)*length; shape=math.sin(math.pi*t)**.62
            half=max(.035,width*.5*shape); bow=(abs(t-.5)*2)**4*.34
            return [(-half,.25+bow,z),(-half*.63,-.22+bow,z),(half*.63,-.22+bow,z),(half,.25+bow,z)] if not inside else [(-max(.015,half-.045),.25+bow,z),(-max(.01,half*.63-.04),-.16+bow,z),(max(.01,half*.63-.04),-.16+bow,z),(max(.015,half-.045),.25+bow,z)]
        a=section(i/n); b=section((i+1)/n); ai=section(i/n,True);bi=section((i+1)/n,True)
        for k in range(3):
            g.mesh([a[k],b[k],b[k+1],a[k+1]],[(3,2,1,0)],'wood',paint)
            g.mesh([ai[k],ai[k+1],bi[k+1],bi[k]],[(3,2,1,0)],'wood',(.25,.15,.085))
        for k in [0,3]:g.beam(a[k],b[k],.065,'wood',(.18,.10,.045))
        if i in [3,6,9,12]:
            half=width*.5*math.sin(math.pi*i/n)**.62
            g.box((0,.08,(i/n-.5)*length),(half*1.85,.065,.26),'wood',(.36,.23,.12))
    g.beam((-.18,.23,-length*.25),(.24,.27,length*.30),.045,'wood',(.45,.30,.14))
    g.box((.23,.27,length*.32),(.21,.035,.55),'wood',(.43,.27,.12))
    return g


def country_canoe():return boat('country_canoe',5.5,.86,(.14,.09,.055))


def fishing_skiff():
    g=boat('fishing_skiff',6.7,1.65,(.19,.40,.41))
    g.box((0,.32,2.35),(.30,.38,.36),'metal',(.23,.25,.24))
    g.cylinder((0,.18,2.4),(0,-.48,2.7),.035,'metal',DARK,7)
    for z in [-.8,-.1]:g.box((.27,.05,z),(.52,.27,.45),'detail',(.28,.38,.23))
    return g


def courtyard_well():
    g=Geometry('courtyard_well'); n=24
    for i in range(n):
        a=i*math.tau/n;b=(i+1)*math.tau/n
        def p(r,y,t):return (r*math.cos(t),y,r*math.sin(t))
        g.mesh([p(.78,0,a),p(.78,0,b),p(.78,.80,b),p(.78,.80,a),p(.60,.80,a),p(.60,.80,b),p(.60,0,b),p(.60,0,a)],[(3,2,1,0),(4,5,2,3),(7,6,5,4)],'masonry',(.48,.43,.33))
    for x in [-.91,.91]:g.box((x,1.55,0),(.14,3.1,.14),'masonry',CONCRETE)
    g.beam((-.95,3.02,0),(.95,3.02,0),.12,'wood',WOOD)
    g.cylinder((0,.35,0),(0,3.0,0),.012,'detail',(.48,.39,.24),6)
    g.cylinder((.55,.02,-.65),(.55,.35,-.65),.16,'metal',(.45,.48,.45),12,.20)
    hip_roof(g,2.3,1.8,3.1,.6)
    return g


def fishing_net_rack():
    g=Geometry('fishing_net_rack')
    for x in [-1.9,1.9]:g.cylinder((x,0,0),(x,2.2,0),.045,'wood',WOOD,7)
    g.beam((-2,2.1,0),(2,2.1,0),.04,'wood',WOOD)
    # Sparse geometric net, draped over a bamboo rack, with rope float markers.
    for i in range(25):
        x=-1.8+i*.15
        for side in [-1,1]:
            g.beam((x,2.08,0),(x+.04,.65,side*.45),.007,'detail',(.24,.30,.23))
    for j in range(10):
        t=j/10
        for side in [-1,1]:g.beam((-1.8,2.08-t*1.43,side*t*.45),(1.8,2.08-t*1.43,side*t*.45),.007,'detail',(.24,.30,.23))
    return g


def rice(name,ripe=False):
    g=Geometry(name);rng=random.Random(951)
    for clump in range(9):
        x=(clump%3-1)*.35+rng.uniform(-.06,.06);z=(clump//3-1)*.35
        for i in range(7):
            angle=rng.random()*math.tau;h=rng.uniform(.42,.76)
            with g.at((x,0,z),angle):
                c=(.43,.40,.10) if ripe else (.17,.34,.055)
                g.mesh([(-.018,0,0),(.018,0,0),(.025,h*.7,.10),(0,h,.28),(-.025,h*.7,.10)],[(0,1,2),(0,2,4),(4,2,3)],'grass',c)
                if ripe and i%2==0:
                    g.mesh([(0,h*.8,.13),(.028,h,.23),(0,h+.02,.30),(-.028,h*.94,.34)],[(0,1,2),(0,2,3)],'grass',(.53,.44,.17))
    return g

def rice_green():return rice('rice_green')
def rice_ripe():return rice('rice_ripe',True)

FACTORIES=[kerala_veranda,laterite_cottage,coastal_shop,balcony_villa,banana_clump,country_canoe,fishing_skiff,courtyard_well,fishing_net_rack,rice_green,rice_ripe]
