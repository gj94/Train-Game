"""Original architectural reconstructions for the Kerala Coast route.

Background Blender only. Reference photographs guide shapes, never textures.
These represent recognisable existing facades, not unbuilt redevelopment renders.
Dimensions and unseen elevations are interpreted, not survey measurements.
"""
from pathlib import Path
import sys, math, json, random
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_scenery as kit
from build_scenery import Geometry, opening, facade, box_rim, ac_unit, tank

IVORY=(.76,.73,.65); STONE=(.31,.33,.31); DARK=(.09,.12,.115)

def arch(g,x,y,z,width,height,depth=.28,colour=IVORY):
    radius=width/2; spring=y+height-radius
    for side in [-1,1]:
        g.box((x+side*(radius+.14),y+(height-radius)/2,z),(.28,height-radius,depth),'masonry',colour)
    for i in range(32):
        a=i*math.pi/32; b=(i+1)*math.pi/32
        points=[]
        for zz in [z-depth/2,z+depth/2]:
            for r,angle in [(radius,a),(radius,b),(radius+.28,b),(radius+.28,a)]:
                points.append((x+math.cos(angle)*r,spring+math.sin(angle)*r,zz))
        g.mesh(points,[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],'masonry',colour)
    # Recessed shutters in the actual arched aperture, slats end on the arch.
    for xx in range(int(width/.085)):
        dx=-radius+.045+xx*.085
        top=spring+math.sqrt(max(0,radius*radius-dx*dx))
        g.box((x+dx,(y+top)/2,z+.19),(.060,top-y,.065),'wood',(.56,.55,.47))
    for yy in [y+.15,y+(height-radius)*.55,spring]:
        g.box((x,yy,z+.10),(width,.06,.08),'wood',IVORY)

def stone_wall(g,width,height,z,seed):
    rng=random.Random(seed)
    for row in range(math.ceil(height/.28)):
        y=.15+row*.28
        offset=.32 if row%2 else 0
        for i in range(math.ceil(width/.67)+1):
            left=max(-width/2,-width/2+i*.67-offset)
            right=min(width/2,-width/2+(i+1)*.67-offset)
            if right-left<.03: continue
            shade=rng.uniform(.82,1.13)
            g.box(((left+right)/2,y,z),((right-left)-.008,.271,.31),'detail',tuple(v*shade for v in STONE))

def tvc():
    g=Geometry('kerala_tvc_heritage')
    g.box((0,.18,0),(111,.36,20),'masonry',(.46,.46,.42))
    for x,width,height in [(0,18,15.2),(-44,18,11.1),(44,18,11.1)]:
        with g.at((x,0,-1)):
            g.box((0,height/2,3),(width,height,12),'detail',STONE)
            stone_wall(g,width,height,-3.2,int(x)+81)
            for xx in [-width/2+.55,-width*.18,width*.18,width/2-.55]:
                g.box((xx,height*.47,-3.52),(1.03,height*.94,.48),'masonry',IVORY)
                for yy,ww,hh in [(1.0,1.25,.22),(height-2,1.4,.22),(height-1.6,1.65,.18)]:
                    g.box((xx,yy,-3.60),(ww,hh,.65),'masonry',IVORY)
            for xx in [-5.7,0,5.7]:
                arch(g,xx,height*.43,-3.8,2.35 if xx else 3.05,height*.43)
                arch(g,xx,.5,-3.8,2.35 if xx else 3.05,3.0)
            for yy,dd in [(height-.2,.5),(height-.7,.3),(height-1.35,.18)]:
                g.box((0,yy,-3.4),(width+.8,.18,dd+1),'masonry',IVORY)
                for side in [-1,1]: g.box((side*(width/2+.18),yy,3),(.45,.18,12.8),'masonry',IVORY)
            g.box((0,height+.42,-3.5),(width-.7,.94,.22),'masonry',IVORY)
    for side in [-1,1]:
        with g.at((side*23,0,0)):
            g.box((0,4.1,3),(27,8.2,13),'detail',STONE)
            stone_wall(g,27,7.4,-3.7,side+12)
            for x in range(-12,13,4):
                arch(g,x,.7,-4.0,2.7,3.1)
                g.cylinder((x,4.5,-5.0),(x,8.2,-5.0),.18,'masonry',IVORY,12)
                for y in [4.5,4.75,8.15]:g.box((x,y,-5),(.53,.16,.53),'masonry',IVORY)
                opening(g,x,5.0,-3.85,1.5,2.2,colour=IVORY)
            g.box((0,4.48,-4.7),(27.4,.28,2.1),'masonry',IVORY)
            for x in range(-132,133,4):
                g.box((x*.1,5.0,-5.6),(.075,.9,.08),'masonry',IVORY)
            g.box((0,5.5,-5.6),(27.4,.16,.2),'masonry',IVORY)
            for x in range(-135,136,3):
                g.beam((x*.1,8.5,-6),(x*.1,9.65,2),.09,'metal',(.27,.30,.30),.035)
                g.beam((x*.1,9.65,2),(x*.1,8.5,10),.09,'metal',(.27,.30,.30),.035)
            g.mesh([(-13.7,8.48,-6),(13.7,8.48,-6),(-13.7,9.63,2),(13.7,9.63,2),(-13.7,8.48,10),(13.7,8.48,10)],[(0,2,3,1),(2,4,5,3)],'metal',(.27,.30,.30))
    return g

def ers():
    g=Geometry('kerala_ers_entry')
    g.box((0,.2,0),(94,.4,20),'masonry',IVORY)
    g.box((0,4.5,2),(90,9,13),'masonry',(.64,.66,.60))
    for side in [-1,1]:
        with g.at((side*27,0,-5)):
            facade(g,34,0,0,8.2,[(x,1.7,1.1,2.1,'window') for x in range(-15,16,5)],(.70,.71,.63))
            for x in range(-15,16,5):
                opening(g,x,5.1,-.13,1.8,2.15)
                ac_unit(g,(x+1.3,4.4,-.1))
            for x in range(-15,16,2):
                g.box((x,2.1,-.6),(.12,3.8,.24),'masonry',(.48,.55,.52))
            box_rim(g,34,2,8.25,.75)
    # Curved entrance marquee, clock housing and deep shaded concourse.
    for x in [-10,-6,6,10]: g.box((x,3.2,-8),(.45,6.4,.6),'masonry',IVORY)
    for i in range(64):
        x=-11+22*i/64; next_x=-11+22*(i+1)/64
        y=8.0+2.2*math.cos(x/11*math.pi/2); next_y=8.0+2.2*math.cos(next_x/11*math.pi/2)
        g.beam((x,y,-8),(next_x,next_y,-8),.28,'masonry',(.50,.56,.54),1.1)
    g.box((0,7.6,-8),(21,1.2,.3),'sign',(.82,.65,.18))
    g.box((0,6.6,-6.5),(22,.20,5.4),'metal',(.32,.37,.38))
    for x in range(-10,11): g.beam((x,6.7,-9),(x,6.7,-4),.05,'metal',DARK)
    g.box((0,9.0,-8.15),(2.1,2.3,.25),'masonry',IVORY)
    g.cylinder((0,9.1,-8.34),(0,9.1,-8.43),.70,'detail',(.83,.82,.73),48)
    g.beam((0,9.1,-8.45),(0,9.65,-8.45),.04,'metal',DARK)
    g.beam((0,9.1,-8.46),(.36,8.91,-8.46),.055,'metal',DARK)
    return g

def ncj():
    g=Geometry('kerala_ncj_entry')
    g.box((0,.2,0),(82,.4,21),'masonry',IVORY)
    g.box((0,4.0,3),(78,8,14),'masonry',(.72,.54,.43))
    for x in range(-36,37,6):
        opening(g,x,1.1,-4.1,2.1,2.2)
        opening(g,x,4.5,-4.1,2.1,2.0)
    for x in range(-30,31,6):
        g.box((x,4.45,-7),(.70,8.9,.85),'masonry',IVORY)
        g.box((x,1.0,-7),(.94,1.3,1.03),'masonry',(.50,.47,.42))
    g.box((0,8.75,-6),(67,.50,4.8),'masonry',IVORY)
    g.box((0,9.40,-7.8),(49,1.15,.35),'masonry',(.73,.58,.47))
    for x in [-25,25]:
        for y in [2,5.1]: ac_unit(g,(x,y,-4.4))
    return g

def coastal():
    g=Geometry('kerala_coastal_station')
    g.box((0,.22,0),(64,.44,15),'masonry',IVORY)
    for side in [-1,1]:
        with g.at((side*18,0,0)):
            facade(g,23,0,-5,4.4,[(x,1.5,.85,1.9,'window') for x in [-9,-4,4,9]],(.73,.70,.57))
            g.box((0,2.2,1),(23,4.4,10),'masonry',(.73,.70,.57))
    for x in [-7,-3.5,3.5,7]: g.box((x,2.6,-5.5),(.4,5.2,.5),'masonry',IVORY)
    g.box((0,4.6,-2),(64,.20,11),'masonry',IVORY)
    for x in range(-32,33,2):
        g.beam((x,4.8,-7),(x,7.1,0),.10,'roof',(.46,.24,.12),.035)
        g.beam((x,7.1,0),(x,4.8,7),.10,'roof',(.46,.24,.12),.035)
    g.mesh([(-33,4.8,-7),(33,4.8,-7),(-33,7.1,0),(33,7.1,0),(-33,4.8,7),(33,4.8,7)],[(0,2,3,1),(2,4,5,3)],'roof',(.72,.55,.39))
    for z in [-6.9,6.9]:
        for x in range(-32,33,8): g.cylinder((x,.3,z),(x,4.75,z),.10,'metal',(.26,.34,.30),10)
    g.box((0,5.5,-7),(17,1.3,.20),'sign',(.86,.68,.20))
    return g

def main():
    for factory in [tvc,ers,ncj,coastal]: kit.save(factory())
    path=kit.OUT/'manifest.json'
    manifest=json.loads(path.read_text()) if path.exists() else {}
    manifest.update(kit.MANIFEST)
    path.write_text(json.dumps(manifest,indent=2)+'\n')

if __name__=='__main__': main()
