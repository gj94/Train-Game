"""Detailed WAP-7 exterior. Run only in a fresh BACKGROUND Blender process.

Metres; X across, +Y cab 1, Z=0 rail top. GLB becomes Godot -Z forward.
Original geometry, referenced to photographs recorded in docs/wap7.md.
The master retains named assemblies, inspection cameras and a separate studio.
Usage: blender -b --factory-startup --python tools/blender/build_wap7.py [-- --render]
"""
import bpy
import bmesh
import json
import math
import os
import sys
from mathutils import Vector, Matrix

P = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(P, 'assets', 'models')
MASTER = os.path.join(P, 'art', 'wap7')
TAU = math.tau
M = {}
GROUPS = []


def mat(name, color, rough=.45, metal=0, emission=0):
    m = bpy.data.materials.new('WAP7_' + name)
    m.use_nodes = True
    m.use_backface_culling = True
    m.diffuse_color = (*color, 1)
    bs = m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value = (*color, 1)
    bs.inputs['Roughness'].default_value = rough
    bs.inputs['Metallic'].default_value = metal
    if emission:
        bs.inputs['Emission Color'].default_value = (*color, 1)
        bs.inputs['Emission Strength'].default_value = emission
    M[name] = m
    return m


class Parts:
    """Batch small manufactured parts into an editable functional assembly."""
    def __init__(self, name, parent=None, collection=None):
        self.name, self.parent = name, parent
        self.collection = collection or ASSET
        self.v, self.f, self.mi, self.smooth = [], [], [], []
        self.mats = []

    def mesh(self, vertices, faces, material, smooth=False):
        if material not in self.mats:
            self.mats.append(material)
        off = len(self.v)
        self.v.extend(vertices)
        self.f.extend([tuple(i + off for i in f) for f in faces])
        self.mi.extend([self.mats.index(material)] * len(faces))
        self.smooth.extend([smooth] * len(faces))

    def box(self, p, size, material, rot=None):
        vs = [Vector((x*size[0]/2, y*size[1]/2, z*size[2]/2))
              for x,y,z in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),
                            (-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
        if rot is not None:
            vs = [rot @ v for v in vs]
        self.mesh([Vector(p)+v for v in vs],
                  [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)], material)

    def cylinder(self, a, b, r, material, n=24, r2=None):
        a, b = Vector(a), Vector(b)
        d = b-a
        q = d.to_track_quat('Z', 'Y').to_matrix()
        r2 = r if r2 is None else r2
        vs = [a + q @ Vector((rad*math.cos(TAU*i/n),rad*math.sin(TAU*i/n),z))
              for z,rad in [(0,r),(d.length,r2)] for i in range(n)]
        faces = [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
        self.mesh(vs, faces, material, True)
        self.mesh(vs,[tuple(reversed(range(n))),tuple(range(n,2*n))],material)

    def tube(self, points, radius, material, sides=8, closed=False):
        pts = [Vector(p) for p in points]
        vs=[]
        for i,p in enumerate(pts):
            a = pts[(i-1)%len(pts)] if (i or closed) else p
            b = pts[(i+1)%len(pts)] if (i+1<len(pts) or closed) else p
            q = (b-a).to_track_quat('Z','Y').to_matrix()
            vs += [p+q@Vector((radius*math.cos(TAU*k/sides),radius*math.sin(TAU*k/sides),0)) for k in range(sides)]
        faces=[]
        for i in range(len(pts) if closed else len(pts)-1):
            for j in range(sides):
                ni=(i+1)%len(pts)
                faces.append((i*sides+j,i*sides+(j+1)%sides,ni*sides+(j+1)%sides,ni*sides+j))
        self.mesh(vs,faces,material,True)

    def ring(self, p, r, wire, material, axis='Z', n=40):
        points=[]
        for i in range(n):
            a=TAU*i/n
            v={'Z':(r*math.cos(a),r*math.sin(a),0),
               'X':(0,r*math.cos(a),r*math.sin(a)),
               'Y':(r*math.cos(a),0,r*math.sin(a))}[axis]
            points.append(Vector(p)+Vector(v))
        self.tube(points,wire,material,8,True)

    def finish(self, bevel=0):
        me=bpy.data.meshes.new(self.name)
        me.from_pydata(self.v,[],self.f)
        me.update()
        ob=bpy.data.objects.new(self.name,me)
        self.collection.objects.link(ob)
        ob.parent=self.parent
        for name in self.mats:
            me.materials.append(M[name])
        for f,mi,s in zip(me.polygons,self.mi,self.smooth):
            f.material_index=mi
            f.use_smooth=s
        if bevel:
            mod=ob.modifiers.new('Machined edge radii','BEVEL')
            mod.width=bevel
            mod.segments=3
            mod.affect='EDGES'
            mod=ob.modifiers.new('Weighted surface normals','WEIGHTED_NORMAL')
            mod.keep_sharp=True
        GROUPS.append(ob)
        return ob


def empty(name, parent=None):
    ob=bpy.data.objects.new(name,None)
    ASSET.objects.link(ob)
    ob.parent=parent
    return ob


def text(name, content, p, size, material='Letter', facing='FRONT', parent=None):
    cr=bpy.data.curves.new(name,'FONT')
    cr.body=content
    cr.size=size
    cr.align_x='CENTER'
    cr.align_y='CENTER'
    cr.font=FONT
    cr.space_character=1.08
    cr.extrude=.0008
    cr.resolution_u=4
    ob=bpy.data.objects.new(name,cr)
    ASSET.objects.link(ob)
    ob.location=p
    # Local text X is reading direction; local Y is up; local Z faces viewer.
    axes={'FRONT':((-1,0,0),(0,0,1),(0,1,0)),
          'REAR':((1,0,0),(0,0,1),(0,-1,0)),
          'RIGHT':((0,1,0),(0,0,1),(1,0,0)),
          'LEFT':((0,-1,0),(0,0,1),(-1,0,0))}
    ob.rotation_euler=Matrix(axes[facing]).transposed().to_euler()
    cr.materials.append(M[material])
    ob.parent=parent or ROOT
    bpy.context.view_layer.objects.active=ob
    ob.select_set(True)
    bpy.ops.object.convert(target='MESH')
    ob.select_set(False)
    GROUPS.append(ob)
    return ob


def rounded_rect(cx,cz,w,h,r,y,sgn=1):
    pts=[]
    for x,z,start in [(cx+w/2-r,cz+h/2-r,0),(cx-w/2+r,cz+h/2-r,90),
                       (cx-w/2+r,cz-h/2+r,180),(cx+w/2-r,cz-h/2+r,270)]:
        for i in range(7):
            a=math.radians(start+i*90/6)
            zz=z+r*math.sin(a)
            pts.append((x+r*math.cos(a),sgn*(y-.195*(zz-cz)),zz))
    return pts


def make_body():
    shell=Parts('01_Body_shell_and_livery',ROOT)
    rings=[]
    # Chamfered plan and a raked cab face, with continuous height-based livery.
    for z,w,y in [(1.48,1.54,9.37),(1.60,1.576,9.37),(2.20,1.576,9.33),
                  (2.48,1.576,9.28),(3.72,1.576,9.04),(3.89,1.48,8.98),
                  (4.07,1.14,8.86),(4.12,.65,8.82)]:
        ring=[(-w,-y+.30,z),(-w+.25,-y,z),(w-.25,-y,z),(w,-y+.30,z),
              (w,y-.30,z),(w-.25,y,z),(-w+.25,y,z),(-w,y-.30,z)]
        rings.append(ring)
    for i in range(len(rings)-1):
        material='Red' if i==2 else ('Roof' if i>=5 else 'Ivory')
        for j in range(8):
            k=(j+1)%8
            shell.mesh([rings[i][j],rings[i][k],rings[i+1][k],rings[i+1][j]],[(0,1,2,3)],material)
    shell.mesh(rings[0],[tuple(reversed(range(8)))],'Under')
    shell.mesh(rings[-1],[tuple(range(8))],'Roof')
    ob=shell.finish(.018)
    # Recalculate normals of the closed envelope, before adding detached fittings.
    bm=bmesh.new(); bm.from_mesh(ob.data)
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
    bm.to_mesh(ob.data); bm.free()
    frame=Parts('02_Main_frame_sills_and_rivets',ROOT)
    frame.box((0,0,1.42),(3.12,18.85,.22),'Frame')
    for s in [-1,1]:
        frame.box((s*1.52,0,1.52),(.07,18.35,.09),'SteelDark')
        frame.box((s*1.585,0,3.73),(.055,17.30,.045),'Roof')
        for y in [i*.38 for i in range(-23,24)]:
            frame.cylinder((s*1.566,y,1.425),(s*1.591,y,1.425),.014,'Steel',6)
        for y in [-8.8,8.8]:
            frame.box((s*1.60,y,1.44),(.16,.24,.20),'Frame')
    frame.finish(.008)


def make_sides():
    for s in [-1,1]:
        p=Parts('03_Side_%s_access_panels_and_grilles'%s,ROOT)
        for y in [-5.35,5.35]:
            p.box((s*1.586,y,3.035),(.025,1.80,1.22),'SteelDark')
            p.box((s*1.607,y,3.035),(.024,1.64,1.07),'Black')
            for k in range(41):
                p.box((s*1.632,y-.79+k*.0395,3.035),(.026,.012,1.02),'Grille')
            for z in [2.47,3.035,3.60]:
                p.box((s*1.65,y,z),(.025,1.75,.025),'SteelDark')
            for yy in [y-.86,y+.86]:
                p.box((s*1.65,yy,3.035),(.025,.034,1.15),'Roof')
                for z in [2.49,2.75,3.30,3.58]:
                    p.cylinder((s*1.663,yy,z),(s*1.677,yy,z),.014,'Steel',6)
        # Low inspection covers, lifting eyes and long welded seams.
        for y in [-3.7,-1.85,0,1.85,3.7]:
            p.box((s*1.581,y,1.88),(.012,1.70,.40),'Seam')
            p.box((s*1.593,y,1.885),(.013,1.665,.363),'Ivory')
            for yy in [y-.72,y+.72]:
                p.box((s*1.609,yy,1.99),(.022,.075,.025),'SteelDark')
        for y in [-6.7,6.7,-3.9,3.9]:
            p.box((s*1.58,y,3.04),(.013,.011,1.12),'Seam')
        for e in [-1,1]:
            y=e*7.65
            p.box((s*1.59,y,2.61),(.025,.77,1.98),'Seam')
            p.box((s*1.608,y,2.62),(.025,.719,1.924),'Ivory')
            p.box((s*1.627,y,2.34),(.018,.718,.28),'Red')
            p.box((s*1.627,y,3.18),(.021,.49,.60),'Rubber')
            p.box((s*1.643,y,3.19),(.012,.416,.52),'Glass')
            for zz in [2.03,3.31]:
                p.cylinder((s*1.648,y-e*.29,zz-.075),(s*1.648,y-e*.29,zz+.075),.019,'Steel',12)
            p.tube([(s*1.656,y+e*.245,2.50),(s*1.710,y+e*.245,2.50),
                    (s*1.710,y+e*.245,2.34),(s*1.656,y+e*.245,2.34)],.017,'Steel')
            for yy in [y-.49,y+.49]:
                p.tube([(s*1.603,yy,1.62),(s*1.70,yy,1.71),(s*1.70,yy,2.79),
                        (s*1.603,yy,2.85)],.022,'Steel')
            for z in [.56,.86,1.16]:
                p.box((s*1.60,y,z),(.38,.74,.065),'Frame')
                for yy in [y-.3,y-.15,y,y+.15,y+.3]:
                    p.box((s*1.60,yy,z+.038),(.32,.035,.018),'Steel')
            for yy in [y-.33,y+.33]:
                p.box((s*1.48,yy,.96),(.055,.035,.96),'Frame')
            # Cab side sliding window, two panes and polished runners.
            yy=e*8.55
            p.box((s*1.58,yy,3.15),(.030,.69,.91),'Rubber')
            p.box((s*1.60,yy,3.15),(.017,.606,.812),'Glass')
            p.box((s*1.619,yy,3.15),(.018,.024,.818),'Steel')
            for zz in [2.72,3.58]:
                p.box((s*1.625,yy,zz),(.036,.74,.025),'Steel')
            p.box((s*1.643,yy+e*.21,3.00),(.026,.083,.033),'Steel')
            facing='RIGHT' if s>0 else 'LEFT'
            text('Cab_entry_label','CAB %d'%(1 if e>0 else 2),(s*1.645,y,2.76),.065,'Letter',facing)
        p.finish(.005)
        facing='RIGHT' if s>0 else 'LEFT'
        text('Railway_side_legend','INDIAN RAILWAYS',(s*1.594,0,3.16),.42,'Letter',facing)
        text('Running_number_side','30306',(s*1.596,0,2.74),.22,'Letter',facing)
        text('Shed_side','LALLAGUDA  •  SCR',(s*1.61,0,1.87),.11,'Letter',facing)
        text('Class_side','WAP-7',(s*1.61,-3.15,1.88),.115,'Letter',facing)
        text('Technical_stencil','25 kV AC   |   Co-Co   |   140 km/h',(s*1.61,2.8,1.88),.072,'Letter',facing)


def make_ends():
    for e in [1,-1]:
        root=empty('Cab_%d_fittings'%(1 if e>0 else 2),ROOT)
        p=Parts('04_Cab_%s_windows_guards_wipers'%e,root)
        for x in [-.67,.67]:
            outline=rounded_rect(x,3.20,1.14,1.00,.10,9.16,e)
            p.mesh(outline,[tuple(range(len(outline)))],'Rubber')
            outline=rounded_rect(x,3.20,1.035,.895,.075,9.176,e)
            p.mesh(outline,[tuple(range(len(outline)))],'Glass')
            p.tube(rounded_rect(x,3.20,1.115,.976,.09,9.193,e),.020,'Steel',8,True)
            p.tube(rounded_rect(x,3.20,1.19,1.05,.09,9.27,e),.020,'Guard',8,True)
            for j in range(10):
                xx=x-.49+j*.109
                p.cylinder((xx,e*9.344,2.81),(xx,e*9.188,3.59),.008,'Guard',8)
            for zz in [2.88,3.17,3.52]:
                yy=e*(9.27-.195*(zz-3.2))
                p.cylinder((x-.55,yy,zz),(x+.55,yy,zz),.009,'Guard',8)
            # Actual wiper arm and separate rubber blade below the guard.
            p.tube([(x-.32,e*9.318,2.78),(x-.20,e*9.281,2.98),
                    (x+.16,e*9.234,3.24)],.012,'Black')
            p.cylinder((x-.12,e*9.244,3.08),(x+.37,e*9.218,3.39),.016,'Rubber',8)
            p.cylinder((x-.32,e*9.30,2.78),(x-.32,e*9.36,2.78),.032,'Steel',16)
            for dx in [-.51,.51]:
                for zz in [2.78,3.65]:
                    yy=e*(9.27-.195*(zz-3.2))
                    p.cylinder((x+dx,yy-e*.025,zz),(x+dx,yy+e*.023,zz),.020,'Steel',8)
        p.finish()
        p=Parts('05_Cab_%s_lamps_horns_and_hardware'%e,root)
        p.box((0,e*9.337,2.35),(.63,.09,.38),'SteelDark')
        for x in [-.151,.151]:
            p.cylinder((x,e*9.35,2.35),(x,e*9.43,2.35),.136,'Steel',40)
            p.cylinder((x,e*9.428,2.35),(x,e*9.439,2.35),.112,'Headlamp',40)
            for dx in [-.05,0,.05]:
                p.cylinder((x+dx,e*9.442,2.265),(x+dx,e*9.442,2.435),.003,'LensLine',6)
        for x in [-1.02,1.02]:
            p.box((x,e*9.325,2.32),(.22,.075,.44),'SteelDark')
            for z,ma in [(2.425,'Marker'),(2.245,'Tail')]:
                p.cylinder((x,e*9.36,z),(x,e*9.416,z),.078,'Steel',32)
                p.cylinder((x,e*9.415,z),(x,e*9.425,z),.060,ma,32)
            p.box((x,e*9.415,1.82),(.205,.10,.27),'Frame')
            p.cylinder((x,e*9.464,1.83),(x,e*9.51,1.83),.070,'Socket',20)
            p.ring((x,e*9.516,1.83),.076,.012,'Steel','Y')
        p.tube([(-1.21,e*9.42,1.60),(-1.26,e*9.43,1.72),(-1.26,e*9.37,2.64)],.021,'Steel')
        p.tube([(1.21,e*9.42,1.60),(1.26,e*9.43,1.72),(1.26,e*9.37,2.64)],.021,'Steel')
        p.tube([(-1.12,e*9.365,2.68),(-1.05,e*9.385,2.65),(1.05,e*9.385,2.65),(1.12,e*9.365,2.68)],.019,'Steel')
        # Roof trumpets, with open black mouths and rolled brass lip.
        for x,r in [(-.29,.115),(.02,.09)]:
            p.cylinder((x,e*8.42,4.21),(x,e*8.88,4.21),.036,'Horn',24,r)
            p.cylinder((x,e*8.884,4.21),(x,e*8.889,4.21),r*.83,'Black',24)
            p.ring((x,e*8.89,4.21),r,.012,'Horn','Y')
            p.box((x,e*8.45,4.09),(.05,.16,.18),'SteelDark')
        p.cylinder((.65,e*8.39,4.11),(.65,e*8.39,4.38),.033,'SteelDark',16)
        p.cylinder((.65,e*8.39,4.38),(.65,e*8.39,4.72),.006,'Steel',8)
        p.finish(.003)
        # Era-inspired identity plate and small tricolour; no photo textures.
        p=Parts('06_Cab_%s_badge_and_flag'%e,root)
        p.cylinder((0,e*9.292,2.71),(0,e*9.331,2.71),.112,'Gold',48)
        p.cylinder((0,e*9.332,2.71),(0,e*9.340,2.71),.093,'Blue',48)
        for z,ma in [(2.03,'Saffron'),(1.975,'Ivory'),(1.92,'Green')]:
            p.box((0,e*9.396,z),(.31,.010,.052),ma)
        p.ring((0,e*9.406,1.975),.019,.003,'Blue','Y',24)
        p.finish()
        facing='FRONT' if e>0 else 'REAR'
        text('Class_front','WAP-7',(e*.61,e*9.428,1.84),.17,'Letter',facing,root)
        text('Number_front','30306',(-e*.61,e*9.428,1.84),.18,'Letter',facing,root)
        text('Shed_badge','LGD',(0,e*9.344,2.714),.064,'Gold',facing,root)
        text('Cab_id','%d'%(1 if e>0 else 2),(1.28,e*9.35,2.13),.083,'Letter',facing,root)
        make_bufferbeam(e,root)


def make_bufferbeam(e,root):
    p=Parts('07_End_%s_buffers_CBC_hoses_pilot'%e,root)
    p.box((0,e*9.47,1.17),(3.09,.26,.40),'Frame')
    for x in [-1.0,1.0]:
        p.box((x,e*9.623,1.095),(.47,.055,.44),'SteelDark')
        p.cylinder((x,e*9.62,1.095),(x,e*10.065,1.095),.135,'Steel',32)
        p.cylinder((x,e*10.06,1.095),(x,e*10.14,1.095),.322,'SteelDark',64)
        p.cylinder((x,e*10.14,1.095),(x,e*10.154,1.095),.303,'BufferFace',64)
        for dx in [-.175,.175]:
            for dz in [-.16,.16]:
                p.cylinder((x+dx,e*9.65,1.095+dz),(x+dx,e*9.69,1.095+dz),.024,'Steel',6)
    p.box((0,e*9.86,1.035),(.23,.80,.22),'SteelDark')
    # Cast knuckle silhouette, with an open throat instead of a solid box.
    profile=[(-.24,10.06),(-.19,10.23),(-.08,10.281),(.055,10.281),
             (.10,10.22),(.02,10.19),(-.025,10.22),(-.08,10.19),
             (-.07,10.12),(.12,10.11),(.18,10.20),(.24,10.18),(.22,10.06)]
    n=len(profile)
    vs=[(x,e*y,z) for z in [.92,1.19] for x,y in profile]
    p.mesh(vs,[tuple(reversed(range(n))),tuple(range(n,n*2))]+
           [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)],'Coupler')
    p.box((.04,e*10.12,1.20),(.19,.19,.048),'SteelDark')
    p.cylinder((.075,e*10.17,.94),(.075,e*10.17,1.22),.057,'Steel',16)
    p.tube([(-.35,e*9.71,1.28),(-.35,e*9.82,1.38),(.39,e*9.82,1.38),(.39,e*9.66,1.28)],.020,'Steel')
    for x in [-.52,.52,-.74,.74]:
        p.cylinder((x,e*9.57,1.40),(x,e*9.78,1.40),.045,'Steel',16)
        p.tube([(x,e*9.79,1.4),(x+.10,e*9.87,1.14),(x+.13,e*9.92,.78),
                (x+.04,e*9.97,.66),(x-.04,e*9.92,.78)],.034,'Rubber',12)
        p.cylinder((x-.04,e*9.89,.75),(x-.04,e*9.97,.79),.062,'Steel',12)
        p.box((x,e*9.77,1.43),(.115,.030,.025),'ValveRed' if x<0 else 'Yellow')
    # Pilot is an open welded grille, with curved lower rail and diagonal braces.
    p.tube([(-1.46,e*9.63,.77),(-1.32,e*9.87,.35),(0,e*10.01,.27),
            (1.32,e*9.87,.35),(1.46,e*9.63,.77)],.047,'Frame',10)
    for z in [.39,.59,.78]:
        p.cylinder((-1.34,e*(9.95-(z-.39)*.60),z),(1.34,e*(9.95-(z-.39)*.60),z),.027,'Frame',10)
    for k in range(13):
        x=-1.26+k*.21
        p.cylinder((x,e*9.99,.34),(x,e*9.69,.81),.016,'SteelDark',8)
    for s in [-1,1]:
        p.cylinder((s*.2,e*9.83,.42),(s*1.38,e*9.63,.87),.028,'Frame',10)
    p.finish(.012)


def make_bogies():
    for bi,cy in enumerate([6,-6],1):
        root=empty('Bogie_%d'%bi,ROOT)
        root['pivot_y_m']=cy
        p=Parts('08_Bogie_%d_fabricated_frame'%bi,root)
        for s in [-1,1]:
            p.box((s*1.115,cy,1.01),(.24,4.75,.22),'Frame')
            p.box((s*1.118,cy,1.17),(.27,3.95,.11),'SteelDark')
            for y in [cy-2.15,cy,cy+2.15]:
                p.box((0,y,1.0),(2.4,.19,.21),'Frame')
            for d in [-.93,.93]:
                for dx in [-.13,.13]:
                    x=s*1.16+dx
                    # Large secondary suspension coils, real swept-wire helices.
                    points=[(x+.14*math.cos(t*TAU*6),cy+d+.14*math.sin(t*TAU*6),.96+t*.43) for t in [k/100 for k in range(101)]]
                    p.tube(points,.028,'Spring',8)
                    p.cylinder((x,cy+d,.91),(x,cy+d,.965),.178,'Frame',24)
                    p.cylinder((x,cy+d,1.375),(x,cy+d,1.415),.177,'SteelDark',24)
            for y in [cy-1.83,cy,cy+1.83]:
                p.box((s*1.16,y,.57),(.36,.43,.33),'SteelDark')
                p.cylinder((s*1.32,y,.57),(s*1.39,y,.57),.148,'Frame',32)
                p.cylinder((s*1.39,y,.57),(s*1.41,y,.57),.090,'SteelDark',24)
                for j in range(6):
                    a=TAU*j/6
                    p.cylinder((s*1.415,y+.115*math.cos(a),.57+.115*math.sin(a)),
                               (s*1.43,y+.115*math.cos(a),.57+.115*math.sin(a)),.015,'Steel',6)
                for yy in [y-.26,y+.26]:
                    points=[(s*1.13+.081*math.cos(t*TAU*4),yy+.081*math.sin(t*TAU*4),.63+t*.32) for t in [k/64 for k in range(65)]]
                    p.tube(points,.019,'Spring',8)
                p.cylinder((s*1.32,y+.16,.65),(s*1.33,y+.52,1.12),.033,'Damper',16)
                p.cylinder((s*1.33,y+.42,.985),(s*1.33,y+.52,1.12),.020,'Steel',12)
                p.cylinder((s*1.30,y-.40,.44),(s*1.30,y-.33,.86),.022,'SteelDark',12)
                p.box((s*.95,y-.48,.56),(.15,.10,.27),'Brake')
                p.box((s*.95,y+.48,.56),(.15,.10,.27),'Brake')
            p.tube([(s*1.34,cy-2.2,.98),(s*1.38,cy-1.3,.93),(s*1.38,cy+1.1,.93),(s*1.31,cy+2.18,.78)],.018,'Pipe',8)
            for dy in [-1.12,1.12]:
                p.cylinder((s*.7,cy+dy,.84),(s*1.17,cy+dy,.84),.102,'Frame',24)
                p.cylinder((s*1.17,cy+dy,.84),(s*1.34,cy+dy,.84),.028,'Steel',12)
                p.cylinder((s*1.32,cy+dy-.18,.77),(s*1.32,cy+dy+.18,.77),.023,'Brake',12)
            for y in [cy-2.0,cy+2.0]:
                p.box((s*1.42,y,1.0),(.16,.14,.14),'Yellow')
        p.finish(.009)
        for wi,dy in enumerate([-1.85,0,1.85],1):
            y=cy+dy
            wheel=Parts('Wheelset_%d_%d'%(bi,wi),root)
            wheel.cylinder((-1.2,y,.546),(1.2,y,.546),.115,'SteelDark',32)
            for s in [-1,1]:
                # 1092 mm tread diameter with a flange on the inboard face.
                wheel.cylinder((s*.853,y,.546),(s*1.002,y,.546),.546,'WheelTread',64)
                wheel.cylinder((s*.817,y,.546),(s*.853,y,.546),.575,'Steel',64)
                wheel.cylinder((s*1.003,y,.546),(s*1.020,y,.546),.455,'WheelFace',64)
                wheel.ring((s*1.025,y,.546),.418,.013,'SteelDark','X',56)
                wheel.cylinder((s*1.022,y,.546),(s*1.064,y,.546),.19,'SteelDark',32)
                for j in range(8):
                    a=TAU*j/8
                    wheel.cylinder((s*1.025,y+.32*math.sin(a),.546+.32*math.cos(a)),
                                   (s*1.032,y+.32*math.sin(a),.546+.32*math.cos(a)),.034,'Black',16)
            ob=wheel.finish()
            # Put the object's origin on the axle for downstream animation.
            for v in ob.data.vertices:
                v.co-=Vector((0,y,.546))
            ob.location=(0,y,.546)
            ob['radius_m']=.546
        p=Parts('09_Bogie_%d_traction_motors_sand_lines'%bi,root)
        for dy in [-1.85,0,1.85]:
            y=cy+dy
            p.cylinder((-.63,y+.26,.65),(.63,y+.26,.65),.24,'Motor',32)
            for x in [-.44,-.25,0,.25,.44]:
                p.ring((x,y+.26,.65),.242,.018,'Frame','X',32)
            p.box((.70,y+.1,.58),(.20,.62,.56),'Frame')
        for s in [-1,1]:
            for e in [-1,1]:
                y=cy+e*2.26
                p.box((s*.92,y,1.12),(.46,.39,.41),'Frame')
                p.tube([(s*.92,y,.94),(s*.92,y+e*.05,.55),(s*.89,y-e*.04,.15)],.025,'Pipe',10)
        p.finish(.014)


def make_underframe():
    p=Parts('10_Transformer_battery_boxes_reservoirs',ROOT)
    p.box((0,0,.90),(1.85,4.60,.72),'Frame')
    p.box((0,0,.47),(1.55,3.70,.12),'SteelDark')
    for s in [-1,1]:
        for y in [-1.46,1.46]:
            p.box((s*1.21,y,.98),(.49,1.1,.61),'Motor')
            for z in [.75,.86,.97,1.08,1.19]:
                p.box((s*1.465,y,z),(.035,1.01,.031),'SteelDark')
            for yy in [y-.46,y+.46]:
                p.box((s*1.49,yy,.98),(.021,.022,.53),'Steel')
        p.cylinder((s*1.13,-.62,.83),(s*1.13,.62,.83),.225,'Tank',40)
        for yy in [-.40,.40]:
            p.ring((s*1.13,yy,.83),.23,.024,'SteelDark','Y',40)
        p.cylinder((s*1.13,.62,.83),(s*1.13,.68,.83),.055,'Steel',16)
        p.tube([(s*1.18,-2.75,1.25),(s*1.28,-2.40,.58),(s*1.28,2.40,.58),(s*.80,2.72,1.21)],.028,'Pipe')
        for y in [-2.55,2.55]:
            p.box((s*1.1,y,1.1),(.6,.50,.42),'Frame')
    p.finish(.013)


def insulator(p,x,y,z,height=.37):
    p.cylinder((x,y,z),(x,y,z+height),.069,'Ceramic',24)
    for i in range(7):
        zz=z+.037+i*(height-.07)/6
        p.cylinder((x,y,zz),(x,y,zz+.023),.124,'Ceramic',28,.097)
    p.cylinder((x,y,z-.018),(x,y,z+.018),.108,'Steel',24)
    p.cylinder((x,y,z+height),(x,y,z+height+.052),.065,'Steel',16)


def make_roof():
    p=Parts('11_Roof_access_hatches_walkways_and_fans',ROOT)
    for y in [-6.8,-4.25,-1.55,1.3,4.15,6.7]:
        p.box((0,y,4.105),(1.65,2.3,.07),'Roof')
        for x in [-.8,.8]:
            p.box((x,y,4.148),(.012,2.22,.012),'Seam')
            for yy in [y-.9,y,y+.9]:
                p.cylinder((x,yy,4.15),(x,yy,4.172),.018,'Steel',6)
        for yy in [y-1.08,y+1.08]:
            p.box((0,yy,4.151),(1.6,.012,.013),'Seam')
            for x in [-.5,.5]:
                p.tube([(x-.065,yy,4.15),(x-.065,yy,4.23),(x+.065,yy,4.23),(x+.065,yy,4.15)],.014,'Steel')
    for s in [-1,1]:
        p.box((s*1.19,0,4.04),(.34,13.40,.055),'Walkway')
        for k in range(110):
            p.box((s*1.19,-6.45+k*.119,4.077),(.32,.025,.014),'Roof')
    for y in [-2.55,2.55]:
        p.box((0,y,4.20),(1.44,1.50,.15),'SteelDark')
        p.cylinder((0,y,4.26),(0,y,4.29),.61,'Black',64)
        for j in range(8):
            a=TAU*j/8
            p.box((.28*math.cos(a),y+.28*math.sin(a),4.295),(.49,.11,.017),'Fan',Matrix.Rotation(a+.5,3,'Z'))
        p.cylinder((0,y,4.28),(0,y,4.34),.13,'SteelDark',32)
        for r in [.15,.25,.35,.45,.56,.63]:
            p.ring((0,y,4.36),r,.006,'Grille','Z',48)
        for i in range(16):
            a=TAU*i/16
            p.cylinder((0,y,4.36),(.63*math.cos(a),y+.63*math.sin(a),4.36),.005,'Grille',6)
    p.finish(.003)
    p=Parts('12_High_voltage_bus_VCB_and_roof_cables',ROOT)
    for y in [-4.6,-1.35,1.10,4.45]:
        insulator(p,.58,y,4.15,.39)
    p.tube([(.58,-5.7,4.58),(.58,-4.6,4.59),(.58,-1.35,4.59),
            (.58,1.1,4.59),(.58,4.45,4.59),(.58,5.7,4.57)],.027,'Copper',12)
    p.box((-.28,0,4.22),(.65,1.22,.20),'SteelDark')
    insulator(p,-.29,-.39,4.32,.42)
    insulator(p,-.29,.42,4.32,.42)
    p.cylinder((-.29,-.39,4.79),(-.29,.42,4.79),.076,'Ceramic',24)
    p.tube([(.58,1.1,4.61),(-.29,.74,4.61),(-.29,.42,4.79)],.024,'Copper')
    p.tube([(-.29,-.39,4.79),(-.55,-.60,4.77),(-.65,-.75,4.28)],.030,'Cable')
    for y in [-3.8,3.8]:
        insulator(p,-.55,y,4.15,.30)
        p.tube([(-.55,y,4.51),(-.9,y+.23,4.3),(-1.0,y+.38,4.05)],.020,'Copper')
    p.finish()
    pantograph(1,6.0,False)
    pantograph(2,-6.0,True)


def pantograph(idx,cy,raised):
    root=empty('Pantograph_%d_%s'%(idx,'raised' if raised else 'folded'),ROOT)
    p=Parts('13_Pantograph_%d_insulated_base'%idx,root)
    for x in [-.62,.62]:
        for y in [cy-.70,cy+.70]:
            insulator(p,x,y,4.15,.22)
        p.box((x,cy,4.43),(.065,1.83,.075),'Panto')
    for y in [cy-.7,cy+.7]:
        p.box((0,y,4.43),(1.40,.07,.075),'Panto')
    p.cylinder((-.50,cy+.41,4.49),(.50,cy+.41,4.49),.074,'SteelDark',24)
    p.finish(.006)
    p=Parts('14_Pantograph_%d_articulated_arms'%idx,root)
    direction=-1 if cy>0 else 1
    y0=cy-direction*.61
    y1=cy+direction*(.55 if raised else .82)
    y2=cy-direction*.26
    z0=4.49; z1=5.15 if raised else 4.60; z2=5.68 if raised else 4.72
    for s in [-1,1]:
        p.cylinder((s*.49,y0,z0),(s*.19,y1,z1),.034,'Panto',12)
        p.cylinder((s*.19,y1,z1),(s*.49,y2,z2),.025,'Panto',12)
        p.cylinder((s*.36,y0,z0+.04),(s*.12,y1,z1+.03),.014,'SteelDark',10)
        p.cylinder((s*.12,y1,z1+.03),(s*.35,y2,z2-.04),.015,'SteelDark',10)
        for yy,zz,xx in [(y0,z0,.49),(y1,z1,.19),(y2,z2,.49)]:
            p.cylinder((s*(xx-.047),yy,zz),(s*(xx+.047),yy,zz),.056,'Steel',20)
    p.cylinder((-.49,y0,z0),(.49,y0,z0),.04,'Panto',16)
    p.cylinder((-.19,y1,z1),(.19,y1,z1),.03,'Panto',16)
    p.cylinder((-.49,y2,z2),(.49,y2,z2),.03,'Panto',16)
    p.cylinder((-.47,y0,z0),(.47,y1,z1),.012,'SteelDark',8)
    for s in [-1,1]:
        p.tube([(s*.48,y0,4.50),(s*.48,y0+.38*direction,4.50),(s*.30,y1,z1-.04)],.018,'Copper')
        for k in range(15):
            yy=cy-.45+k*.025
            p.ring((s*.30,yy,4.49),.045,.010,'Spring','Y',16)
    p.finish()
    p=Parts('15_Pantograph_%d_contact_head'%idx,root)
    for yy in [y2-.16,y2+.16]:
        p.box((0,yy,z2+.045),(1.61,.055,.045),'Contact')
        p.tube([(-1.03,yy,z2-.16),(-.90,yy,z2-.035),(-.78,yy,z2+.035),
                (.78,yy,z2+.035),(.90,yy,z2-.035),(1.03,yy,z2-.16)],.025,'Copper',12)
    for x in [-.55,0,.55]:
        p.box((x,y2,z2-.003),(.040,.37,.030),'SteelDark')
    p.finish(.004)


def setup_studio():
    studio=bpy.data.collections.new('STUDIO • excluded from GLB')
    bpy.context.scene.collection.children.link(studio)
    p=Parts('Display_track',collection=studio)
    for x in [-.870,.870]:
        p.box((x,0,-.10),(.145,26,.035),'Rail')
        p.box((x,0,-.048),(.026,26,.095),'SteelDark')
        p.box((x,0,-.008),(.067,26,.022),'Steel')
    for i in range(41):
        y=-12.5+i*.625
        p.box((0,y,-.20),(2.75,.24,.19),'Sleeper')
        for x in [-.87,.87]:
            p.box((x,y,-.116),(.23,.20,.025),'Rail')
            for dx in [-.10,.10]:
                p.tube([(x+dx,y-.055,-.107),(x+dx,y,-.079),(x+dx,y+.055,-.107)],.013,'Rail')
    p.finish(.014)
    p=Parts('Studio_floor',collection=studio)
    p.box((0,0,-.34),(200,200,.05),'Floor')
    p.finish()
    sc=bpy.context.scene
    sc.world=bpy.data.worlds.new('Cool studio ambience')
    sc.world.use_nodes=True
    bg=sc.world.node_tree.nodes.get('Background')
    bg.inputs[0].default_value=(.21,.27,.35,1)
    bg.inputs[1].default_value=.40
    for name,loc,energy,size,color in [
        ('Long warm key',(4,7,14),3300,10,(1,.91,.80)),
        ('Cool side fill',(-9,0,8),2600,9,(.76,.86,1)),
        ('Roof strip',(1,-7,13),3000,8,(1,1,1)),
        ('Cab softbox',(1,16,7),1700,7,(1,.96,.91)),
    ]:
        d=bpy.data.lights.new(name,'AREA'); d.energy=energy; d.shape='DISK'; d.size=size; d.color=color
        ob=bpy.data.objects.new(name,d); studio.objects.link(ob); ob.location=loc
        ob.rotation_euler=(Vector((0,0,1.7))-ob.location).to_track_quat('-Z','Y').to_euler()
    for name,loc,target,lens in [
        ('01_Hero',(17.7,25.7,10.3),(0,0,2.1),49),
        ('02_Front',(5.1,18.8,5.0),(0,8.1,2.2),45),
        ('03_Bogie',(6.6,9.0,2.6),(.35,5.9,.85),53),
        ('04_Roof',(9,-13,13),(0,-2,4.2),49),
        ('05_Side',(28,0,7),(0,0,2.5),45),
    ]:
        d=bpy.data.cameras.new(name); ob=bpy.data.objects.new(name,d); studio.objects.link(ob)
        ob.location=loc; d.lens=lens
        ob.rotation_euler=(Vector(target)-ob.location).to_track_quat('-Z','Y').to_euler()
        d.clip_end=250
    sc.camera=bpy.data.objects['01_Hero']
    sc.render.engine='CYCLES'
    sc.cycles.device='CPU'
    sc.cycles.samples=32
    sc.cycles.use_denoising=True
    sc.render.resolution_x=1920; sc.render.resolution_y=1080; sc.render.resolution_percentage=100
    sc.render.image_settings.file_format='PNG'
    sc.view_settings.view_transform='AgX'
    sc.render.film_transparent=False
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type=='VIEW_3D':
                area.spaces.active.region_3d.view_perspective='CAMERA'
                area.spaces.active.shading.type='MATERIAL'
    return studio


def main():
    global ASSET,ROOT,FONT
    if not bpy.app.background:
        raise RuntimeError('Safety: this builder is only for background Blender.')
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob,do_unlink=True)
    ASSET=bpy.data.collections.new('WAP-7 • locomotive assemblies')
    bpy.context.scene.collection.children.link(ASSET)
    ROOT=empty('WAP7_30306')
    ROOT['prototype']='Indian Railways WAP-7, Lallaguda 30306; reference-based exterior'
    ROOT['units']='metres; rail top Z=0; forward +Y; glTF forward -Z'
    ROOT['gauge_m']=1.676; ROOT['bogie_centres_m']=12.0; ROOT['axle_spacing_m']=1.85
    ROOT['body_width_m']=3.152; ROOT['nominal_length_over_couplers_m']=20.562
    ROOT['source_notes']='docs/wap7.md — photo references and approximation boundaries'
    FONT=bpy.data.fonts.load('C:/Windows/Fonts/bahnschrift.ttf') if os.path.exists('C:/Windows/Fonts/bahnschrift.ttf') else bpy.data.fonts[0]
    for name,col,rough,metal in [
        ('Ivory',(.79,.78,.71),.34,.12),('Red',(.52,.036,.013),.34,.15),
        ('Roof',(.29,.31,.31),.58,.45),('Under',(.048,.054,.052),.76,.25),
        ('Frame',(.064,.077,.076),.59,.55),('SteelDark',(.13,.155,.16),.43,.75),
        ('Steel',(.46,.51,.52),.28,.88),('Glass',(.018,.07,.094),.16,.65),
        ('Rubber',(.009,.014,.016),.80,.05),('Black',(.009,.012,.012),.65,.12),
        ('Letter',(.018,.025,.027),.49,.08),('Grille',(.105,.13,.135),.50,.68),
        ('Guard',(.27,.30,.28),.40,.70),('Seam',(.26,.28,.26),.60,.08),
        ('WheelTread',(.32,.35,.34),.24,.95),('WheelFace',(.12,.135,.12),.60,.75),
        ('Spring',(.18,.18,.15),.52,.80),('Brake',(.19,.16,.12),.68,.70),
        ('Damper',(.21,.25,.26),.4,.75),('Pipe',(.14,.17,.15),.46,.7),
        ('Motor',(.105,.13,.135),.63,.4),('Tank',(.12,.155,.15),.50,.65),
        ('Panto',(.61,.30,.047),.40,.62),('Copper',(.33,.17,.073),.38,.80),
        ('Ceramic',(.20,.073,.036),.23,.10),('Cable',(.026,.039,.033),.72,.0),
        ('Contact',(.055,.06,.057),.7,.35),('Walkway',(.20,.24,.24),.75,.60),
        ('Fan',(.25,.30,.31),.38,.8),('Horn',(.13,.30,.32),.39,.68),
        ('Gold',(.88,.57,.055),.33,.6),('Blue',(.013,.06,.28),.39,.18),
        ('Saffron',(.96,.26,.035),.39,.05),('Green',(.018,.30,.085),.42,.05),
        ('BufferFace',(.19,.21,.205),.49,.8),('Coupler',(.24,.21,.17),.68,.72),
        ('Socket',(.12,.16,.15),.50,.60),('Tail',(.36,.008,.006),.23,.2),
        ('Marker',(.74,.77,.70),.23,.3),('Yellow',(.9,.56,.03),.5,.2),
        ('ValveRed',(.61,.047,.02),.5,.4),('LensLine',(.50,.48,.36),.21,.2),
        ('Rail',(.12,.115,.103),.71,.65),('Sleeper',(.26,.275,.263),.88,0),
        ('Floor',(.065,.083,.104),.65,.08),
    ]:
        mat(name,col,rough,metal)
    mat('Headlamp',(1,.84,.53),.19,.12,.4)
    for fn in [make_body,make_sides,make_ends,make_bogies,make_underframe,make_roof]:
        fn(); print('BUILT',fn.__name__,flush=True)
    # Articulation origins are real pivots; preserve each child's world placement.
    for name,origin in [('Bogie_1',(0,6,.95)),('Bogie_2',(0,-6,.95)),
                        ('Pantograph_1_folded',(0,6,4.43)),('Pantograph_2_raised',(0,-6,4.43))]:
        parent=bpy.data.objects[name]
        parent.location=origin
        for child in parent.children:
            child.location-=Vector(origin)
    # Avoid mirrored front/back decal normals; make these tiny surfaces explicit.
    for ob in ASSET.objects:
        if ob.type=='MESH':
            bm=bmesh.new(); bm.from_mesh(ob.data)
            bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
            bm.to_mesh(ob.data); bm.free()
    # Window sheets need normals facing out independently of their orientation.
    for ob in ASSET.objects:
        if ob.type=='MESH' and '_windows_guards_wipers' in ob.name:
            e=1 if 'Cab_1_' in ob.name else -1
            for poly in ob.data.polygons:
                if len(poly.vertices)>10 and poly.normal.y*e<0:
                    poly.flip()
    os.makedirs(OUT,exist_ok=True); os.makedirs(MASTER,exist_ok=True)
    bpy.ops.object.select_all(action='DESELECT')
    for ob in ASSET.objects:
        ob.select_set(True)
    bpy.context.view_layer.objects.active=ROOT
    glb=os.path.join(OUT,'wap7.glb')
    bpy.ops.export_scene.gltf(filepath=glb,export_format='GLB',use_selection=True,
                              export_apply=True,export_extras=True,export_yup=True,
                              export_cameras=False,export_lights=False)
    # Statistics from evaluated geometry, so bevels and text are counted.
    dg=bpy.context.evaluated_depsgraph_get()
    stats={'mesh_objects':0,'triangles':0,'vertices':0,'materials':len(M),'glb_bytes':os.path.getsize(glb)}
    for ob in ASSET.objects:
        if ob.type=='MESH':
            ev=ob.evaluated_get(dg); me=ev.to_mesh(); me.calc_loop_triangles()
            stats['mesh_objects']+=1; stats['triangles']+=len(me.loop_triangles); stats['vertices']+=len(me.vertices)
            ev.to_mesh_clear()
    setup_studio()
    bpy.ops.object.select_all(action='DESELECT')
    ROOT.select_set(True); bpy.context.view_layer.objects.active=ROOT
    bpy.context.scene.unit_settings.system='METRIC'
    bpy.context.scene.render.filepath=os.path.join(MASTER,'hero.png')
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(MASTER,'wap7_30306.blend'),compress=True)
    with open(os.path.join(MASTER,'model-stats.json'),'w',encoding='utf8') as f:
        json.dump(stats,f,indent=2)
    print('WAP7_STATS '+json.dumps(stats),flush=True)
    if '--render' in sys.argv:
        bpy.ops.render.render(write_still=True)


if __name__=='__main__':
    main()
