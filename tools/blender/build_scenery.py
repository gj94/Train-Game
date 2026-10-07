"""Original metre-scale Southern Indian scenery kit. BACKGROUND Blender only.

No borrowed meshes or reference-photo pixels. Runtime supplies the registered
CC0 PBR finishes. Colour attributes retain restrained, varied facade/prop paint.
Coordinates throughout are Godot metres: X width, Y up, front faces -Z.
"""
from __future__ import annotations
import bpy, math, random, json, struct, sys
from pathlib import Path
from contextlib import contextmanager
from mathutils import Vector, Matrix

sys.path.insert(0,str(Path(__file__).resolve().parent))
sys.modules.setdefault('build_scenery',sys.modules[__name__])

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/models/scenery'
MASTERS = ROOT / 'art/scenery'
RNG = random.Random(20261007)
MATERIALS = {}
MANIFEST = {}
SURFACE_IDS={'detail':0,'masonry':1,'roof':2,'metal':3,'glass':4,'bark':5,'leaves':6,'grass':7,'sign':8,'wood':9,'broadleaf':10}
PAINTS = [(0.64,.58,.44),(.61,.66,.60),(.48,.60,.63),(.68,.58,.52),(.68,.68,.57),(.57,.64,.58)]
IVORY=(.76,.73,.63); CONCRETE=(.43,.43,.39); DARK=(.055,.07,.07)
RUST=(.27,.12,.065); GLASS=(.12,.20,.21); STEEL=(.24,.29,.29); WOOD=(.20,.115,.060)

def material(name):
    if name in MATERIALS: return MATERIALS[name]
    mat=bpy.data.materials.new('SC_'+name)
    mat.use_nodes=True
    mat.use_backface_culling=True
    node=mat.node_tree.nodes.get('Principled BSDF')
    attr=mat.node_tree.nodes.new('ShaderNodeVertexColor'); attr.layer_name='Color'
    mat.node_tree.links.new(attr.outputs['Color'],node.inputs['Base Color'])
    node.inputs['Roughness'].default_value=.85 if name!='glass' else .26
    node.inputs['Metallic'].default_value=.45 if name=='metal' else 0
    if name=='broadleaf':
        # Registered CC0 Burkea leaf photographs; reused as ornamental foliage.
        # UVs select one isolated leaflet directly; source pixels are unchanged.
        prefix=OUT/'tree_small_02_tree_small_02_leaves'
        diffuse=mat.node_tree.nodes.new('ShaderNodeTexImage')
        diffuse.image=bpy.data.images.load(str(prefix)+'_diff_1k.png',check_existing=True)
        normal=mat.node_tree.nodes.new('ShaderNodeTexImage')
        normal.image=bpy.data.images.load(str(prefix)+'_nor_gl_1k.png',check_existing=True)
        normal.image.colorspace_settings.name='Non-Color'
        mat.node_tree.links.new(diffuse.outputs['Color'],node.inputs['Base Color'])
        mat.node_tree.links.new(diffuse.outputs['Alpha'],node.inputs['Alpha'])
        bump=mat.node_tree.nodes.new('ShaderNodeNormalMap')
        bump.inputs['Strength'].default_value=.45
        mat.node_tree.links.new(normal.outputs['Color'],bump.inputs['Color'])
        mat.node_tree.links.new(bump.outputs[0],node.inputs['Normal'])
        mat.use_backface_culling=False
    MATERIALS[name]=mat
    return mat

class Geometry:
    def __init__(self,name):
        self.name=name; self.vertices=[]; self.faces=[]; self.colours=[]; self.slots=[]; self.smooth=[]
        self.materials=[]; self.transform=Matrix.Identity(4); self.uvs=[]; self.bevel_weights=[]
    @contextmanager
    def at(self,position=(0,0,0),angle=0):
        previous=self.transform.copy()
        self.transform=previous @ Matrix.Translation(Vector(position)) @ Matrix.Rotation(angle,4,'Y')
        try: yield self
        finally: self.transform=previous
    def mesh(self,vertices,faces,kind='masonry',colour=IVORY,smooth=False,uvs=None,bevel=False):
        if kind not in self.materials: self.materials.append(kind)
        start=len(self.vertices)
        for vertex in vertices:
            p=self.transform @ Vector(vertex)
            self.vertices.append((p.x,-p.z,p.y))
            self.colours.append((*colour[:3],SURFACE_IDS.get(kind,0)/15.0))
        self.uvs.extend(uvs if uvs is not None else [None]*len(vertices))
        self.bevel_weights.extend([bevel]*len(vertices))
        self.faces.extend(tuple(start+i for i in face) for face in faces)
        self.slots.extend([self.materials.index(kind)]*len(faces)); self.smooth.extend([smooth]*len(faces))
    def box(self,p,size,kind='masonry',colour=IVORY,rotation=None):
        signs=[(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]
        vertices=[Vector((x*size[0]/2,y*size[1]/2,z*size[2]/2)) for x,y,z in signs]
        if rotation is not None: vertices=[rotation @ v for v in vertices]
        self.mesh([Vector(p)+v for v in vertices],[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],kind,colour,bevel=min(size)>=.18 and max(size)>=.75)
    def cylinder(self,a,b,r,kind='metal',colour=STEEL,sides=10,end_radius=None):
        a,b=Vector(a),Vector(b); d=b-a; q=d.to_track_quat('Y','Z').to_matrix()
        r2=r if end_radius is None else end_radius
        vertices=[a+q @ Vector((radius*math.cos(i*math.tau/sides),y,radius*math.sin(i*math.tau/sides))) for y,radius in [(0,r),(d.length,r2)] for i in range(sides)]
        self.mesh(vertices,[(i,i+sides,(i+1)%sides+sides,(i+1)%sides) for i in range(sides)]+[tuple(range(sides)),tuple(reversed(range(sides,2*sides)))],kind,colour,True)
    def beam(self,a,b,width,kind='metal',colour=STEEL,depth=None):
        a,b=Vector(a),Vector(b); delta=b-a
        self.box((a+b)/2,(width,delta.length,width if depth is None else depth),kind,colour,delta.to_track_quat('Y','Z').to_matrix())
    def finish(self):
        mesh=bpy.data.meshes.new(self.name)
        mesh.from_pydata(self.vertices,[],self.faces); mesh.update()
        weights=mesh.attributes.new('bevel_weight_edge','FLOAT','EDGE')
        for edge in mesh.edges:
            weights.data[edge.index].value=1 if all(self.bevel_weights[v] for v in edge.vertices) else 0
        for kind in self.materials: mesh.materials.append(material(kind))
        for face,slot,smooth in zip(mesh.polygons,self.slots,self.smooth): face.material_index=slot; face.use_smooth=smooth
        attr=mesh.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='POINT')
        for value,colour in zip(attr.data,self.colours): value.color=colour
        obj=bpy.data.objects.new(self.name,mesh); bpy.context.collection.objects.link(obj)
        # Explicit planar metre UVs, useful for inspecting and exporting the kit.
        uv=mesh.uv_layers.new(name='UVMap')
        for poly in mesh.polygons:
            axis=max(range(3),key=lambda i:abs(poly.normal[i]))
            axes=[i for i in range(3) if i!=axis]
            for loop in poly.loop_indices:
                p=mesh.vertices[mesh.loops[loop].vertex_index].co
                explicit=self.uvs[mesh.loops[loop].vertex_index]
                uv.data[loop].uv=explicit if explicit is not None else (p[axes[0]],p[axes[1]])
        return obj

def reset():
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)

def box_rim(g,width,depth,y,height=.7,colour=IVORY):
    for x in [-width/2,width/2]: g.box((x,y+height/2,0),(.16,height,depth+.16),'masonry',colour)
    for z in [-depth/2,depth/2]: g.box((0,y+height/2,z),(width,.16 if height<.2 else height,.16),'masonry',colour)

def tank(g,p,r=.62,height=1.08):
    with g.at(p):
        g.cylinder((0,0,0),(0,height,0),r,'detail',DARK,16)
        for y in [.08,.21,height-.20,height-.07]: g.cylinder((0,y-.026,0),(0,y+.026,0),r+.025,'detail',(.085,.095,.085),16)
        g.cylinder((0,height,0),(0,height+.065,0),r*.75,'detail',DARK,16)
        g.cylinder((r*.68,-.1,0),(r*.68,height*.5,0),.034,'detail',(.57,.59,.53),6)

def opening(g,x,y,z,width=1.28,height=1.35,door=False,shutter=False,grill=True,colour=IVORY):
    # Recessed dark backing sits behind a real wall aperture, with thick jambs.
    g.box((x,y+height/2,z+.15),(width,.001+height,.028),'glass' if not door else 'wood',GLASS if not door else WOOD)
    frame=.065
    for xx in [-width/2,width/2]: g.box((x+xx,y+height/2,z-.02),(frame,height+.11,.17),'detail',colour)
    for yy in [0,height]: g.box((x,y+yy,z-.02),(width+.13,frame,.17),'detail',colour)
    if shutter:
        g.box((x,y+height/2,z+.04),(width,height,.055),'metal',(.32,.39,.38))
        for yy in range(max(1,int(height/.13))): g.box((x,y+.07+yy*.13,z-.006),(width,.019,.025),'metal',(.22,.27,.26))
    elif not door:
        g.box((x,y+height/2,z+.03),(.04,height,.065),'detail',colour)
        g.box((x,y+height*.53,z+.03),(width,.034,.065),'detail',colour)
        if grill:
            for i in range(1,6): g.cylinder((x-width/2+i*width/6,y+.04,z-.10),(x-width/2+i*width/6,y+height-.04,z-.10),.012,'metal',(.11,.15,.14),5)
            for h in [.23,.77]: g.box((x,y+height*h,z-.10),(width,.025,.028),'metal',(.11,.15,.14))
    else:
        g.box((x+.12,y+height*.5,z+.105),(.035,.13,.055),'metal',(.55,.53,.43))
    if not shutter:
        g.box((x,y+height+.16,z-.27),(width+.38,.10,.75),'masonry',(.51,.52,.46))
        g.box((x,y-.045,z-.11),(width+.17,.10,.30),'masonry',(.52,.51,.46))

def facade(g,width,y,z,height,windows,colour):
    """Front wall segmented around true openings: [(x,width,bottom,height,kind)]."""
    left=-width/2
    for x,w,bottom,h,kind in sorted(windows):
        edge=x-w/2
        if edge>left: g.box(((left+edge)/2,y+height/2,z+.13),(edge-left,height,.26),'masonry',colour)
        if bottom>0: g.box((x,y+bottom/2,z+.13),(w,bottom,.26),'masonry',colour)
        if height>bottom+h: g.box((x,y+(bottom+h+height)/2,z+.13),(w,height-bottom-h,.26),'masonry',colour)
        opening(g,x,y+bottom,z,w,h,door=kind=='door',shutter=kind=='shutter')
        left=x+w/2
    if left<width/2: g.box(((left+width/2)/2,y+height/2,z+.13),(width/2-left,height,.26),'masonry',colour)

def balcony(g,x,y,z,width=3.0,depth=1.12):
    g.box((x,y,z-depth/2),(width+.25,.18,depth+.22),'masonry',IVORY)
    for xx in [-width/2,width/2]:
        g.beam((x+xx,y+.12,z),(x+xx,y+.12,z-depth),.065)
        g.beam((x+xx,y+1.10,z),(x+xx,y+1.10,z-depth),.045)
    g.box((x,y+1.08,z-depth),(width,.05,.05),'metal',(.16,.20,.18))
    g.box((x,y+.30,z-depth),(width,.03,.035),'metal',(.16,.20,.18))
    for i in range(int(width/.17)+1): g.box((x-width/2+i*.17,y+.65,z-depth),(.019,.88,.022),'metal',(.16,.20,.18))
    for xx in [-width/2+.08,width/2-.08]: g.box((x+xx,y+.28,z-.26),(.32,.40,.32),'roof',(.34,.20,.13))

def ac_unit(g,p):
    with g.at(p):
        g.box((0,0,0),(.75,.52,.32),'detail',(.70,.69,.60))
        g.cylinder((-.16,0,-.171),(-.16,0,-.18),.185,'detail',(.12,.16,.15),16)
        for x in [-.3,-.2,-.1,0,.1]: g.box((x,0,-.186),(.012,.34,.025),'detail',(.46,.49,.45))
        for y in [-.16,-.08,0,.08,.16]: g.box((-.12,y,-.19),(.40,.012,.025),'detail',(.46,.49,.45))
        g.beam((-.30,-.26,.1),(-.30,-.32,.40),.034); g.beam((.30,-.26,.1),(.30,-.32,.40),.034)

def flat_building(name,width,depth,floors,seed,shop=False,corner=False):
    g=Geometry(name); rng=random.Random(seed); paint=PAINTS[seed%len(PAINTS)]; floor=3.15
    g.box((0,.19,0),(width+.28,.38,depth+.28),'masonry',CONCRETE)
    for level in range(floors):
        base=.38+level*floor
        for side in [-1,1]: g.box((side*(width/2-.13),base+floor/2,0),(.26,floor,depth),'masonry',paint)
        bays=max(2,round(width/3.4))
        xs=[-width/2+(i+.5)*width/bays for i in range(bays)]
        front=[]
        for i,x in enumerate(xs):
            if shop and level==0: front.append((x,width/bays-.5,.06,2.50,'shutter' if i%3==0 else 'door'))
            elif i==bays//2 and level==0: front.append((x,1.0,0,2.18,'door'))
            else: front.append((x,1.30,.95,1.42,'window'))
        facade(g,width,base,-depth/2,floor,front,paint)
        with g.at((0,0,0),math.pi): facade(g,width,base,-depth/2,floor,[(x,1.06,1.02,1.22,'window') for x in xs],paint)
        for side in [-1,1]:
            with g.at((side*width/2,base,0), -side*math.pi/2):
                for z in [-depth*.23,depth*.24]: opening(g,z,1.1,-.018,1.00,1.18)
        g.box((0,base+floor-.10,0),(width+.24,.20,depth+.24),'masonry',IVORY)
        if level>0 and (level%2==1 or corner):
            for x in xs[::2]: balcony(g,x,base+.025,-depth/2,2.6)
        if level>0: ac_unit(g,(xs[-1],base+.65,-depth/2-.22))
    roof=.38+floors*floor
    g.box((0,roof,0),(width+.36,.20,depth+.36),'masonry',CONCRETE)
    box_rim(g,width+.22,depth+.22,roof+.10,.64,paint)
    g.box((width*.25,roof+.98,depth*.22),(2.4,1.80,2.8),'masonry',paint)
    g.box((width*.25,roof+1.92,depth*.22),(2.6,.12,3.0),'masonry',IVORY)
    tank(g,(-width*.27,roof+.17,depth*.23),.63,1.15)
    # Service plumbing, raised meter cabinet, ladder to the water tank.
    for side in [-1,1]:
        g.cylinder((side*(width/2+.05),.35,depth*.29),(side*(width/2+.05),roof+.40,depth*.29),.043,'detail',(.50,.52,.47),6)
    g.box((width*.35,1.55,-depth/2-.11),(.30,.44,.15),'metal',(.30,.34,.31))
    for x in [-.26,.26]: g.cylinder((x,.5,depth/2+.13),(x,roof+.4,depth/2+.13),.025,'metal',DARK,6)
    for i in range(int(roof/.30)): g.beam((-.27,.55+i*.30,depth/2+.13),(.27,.55+i*.30,depth/2+.13),.023,'metal',DARK)
    if shop:
        g.box((0,3.10,-depth/2-.08),(width-.16,.68,.12),'sign',(.13,.24,.27))
        awning_colour=[(.27,.38,.32),(.48,.27,.19),(.23,.32,.42)][seed%3]
        g.box((0,2.78,-depth/2-.86),(width+.6,.07,1.80),'metal',awning_colour,Matrix.Rotation(.09,3,'X'))
        for x in [-width/2,width/2]: g.cylinder((x,.2,-depth/2-1.62),(x,2.72,-depth/2-1.62),.036,'metal',STEEL,6)
        g.box((0,.12,-depth/2-.64),(width+.40,.24,1.38),'masonry',CONCRETE)
        for x in xs:
            g.box((x,.75,-depth/2-.35),(1.5,.72,.56),'wood',(.30,.22,.13))
    return g

def tiled_house(name,width=9.2,depth=8.0,seed=0,courtyard=False):
    g=Geometry(name); paint=PAINTS[seed%len(PAINTS)]
    g.box((0,.20,0),(width+.45,.4,depth+.5),'masonry',(.47,.38,.27))
    for side in [-1,1]: g.box((side*(width/2-.13),1.70,0),(.26,3.0,depth),'masonry',paint)
    facade(g,width,.40,-depth/2,2.8,[(-width*.29,1.13,.83,1.25,'window'),(0,1.12,0,2.08,'door'),(width*.29,1.13,.83,1.25,'window')],paint)
    with g.at(angle=math.pi): facade(g,width,.40,-depth/2,2.8,[(-width*.25,1.05,1.0,1.15,'window'),(width*.25,1.05,1.0,1.15,'window')],paint)
    # Closed pitched roof and masonry gables; individual ridge/eave tile profiles.
    eave=3.22; ridge=4.65; half=depth/2+.65; w=width/2+.56
    for side in [-1,1]:
        faces=[(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)]
        if side<0: faces=[tuple(reversed(face)) for face in faces]
        g.mesh([(-w,eave,side*half),(w,eave,side*half),(w,ridge,0),(-w,ridge,0),(-w,eave-.09,side*half),(w,eave-.09,side*half),(w,ridge-.09,0),(-w,ridge-.09,0)],faces,'roof',(.54,.29,.16) if seed%2 else (.48,.26,.15))
        for i in range(round(width/.30)+3):
            x=-w+.14+i*.30
            g.cylinder((x,eave+.025,side*half),(x,eave+.06,side*(half-.30)),.075,'roof',(.46,.24,.12),6)
        g.cylinder((-w,eave-.10,side*half),(w,eave-.10,side*half),.060,'metal',(.23,.24,.20),8)
    for i in range(round(width/.35)+3):
        x=-w+i*.35
        g.cylinder((x,ridge+.02,0),(x+.34,ridge+.02,0),.11,'roof',(.50,.25,.12),8)
    for x in [-width/2,width/2]: g.mesh([(x,3.15,-depth/2),(x,3.15,depth/2),(x,ridge-.06,0)],[(0,1,2),(2,1,0)],'masonry',paint)
    g.box((0,.42,-depth/2-.74),(width-.8,.38,1.5),'masonry',(.53,.34,.22))
    for x in [-width*.38,width*.38]: g.cylinder((x,.62,-depth/2-1.15),(x,2.90,-depth/2-1.15),.08,'wood',WOOD,10)
    g.box((0,2.99,-depth/2-.73),(width+.35,.11,1.8),'roof',(.45,.26,.16),Matrix.Rotation(-.11,3,'X'))
    g.box((0,.1,-depth/2-1.6),(2.3,.2,.7),'masonry',CONCRETE)
    g.cylinder((width/2+.10,.1,depth/2+.20),(width/2+.10,3.18,depth/2+.20),.055,'metal',(.32,.34,.29),8)
    if courtyard:
        for side in [-1,1]:
            g.box((side*(width/2+1.5),.7,0),(.18,1.4,depth+4),'masonry',paint)
            g.box((side*(width/4+1.2),.7,-depth/2-2.0),(width/2+.1,1.4,.18),'masonry',paint)
        g.box((0,.65,-depth/2-2.03),(1.6,1.3,.06),'metal',(.18,.28,.23))
    return g

def warehouse(name,width=19,depth=25,seed=0):
    g=Geometry(name); h=5.5; paint=(.51,.49,.40)
    g.box((0,.20,0),(width+.40,.40,depth+.40),'masonry',CONCRETE)
    g.box((0,h*.5,depth/2),(width,h,.24),'masonry',paint)
    for side in [-1,1]:
        g.box((side*width/2,h*.5,0),(.22,h,depth),'masonry',paint)
        for z in range(-int(depth/2),int(depth/2)+1,4): g.box((side*(width/2+.06),h/2,z),(.25,h,.28),'masonry',(.38,.39,.34))
    facade(g,width,.3,-depth/2,h-.3,[(-width*.22,3.4,.1,3.9,'shutter'),(width*.22,3.4,.1,3.9,'shutter')],paint)
    for side in [-1,1]:
        top=[(-width/2-.5,h,side*(depth/2+.7)),(width/2+.5,h,side*(depth/2+.7)),(width/2+.5,h+1.6,0),(-width/2-.5,h+1.6,0)]
        faces=[(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)]
        if side<0: faces=[tuple(reversed(face)) for face in faces]
        g.mesh(top+[(x,y-.065,z) for x,y,z in top],faces,'metal',(.41,.44,.41))
    for x in range(-int(width/2),int(width/2)+1):
        for side in [-1,1]: g.beam((x,h+.025,side*(depth/2+.7)),(x,h+1.625,0),.035,'metal',(.35,.38,.36))
    g.box((0,4.9,-depth/2-.13),(width*.55,.65,.16),'sign',(.24,.31,.26))
    g.box((0,.36,-depth/2-2.2),(width+.6,.72,4.4),'masonry',CONCRETE)
    for x in [-width*.38,width*.1]:
        for k in range(3): g.box((x,.9+k*.43,-depth/2-1.0),(.85,.40,.65),'wood',(.39,.31,.19))
    return g

def water_tower(name='water_tower'):
    g=Geometry(name)
    for x,z in [(-1.8,-1.8),(1.8,-1.8),(1.8,1.8),(-1.8,1.8)]:
        g.box((x,.22,z),(.85,.44,.85),'masonry',CONCRETE)
        g.box((x,5.2,z),(.36,10.4,.36),'masonry',IVORY)
    for y in [3,6.6,10.1]:
        for side in [-1,1]:
            g.box((side*1.8,y,0),(.30,.28,3.9),'masonry',CONCRETE)
            g.box((0,y,side*1.8),(3.9,.28,.30),'masonry',CONCRETE)
    g.cylinder((0,10.1,0),(0,13.1,0),2.7,'masonry',(.63,.62,.53),32)
    for y in [10.05,13.15]: g.cylinder((0,y-.09,0),(0,y+.09,0),2.85,'masonry',IVORY,32)
    g.cylinder((.7,.1,.8),(.7,13.1,.8),.15,'metal',(.25,.31,.28),10)
    for x in [-.24,.24]: g.cylinder((x,.2,-2.2),(x,13.8,-2.2),.030,'metal',STEEL,6)
    for i in range(43): g.beam((-.25,.3+i*.32,-2.2),(.25,.3+i*.32,-2.2),.025,'metal',STEEL)
    return g

def save(g):
    reset(); obj=g.finish(); bpy.context.view_layer.objects.active=obj; obj.select_set(True)
    if g.name in ['hatchback','auto_rickshaw','local_bus','goods_lorry','tea_kiosk']:
        bevel=obj.modifiers.new('Manufactured rounded edges','BEVEL')
        bevel.width=.025; bevel.segments=2; bevel.harden_normals=True
        bevel.limit_method='ANGLE'; bevel.angle_limit=.7
    elif not any(kind in g.materials for kind in ['bark','leaves','grass','broadleaf']) and not g.name.startswith('passenger_'):
        # Small real edge radii catch daylight without changing metre footprints.
        bevel=obj.modifiers.new('Worn construction edges','BEVEL')
        bevel.width=.012; bevel.segments=2; bevel.harden_normals=True
        bevel.limit_method='WEIGHT'
    for image in bpy.data.images:
        if image.source=='FILE' and image.users: image.pack()
    OUT.mkdir(parents=True,exist_ok=True); MASTERS.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(MASTERS/(g.name+'.blend')),compress=True)
    evaluated=obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh=evaluated.to_mesh(); mesh.calc_loop_triangles()
    coords=[v.co for v in mesh.vertices]
    low=[min(p[i] for p in coords) for i in range(3)]; high=[max(p[i] for p in coords) for i in range(3)]
    unified=not any(kind in g.materials for kind in ['bark','leaves','grass','broadleaf'])
    MANIFEST[g.name]={'triangles':len(mesh.loop_triangles),'surfaces':1 if unified else len(g.materials),'godot_size':[high[0]-low[0],high[2]-low[2],high[1]-low[1]],'godot_min':[low[0],low[2],-high[1]],'godot_max':[high[0],high[2],-low[1]],'materials':g.materials,'surface_ids':SURFACE_IDS if unified else {},'source':'Original project geometry','front':'-Z','units':'metres'}
    evaluated.to_mesh_clear()
    if unified:
        # Keep the editable master's conventional materials. Runtime uses one
        # draw surface, with exact material category encoded in vertex alpha.
        for modifier in list(obj.modifiers): bpy.ops.object.modifier_apply(modifier=modifier.name)
        obj.data.materials.clear(); obj.data.materials.append(material('architecture'))
        for face in obj.data.polygons: face.material_index=0
    bpy.ops.export_scene.gltf(filepath=str(OUT/(g.name+'.glb')),export_format='GLB',use_selection=True,export_apply=True,export_yup=True,export_normals=True,export_texcoords=True,export_materials='EXPORT',export_vertex_color='ACTIVE',export_all_vertex_colors=False)
    # glTF drops degenerate faces during triangulation; report the shipped count.
    data=(OUT/(g.name+'.glb')).read_bytes()
    size=struct.unpack_from('<I',data,12)[0]
    gltf=json.loads(data[20:20+size])
    MANIFEST[g.name]['triangles']=sum(gltf['accessors'][p['indices']]['count']//3 for m in gltf['meshes'] for p in m['primitives'])
    print('SCENERY_ASSET',g.name,MANIFEST[g.name],flush=True)

def main():
    specs=[('shop_row',11.8,9.0,1,2,True),('shop_house',10.4,10.0,2,4,True),('corner_shop',13.0,10.0,3,1,True),('townhouse',8.0,10.4,2,3,False),('apartments_3',17.0,12.0,3,5,False),('apartments_4',18.5,13.0,4,1,False),('railway_quarters',15.0,8.0,1,0,False),('school_block',22.0,9.0,2,0,False)]
    only=None
    if '--' in sys.argv:
        args=sys.argv[sys.argv.index('--')+1:]
        for arg in args:
            if arg.startswith('--only='): only=set(arg[7:].split(','))
    for name,w,d,f,s,shop in specs:
        if only is None or name in only: save(flat_building(name,w,d,f,s,shop,corner=name=='corner_shop'))
    for name,w,d,s,c in [('tiled_house',8.6,7.2,0,False),('courtyard_house',11,9,4,True),('tiled_cottage',6.4,6.6,3,False)]:
        if only is None or name in only: save(tiled_house(name,w,d,s,c))
    for name,w,d,s in [('warehouse',19,25,1),('workshop',12,14,2),('rice_mill',25,34,3)]:
        if only is None or name in only: save(warehouse(name,w,d,s))
    if only is None or 'water_tower' in only: save(water_tower())
    from scenery_props import FACTORIES
    for factory in FACTORIES:
        if only is None or factory.__name__ in only: save(factory())
    from scenery_landmarks import FACTORIES as LANDMARKS
    for factory in LANDMARKS:
        if only is None or factory.__name__ in only: save(factory())
    from scenery_people import FACTORIES as PEOPLE
    for factory in PEOPLE:
        if only is None or factory.__name__ in only: save(factory())
    from scenery_vegetation import FACTORIES as VEGETATION
    for factory in VEGETATION:
        if only is None or factory.__name__ in only: save(factory())
    path=OUT/'manifest.json'
    prior=json.loads(path.read_text()) if path.exists() else {}
    prior.update(MANIFEST)
    path.write_text(json.dumps(prior,indent=2)+'\n')

if __name__=='__main__': main()
