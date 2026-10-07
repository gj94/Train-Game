"""Original tropical vegetation: curved fronds, leaflets and branching canopies."""
import math, random
from mathutils import Vector
from build_scenery import Geometry

def leaf(g,base,tip,width,colour,roll=0,kind='leaves'):
    a,b=Vector(base),Vector(tip); d=b-a
    normal=d.cross(Vector((0,1,0)))
    if normal.length<.0001: normal=Vector((1,0,0))
    normal.normalize()
    normal=normal*math.cos(roll)+d.normalized().cross(normal)*math.sin(roll)
    mid=a+d*.48; ridge=mid+Vector((0,width*.16,0))
    vertices=[a,mid-normal*width*.5,ridge,mid+normal*width*.5,b]
    g.mesh(vertices,[(0,1,2),(0,2,3),(1,4,2),(2,4,3)],kind,colour)

def scanned_leaf(g,base,tip,width,colour,roll):
    """Bent card with the unchanged CC0 leaflet mapped to its own UV island."""
    a,b=Vector(base),Vector(tip); d=b-a
    across=d.cross(Vector((0,1,0)))
    if across.length<.0001: across=Vector((1,0,0))
    across.normalize()
    across=across*math.cos(roll)+d.normalized().cross(across)*math.sin(roll)
    # Rectangle enclosing one leaf in the source's 1024px atlas, bottom-left area.
    u0,u1=54/1024,242/1024; v0,v1=1-980/1024,1-872/1024
    vertices=[]; uvs=[]
    for t in [0,.5,1]:
        p=a+d*t+Vector((0,math.sin(t*math.pi)*width*.16,0))
        for s in [-1,1]:
            vertices.append(p+across*s*width*.5)
            uvs.append((u0+(u1-u0)*t,v0 if s<0 else v1))
    g.mesh(vertices,[(0,1,3,2),(2,3,5,4)],'broadleaf',colour,uvs=uvs)

def curved_branch(g,points,radius,kind='bark',colour=(.25,.23,.17),end_radius=.014,sides=7):
    for i in range(len(points)-1):
        t=i/(len(points)-1); u=(i+1)/(len(points)-1)
        g.cylinder(points[i],points[i+1],radius+(end_radius-radius)*t,kind,colour,sides,radius+(end_radius-radius)*u)

def palm(name,height,seed):
    rng=random.Random(seed); g=Geometry(name)
    lean=Vector((rng.uniform(.7,1.8),0,rng.uniform(-.8,.8)))
    trunk=[]
    for i in range(18):
        t=i/17
        trunk.append(lean*(t*t)+Vector((math.sin(t*3)*.12,height*t,math.sin(t*4)*.1)))
    curved_branch(g,trunk,.20,'bark',(.33,.30,.22),.112,11)
    for i in range(2,int(height/.28)):
        t=i*.28/height; p=lean*(t*t)+Vector((math.sin(t*3)*.12,height*t,math.sin(t*4)*.1))
        radius=.20+(.112-.20)*t
        g.cylinder(p,p+Vector((0,.018,0)),radius+.007,'bark',(.40,.36,.26),11)
    crown=trunk[-1]
    g.cylinder(crown-Vector((0,.08,0)),crown+Vector((0,.58,0)),.19,'leaves',(.21,.31,.10),9,.11)
    for frond in range(23):
        theta=frond*2.399963+rng.uniform(-.11,.11)
        direction=Vector((math.cos(theta),0,math.sin(theta)))
        across=Vector((-direction.z,0,direction.x))
        length=rng.uniform(3.4,4.8)*(height/11)**.34
        lift=1.05 if frond<6 else (.50 if frond<15 else -.14)
        def along(t): return crown+direction*length*t+Vector((0,.30+length*(lift*t-(lift+.37)*t*t),0))
        pts=[along(i/9) for i in range(10)]
        curved_branch(g,pts,.036,'leaves',(.20,.29,.095),.005,5)
        for side in [-1,1]:
            for i in range(27):
                t=.11+i*.032+rng.uniform(-.006,.006)
                point=along(t)
                span=(.20+math.sin(math.pi*t)**.8)*rng.uniform(.74,1.06)
                tip=point+across*side*span+direction*length*.10+Vector((0,-span*.40,0))
                colour=(rng.uniform(.035,.070),rng.uniform(.095,.17),rng.uniform(.017,.038),.3+.7*t)
                if frond>20: colour=(.15,.11,.035,1) # Retained dry lower fronds.
                leaf(g,point,tip,rng.uniform(.085,.115),colour,rng.uniform(-.30,.30))
    for i in range(7):
        theta=i*math.tau/7
        p=crown+Vector((math.cos(theta)*.22,-.28,math.sin(theta)*.22))
        g.cylinder(p,p+Vector((0,.19,0)),.105,'bark',(.25,.28,.09),7,.075)
    return g

def coconut_palm(): return palm('coconut_palm',11.2,92)
def young_palm(): return palm('young_palm',6.5,158)

def broadleaf(name,height,radius,seed):
    rng=random.Random(seed); g=Geometry(name)
    centre=Vector((.32,height*.35,-.24))
    curved_branch(g,[Vector((0,0,0)),Vector((-.08,.9,.03)),Vector((.12,height*.20,-.16)),centre],.33,'bark',(.24,.235,.17),.21,10)
    for i in range(6):
        a=i*math.tau/6
        curved_branch(g,[Vector((math.cos(a)*1.0,.03,math.sin(a)*1.0)),Vector((math.cos(a)*.40,.34,math.sin(a)*.40)),Vector((0,1.1,0))],.065,'bark',(.25,.235,.17),.14,7)
    for major in range(7):
        angle=major*2.399+rng.uniform(-.30,.30)
        side=Vector((math.cos(angle),0,math.sin(angle)))
        end=centre+side*radius*rng.uniform(.40,.68)+Vector((0,height*rng.uniform(.15,.37),0))
        mid=centre*.45+end*.55-Vector((0,.38,0))
        curved_branch(g,[centre,mid,end],.16,'bark',(.25,.235,.17),.048,8)
        for branch in range(4):
            theta=angle+(branch-1.5)*.64
            direction=Vector((math.cos(theta),0,math.sin(theta)))
            tip=end+direction*radius*rng.uniform(.32,.58)+Vector((0,rng.uniform(.35,2.10),0))
            curved_branch(g,[end,(end+tip)*.5+Vector((0,.17,0)),tip],.055,'bark',(.24,.24,.16),.012,6)
            for shoot in range(42):
                theta=rng.uniform(0,math.tau)
                delta=Vector((math.cos(theta),rng.uniform(-.70,1.10),math.sin(theta)))
                start=end.lerp(tip,rng.uniform(.05,1.0))+Vector((rng.uniform(-.55,.55),rng.uniform(-.65,.55),rng.uniform(-.55,.55)))
                finish=start+delta*rng.uniform(.55,1.30)
                g.cylinder(start,finish,.009,'bark',(.28,.29,.12),4,.002)
                axis=Vector((delta.z,0,-delta.x)).normalized()
                for k in range(1,6):
                    p=start.lerp(finish,k/6)
                    for sign in [-1,1]:
                        length=rng.uniform(.38,.62)
                        tip_leaf=p+axis*sign*length+delta*.13+Vector((0,rng.uniform(-.10,.07),0))
                        hue=rng.random()
                        colour=(.63+hue*.30,.67+hue*.27,.55+hue*.30,1)
                        scanned_leaf(g,p,tip_leaf,length*.59,colour,rng.uniform(-1.2,1.2))
    return g

def mango_tree(): return broadleaf('mango_tree',7.0,3.6,200)
def rain_tree(): return broadleaf('rain_tree',8.6,5.0,321)

def shrub():
    rng=random.Random(210); g=Geometry('shrub')
    for stem in range(35):
        theta=rng.uniform(0,math.tau); spread=rng.uniform(.2,.95)
        base=Vector((rng.uniform(-.13,.13),0,rng.uniform(-.13,.13)))
        tip=Vector((math.cos(theta)*spread,rng.uniform(.75,1.75),math.sin(theta)*spread))
        g.cylinder(base,tip,.015,'bark',(.25,.25,.11),5,.004)
        axis=Vector((math.sin(theta),0,-math.cos(theta)))
        for i in range(2,9):
            p=base.lerp(tip,i/10)
            for sign in [-1,1]: leaf(g,p,p+axis*sign*rng.uniform(.14,.28)+Vector((0,.05,0)),.07,(.16,.27,.055,.8),rng.uniform(-1,1))
    return g

def grass_tuft():
    rng=random.Random(204); g=Geometry('grass_tuft')
    for i in range(24):
        theta=rng.uniform(0,math.tau); direction=Vector((math.cos(theta),0,math.sin(theta)))
        across=Vector((-direction.z,0,direction.x))*rng.uniform(.008,.018)
        base=Vector((rng.uniform(-.18,.18),0,rng.uniform(-.18,.18)))
        h=rng.uniform(.22,.66); bend=rng.uniform(.13,.29)
        colour=(rng.uniform(.18,.25),rng.uniform(.23,.31),rng.uniform(.055,.095),1)
        mid=base+Vector((0,h*.62,0))+direction*bend*.32
        tip=base+Vector((0,h,0))+direction*bend
        g.mesh([base-across,base+across,mid-across*.58,mid+across*.58,tip],[(0,1,2),(2,1,3),(2,3,4)],'grass',colour)
    return g

def reeds():
    rng=random.Random(222); g=Geometry('reeds')
    for i in range(18):
        base=Vector((rng.uniform(-.35,.35),0,rng.uniform(-.35,.35)))
        tip=base+Vector((rng.uniform(-.2,.2),rng.uniform(1.0,1.8),rng.uniform(-.2,.2)))
        g.cylinder(base,tip,.011,'grass',(.30,.32,.13,1),4,.006)
        for k in range(3):
            p=base.lerp(tip,.25+k*.20)
            angle=rng.uniform(0,math.tau)
            leaf(g,p,p+Vector((math.cos(angle)*.45,.15,math.sin(angle)*.45)),.07,(.24,.33,.085,1),.3,'grass')
        g.cylinder(tip-Vector((0,.23,0)),tip,.029,'bark',(.31,.22,.10),5)
    return g

def verge_patch():
    """Irregular four-metre weed patch; batched near-track cover, no flat cards."""
    rng=random.Random(716); g=Geometry('verge_patch')
    for tuft in range(58):
        angle=rng.random()*math.tau; radius=math.sqrt(rng.random())*1.8
        centre=Vector((math.cos(angle)*radius,0,math.sin(angle)*radius))
        height=rng.uniform(.12,.42)
        for blade in range(16):
            theta=rng.random()*math.tau
            direction=Vector((math.cos(theta),0,math.sin(theta)))
            across=Vector((-direction.z,0,direction.x))*rng.uniform(.004,.010)
            base=centre+Vector((rng.uniform(-.10,.10),0,rng.uniform(-.10,.10)))
            h=height*rng.uniform(.7,1.2)
            mid=base+Vector((0,h*.72,0))+direction*h*.15
            tip=base+Vector((0,h*.90,0))+direction*h*.60
            dry=rng.random()<.23
            colour=(.13,.105,.043) if dry else (.050,.090,.025)
            g.mesh([base-across,base+across,mid-across*.65,mid+across*.65,tip],[(0,1,2),(2,1,3),(2,3,4)],'grass',colour)
        if tuft%5==0:
            stem=centre+Vector((0,height*.5,0))
            for i in range(5):
                a=i*2.4
                leaf(g,stem,stem+Vector((math.cos(a)*.18,.04,math.sin(a)*.18)),.07,(.065,.105,.025),a*.3,'grass')
    return g

FACTORIES=[coconut_palm,young_palm,mango_tree,rain_tree,shrub,grass_tuft,reeds,verge_patch]
