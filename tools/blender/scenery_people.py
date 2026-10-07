"""Original small, metre-scale passengers and street figures for instancing.

Cloth has actual volume/folds; rounded limbs replace the older capsule-and-box
figures. These are scenery figures, not a character-creation or animation system.
"""
import math
from mathutils import Vector, Matrix
from build_scenery import Geometry
from scenery_landmarks import ellipsoid

SKIN=(.30,.17,.105); HAIR=(.016,.014,.011); SHOE=(.028,.032,.029)

def oval_limb(g,a,b,r1,r2,kind,colour,sides=10):
    a,b=Vector(a),Vector(b); d=b-a; q=d.to_track_quat('Y','Z').to_matrix()
    vertices=[]
    for t,bulge in [(0,.73),(.16,1),(.64,.96),(.91,.86),(1,.68)]:
        r=(r1+(r2-r1)*t)*bulge
        for i in range(sides):
            theta=i*math.tau/sides
            vertices.append(a+q@Vector((math.cos(theta)*r,d.length*t,math.sin(theta)*r*.87)))
    faces=[tuple(range(sides)),tuple(reversed(range(sides*4,sides*5)))]
    for j in range(4):
        for i in range(sides):
            a=j*sides+i; b=j*sides+(i+1)%sides
            faces.append((a,a+sides,b+sides,b))
    g.mesh(vertices,faces,kind,colour,True)

def cloth(g,rings,colour,folds=0,phase=0):
    n=24; vertices=[]
    for y,rx,rz,offset_z in rings:
        for i in range(n):
            a=i*math.tau/n; wave=1+folds*math.cos(a*9+phase)
            vertices.append((math.cos(a)*rx*wave,y,offset_z+math.sin(a)*rz*wave))
    faces=[tuple(range(n)),tuple(reversed(range((len(rings)-1)*n,len(rings)*n)))]
    for row in range(len(rings)-1):
        for i in range(n):
            a=row*n+i; b=row*n+(i+1)%n
            faces.append((a,a+n,b+n,b))
    g.mesh(vertices,faces,'detail',colour,True)

def head(g,p,skin=SKIN,female=False):
    x,y,z=p
    oval_limb(g,(x,y-.20,z+.008),(x,y-.085,z+.008),.048,.049,'detail',skin,16)
    # Integrated bridge, cheekbones, sockets, jaw and chin replace the egg head
    # and separate large nose. Dimensions remain appropriate to a 1.7 m figure.
    vertices=[]; faces=[]; sides=40; rings=28
    def bell(v,c,s): return math.exp(-((v-c)/s)**2)
    for j in range(rings+1):
        latitude=math.pi*j/rings
        yy=math.cos(latitude)*.133
        jaw=.72+.28*min(1,max(0,(yy+.115)/.095))
        for i in range(sides):
            a=i*math.tau/sides
            xx=math.cos(a)*math.sin(latitude)*.098*jaw
            zz=math.sin(a)*math.sin(latitude)*.097
            front=max(0,-math.sin(a))**10
            shape=.020*bell(xx,0,.013)*bell(yy,.013,.049)
            shape+=.027*bell(xx,0,.020)*bell(yy,-.026,.020)
            shape+=.006*bell(abs(xx),.052,.021)*bell(yy,-.019,.034)
            shape+=.009*bell(xx,0,.029)*bell(yy,-.095,.020)
            shape-=.009*bell(abs(xx),.036,.021)*bell(yy,.020,.014)
            vertices.append((x+xx,y+yy,z+zz-front*shape))
    for j in range(rings):
        for i in range(sides):
            a=j*sides+i; b=j*sides+(i+1)%sides
            faces.append((a,a+sides,b+sides,b))
    g.mesh(vertices,[tuple(reversed(face)) for face in faces],'detail',skin,True)
    # Hair cap follows the scalp; irregular hairline, no helmet-like lower sphere.
    vertices=[]; faces=[]
    for j in range(11):
        for i in range(40):
            a=i*math.tau/40
            front=max(0,-math.sin(a))
            end=1.70-front*.66+.035*math.sin(a*7)
            t=end*j/10
            vertices.append((x+math.cos(a)*math.sin(t)*.100,y+math.cos(t)*.135,z+math.sin(a)*math.sin(t)*.099))
    for j in range(10):
        for i in range(40):
            a=j*40+i; b=j*40+(i+1)%40
            faces.append((a,a+40,b+40,b))
    g.mesh(vertices,[tuple(reversed(face)) for face in faces],'detail',HAIR,True)
    for side in [-1,1]:
        ellipsoid(g,(x+side*.097,y-.005,z),(.013,.027,.018),'detail',skin,14,8)
        ellipsoid(g,(x+side*.107,y-.006,z-.008),(.004,.017,.009),'detail',tuple(v*.60 for v in skin),10,6)
        ellipsoid(g,(x+side*.035,y+.019,z-.088),(.014,.0045,.006),'detail',(.42,.38,.32),16,8)
        ellipsoid(g,(x+side*.035,y+.019,z-.094),(.0045,.0042,.0015),'detail',(.042,.027,.014),12,6)
        ellipsoid(g,(x+side*.035,y+.019,z-.095),(.002,.0027,.001),'detail',HAIR,10,6)
        # Curved eyelids, fine eyebrows and nostrils, all millimetre-scale.
        for k in range(5):
            u=k/5; v=(k+1)/5
            for upper in [False,True]:
                def lid(t): return (x+side*.035+(t-.5)*.031,y+.019+math.sin(t*math.pi)*(.006 if upper else -.004),z-.092)
                g.beam(lid(u),lid(v),.002,'detail',skin)
            g.beam((x+side*.035+(u-.5)*.036,y+.036+.004*math.sin(u*math.pi),z-.090),(x+side*.035+(v-.5)*.036,y+.036+.004*math.sin(v*math.pi),z-.090),.0025,'detail',HAIR)
        ellipsoid(g,(x+side*.010,y-.039,z-.117),(.004,.0025,.003),'detail',tuple(v*.45 for v in skin),10,6)
    ellipsoid(g,(x,y-.063,z-.087),(.024,.004,.006),'detail',(.22,.094,.065),20,8)
    ellipsoid(g,(x,y-.069,z-.086),(.021,.0035,.006),'detail',(.29,.13,.084),20,8)
    if female:
        ellipsoid(g,(x,y+.024,z+.109),(.071,.060,.069),'detail',HAIR,10,7)
        for side in [-1,1]: ellipsoid(g,(x+side*.111,y-.035,z),(.012,.018,.009),'metal',(.48,.33,.10),8,4)

def person(g,female=False,colour=(.16,.29,.38),pose='standing',bag=True):
    seated=pose in ['seated','rider']; hips=.87 if not seated else .56
    torso_bottom=hips; torso_top=hips+.49
    cloth(g,[(torso_bottom,.15,.10,0),(hips+.06,.155,.104,0),(hips+.12,.162,.105,0),(hips+.23,.171,.116,0),(hips+.36,.20,.12,0),(hips+.43,.177,.092,0),(torso_top,.075,.070,0)],colour,.028)
    if female:
        cloth(g,[(.075,.23,.16,0),(.23,.23,.15,0),(hips-.09,.17,.12,0),(hips+.04,.16,.115,0)],colour,.08)
        # Contrast border and diagonal pallu follow the torso, with folded edges.
        cloth(g,[(.07,.232,.162,0),(.11,.23,.16,0)],(.56,.39,.14),.07)
        g.mesh([(-.16,hips+.02,-.115),(.11,hips+.45,-.11),(.19,hips+.45,-.10),(-.035,hips+.02,-.12)],[(0,1,2,3),(3,2,1,0)],'detail',(.44,.27,.17))
    else:
        for side in [-1,1]:
            foot_z=.10 if side>0 else -.06
            knee_z=-.27 if seated else foot_z*.5
            ankle_z=-.44 if seated else foot_z
            oval_limb(g,(side*.085,hips+.05,.0),(side*.105,.48 if not seated else .47,knee_z),.10,.076,'detail',(.065,.075,.071))
            oval_limb(g,(side*.105,.48 if not seated else .47,knee_z),(side*.105,.105,ankle_z),.078,.058,'detail',(.062,.070,.069))
            ellipsoid(g,(side*.105,.067,ankle_z-.035),(.077,.055,.145),'detail',SHOE,12,6)
        # Visible shirt opening, collar and rolled cuffs.
        g.beam((0,hips+.05,-.112),(0,hips+.45,-.115),.013,'detail',tuple(v*.65 for v in colour))
        for y in [.09,.19,.29,.39]: ellipsoid(g,(.012,hips+y,-.118),(.004,.004,.002),'detail',(.51,.50,.43),10,5)
        for side in [-1,1]:
            g.mesh([(side*.014,hips+.47,-.070),(side*.072,hips+.48,-.064),(side*.107,hips+.405,-.105),(side*.045,hips+.42,-.112)],[(0,1,2,3),(3,2,1,0)],'detail',tuple(v*.84 for v in colour))
        # Pocket rim and fabric hem, not a floating solid rectangle.
        g.beam((.065,hips+.31,-.122),(.135,hips+.31,-.115),.004,'detail',tuple(v*.74 for v in colour))
    for side in [-1,1]:
        shoulder=(side*.19,hips+.42,0)
        elbow=(side*.245,hips+.20,-.045)
        hand=(side*.255,hips-.02,-.07)
        if pose=='phone' and side<0: elbow=(-.28,hips+.20,-.03); hand=(-.18,hips+.53,-.17)
        if seated: elbow=(side*.23,hips+.22,-.17); hand=(side*.18,hips+.08,-.38)
        if pose=='rider': elbow=(side*.25,hips+.29,-.30); hand=(side*.30,hips+.20,-.65)
        oval_limb(g,shoulder,elbow,.077,.060,'detail',colour)
        oval_limb(g,elbow,hand,.052,.037,'detail',SKIN)
        ellipsoid(g,hand,(.043,.070,.035),'detail',SKIN,10,6)
    head(g,(0,hips+.68,-.005),female=female)
    if pose=='phone': g.box((-.18,hips+.53,-.196),(.063,.121,.010),'detail',(.02,.027,.025),Matrix.Rotation(-.12,3,'X'))
    if bag:
        ellipsoid(g,(.30,hips-.23,-.04),(.13,.17,.085),'detail',(.21,.115,.061),12,6)
        for z in [-.07,-.025]: g.beam((.255,hips-.015,z),(.34,hips-.13,z),.013,'detail',(.13,.065,.025))
    if female:
        for side in [-1,1]: ellipsoid(g,(side*.105,.038,-.055),(.068,.034,.13),'detail',(.14,.065,.035),12,6)
    return g

def passenger_man(): return person(Geometry('passenger_man'),colour=(.20,.31,.37))
def passenger_phone(): return person(Geometry('passenger_phone'),colour=(.51,.46,.33),pose='phone',bag=False)
def passenger_sari(): return person(Geometry('passenger_sari'),True,(.36,.095,.16))
def passenger_sari_blue(): return person(Geometry('passenger_sari_blue'),True,(.075,.24,.30),bag=False)
def passenger_seated(): return person(Geometry('passenger_seated'),colour=(.37,.40,.34),pose='seated')

FACTORIES=[passenger_man,passenger_phone,passenger_sari,passenger_sari_blue,passenger_seated]
