"""Bake small carriage-local clearance grids from the pinned visible masters.

Background Blender only. The visual masters are never changed or re-exported.
Floor rays and overlapping body spheres retain seats, partitions and equipment
as obstacles; no detailed render meshes become runtime physics colliders.
"""
import bpy, hashlib, json, math, sys
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
sys.path.insert(0, str(Path(__file__).parent))
import passage_clearance

ROOT = Path(__file__).resolve().parents[2]
OPEN = '--open-passages' in sys.argv
STEP = .04 if OPEN else .08
STEP_OVERRIDE = next((float(arg.split('=',1)[1]) for arg in sys.argv if arg.startswith('--step=')),None)
RADIUS = .16
HEIGHTS = (1.72, 1.08)
OUT = ROOT / ('data/interiors/walkways_open.json' if OPEN else 'data/interiors/walkways.json')


def bake(entry, folder, pin):
    global STEP
    STEP = STEP_OVERRIDE or ((.02 if entry['id']=='icf_1a' else .04) if OPEN else .08)
    path = ROOT / folder / entry['path']
    raw = path.read_bytes()
    expected = next(p['sha'] for p in pin['files'] if p['path'] == entry['path'])
    assert hashlib.sha1(f'blob {len(raw)}\0'.encode()+raw).hexdigest() == expected
    bpy.ops.wm.open_mainfile(filepath=str(path), load_ui=False, use_scripts=False)
    key = entry['id']
    root = next(o for o in bpy.data.objects if o.type == 'EMPTY' and not o.parent and 'ROOT' in o.name.upper())
    graph = bpy.context.evaluated_depsgraph_get()
    verts, faces, floor_verts, floor_faces = [], [], [], []
    owners = []
    open_parts = []
    def passage_leaf(name):
        name=name.lower()
        if key.startswith('icf_'):
            return name.startswith(('end door clear window','end glazed door','end sliding door','vestibule door grab pull'))
        if key.startswith('vb_'):
            return ('saloon_door_leaf' in name or 'saloon_glass' in name or 'saloon_clear_sliding_glass' in name or (key!='vb_dtc' and ('service_removable_closed_door' in name or 'service_door_kickplate' in name or 'service_door_lever' in name or 'service_door_lock_escutcheon' in name)))
        return False

    for ob in root.children_recursive:
        if ob.type not in {'MESH', 'FONT', 'CURVE'} or ob.hide_render or any(c.hide_render for c in ob.users_collection):
            continue
        bounds = [ob.matrix_world @ Vector(p) for p in ob.bound_box]
        if max(p.z for p in bounds) < 1.15 or min(p.z for p in bounds) > 3.7:
            continue
        if min(p.y for p in bounds) > 1.6 or max(p.y for p in bounds) < -1.6:
            continue
        evaluated = ob.evaluated_get(graph)
        mesh = evaluated.to_mesh()
        if not mesh: continue
        mesh.calc_loop_triangles()
        world = [passage_clearance.position(key, ob.name, ob.matrix_world @ v.co) for v in mesh.vertices]
        if OPEN and passage_leaf(ob.name):
            # Source objects can contain BOTH distant door leaves. Split by
            # connected mesh component before deriving local clipping boxes.
            neighbours=[[] for _ in mesh.vertices]
            for edge in mesh.edges:
                a,b=edge.vertices;neighbours[a].append(b);neighbours[b].append(a)
            unseen=set(range(len(world)))
            while unseen:
                todo=[unseen.pop()]; ids=[]
                while todo:
                    at=todo.pop();ids.append(at)
                    for near in neighbours[at]:
                        if near in unseen:unseen.remove(near);todo.append(near)
                pts=[world[i] for i in ids]
                lo=[min(v[i] for v in pts) for i in range(3)]
                hi=[max(v[i] for v in pts) for i in range(3)]
                open_parts.append(dict(name=ob.name,lo=lo,hi=hi))
            evaluated.to_mesh_clear()
            continue
        offset = len(verts)
        verts.extend(world)
        faces.extend(tuple(offset+i for i in t.vertices) for t in mesh.loop_triangles)
        owners.append((len(faces),ob.name))
        # Use named structural walking surfaces, not seat tops, as the floor.
        if any(s in ob.name.lower() for s in ['floor', 'walkway', 'footplate', 'anti-slip mat']+(['bridge'] if OPEN else [])):
            offset = len(floor_verts)
            floor_verts.extend(world)
            for t in mesh.loop_triangles:
                pts = [world[i] for i in t.vertices]
                normal = (pts[1]-pts[0]).cross(pts[2]-pts[0]).normalized()
                # Some source slabs have reversed winding; floor support is two-sided.
                if abs(normal.z) > .6 and all(1.20 <= p.z <= 1.95 for p in pts):
                    floor_faces.append(tuple(offset+i for i in t.vertices))
        evaluated.to_mesh_clear()
    assert floor_faces, key + ': no floor geometry'
    hull = BVHTree.FromPolygons(verts, faces, all_triangles=True)
    floor = BVHTree.FromPolygons(floor_verts, floor_faces, all_triangles=True)
    length = 19.0 if key == 'wap7' else ((22.08 if key.startswith('icf_') else 24.0) if OPEN else (21.12 if key.startswith('icf_') else 23.52))
    width, rows = round(2.96/STEP) | 1, math.ceil(length/STEP)
    # Godot local (x,z) = Blender (-y,-x).
    origin = [-width*STEP/2, -rows*STEP/2]
    masks = [[], []]
    floor_rows = []
    for row in range(rows):
        line = ['', '']; levels = []
        for col in range(width):
            gx, gz = origin[0]+(col+.5)*STEP, origin[1]+(row+.5)*STEP
            x, y = -gz, -gx
            hit, normal, _, _ = floor.ray_cast(Vector((x,y,2.0)),Vector((0,0,-1)),.85)
            level = hit.z if hit else 0
            levels.append(round(level*1000))
            for state, height in enumerate(HEIGHTS):
                clear = hit is not None
                if clear:
                    # A ray prevents accepting cells deep inside a closed seat/cabinet.
                    top, _, hit_index, _ = hull.ray_cast(Vector((x,y,level+height)),Vector((0,0,-1)),height+.04)
                    clear = top is not None and top.z <= level+.10
                    if '--trace' in sys.argv and abs(x)<.05 and abs(y)<.6 and state==0:
                        print('TRACE',key,round(y,2),'floor',level,'top',top,'owner',next((name for end,name in owners if hit_index is not None and hit_index<end),''),flush=True)
                if clear:
                    count = math.ceil((height-2*RADIUS-.05)/.08)
                    for h in [RADIUS+.05+i*(height-2*RADIUS-.05)/count for i in range(count+1)]:
                        nearest, _, _, distance = hull.find_nearest(Vector((x,y,level+h)),RADIUS+.006)
                        if nearest is not None and distance < RADIUS+.005:
                            clear = False; break
                line[state] += '1' if clear else '0'
        line[1] = ''.join('1' if a=='1' or b=='1' else '0' for a,b in zip(*line))
        for state in range(2): masks[state].append(line[state])
        floor_rows.append(levels)
    side_doors = []
    for ob in root.children_recursive:
        if 'door_header' in ob.name.lower() and ob.name.lower().startswith(('cabin','coupe')):
            points = [ob.matrix_world @ Vector(p) for p in ob.bound_box]
            centre = sum(points, Vector()) / len(points)
            side_doors.append([round(-centre.y,4), round(-centre.x,4)])
    result = dict(step=STEP,radius=RADIUS,heights=list(HEIGHTS),origin=origin,width=width,side_doors=side_doors,
                  standing=masks[0],crouching=masks[1],floor_mm=floor_rows,
                  source_sha256=hashlib.sha256(raw).hexdigest(),source_revision=pin['revision'])
    if key in passage_clearance.MODELS:result['passage_clearance_revision']=passage_clearance.REVISION
    if OPEN:
        # Merge components belonging to the same transverse doorway, retaining
        # the wall jambs, headers, exterior doors and toilet/crew-room partitions.
        groups=[]
        for part in sorted(open_parts,key=lambda p:(p['lo'][0]+p['hi'][0])/2):
            mid=(part['lo'][0]+part['hi'][0])/2
            group=next((g for g in groups if abs(g['mid']-mid)<.60),None)
            if group is None:
                group=dict(mid=mid,lo=part['lo'][:],hi=part['hi'][:],parts=[]);groups.append(group)
            group['lo']=[min(a,b) for a,b in zip(group['lo'],part['lo'])]
            group['hi']=[max(a,b) for a,b in zip(group['hi'],part['hi'])]
            group['parts'].append(part['name'])
        result['open_doors']=[dict(lo=[-g['hi'][1]-.003,g['lo'][2]-.003,-g['hi'][0]-.003],hi=[-g['lo'][1]+.003,g['hi'][2]+.003,-g['lo'][0]+.003],parts=sorted(set(g['parts']))) for g in groups]
        result['gangway_ends']=[] if key=='wap7' else ([1] if key=='vb_dtc' else [-1,1])
        result['gangway_floor']=1.296 if key.startswith('icf_') else (1.325 if key.startswith('vb_') else 1.34)
        result['gangway_join']=10.80 if key.startswith('icf_') else (11.76 if key.startswith('lhb_') else 11.65)
        if key!='wap7':
            row=int((result['gangway_join']-origin[1])/STEP);col=int(-origin[0]/STEP)
            result['gangway_floor']=floor_rows[row][col]*.001
            assert 1.2<result['gangway_floor']<1.95
        assert len(groups)<=8, key+': too many passenger doorway groups'
    assert sum(s.count('1') for s in masks[0]) > 30, key + ': no usable walking clearance'
    print('WALK_BAKED',key,'standing',sum(s.count('1') for s in masks[0]),'crouch',sum(s.count('1') for s in masks[1]),flush=True)
    return result


selected = [arg for arg in sys.argv[sys.argv.index('--')+1:] if not arg.startswith('--')] if '--' in sys.argv else []
result = json.loads(OUT.read_text(encoding='utf-8')) if OUT.exists() else {}
for family, folder in [('coach','.local/coach-v02-source'),('vb','.local/vb-v02-source'),('wap7','.local/wap7-v02-source')]:
    pin = json.loads((ROOT/f'tools/{family}_v02_sources.json').read_text())
    for entry in pin['models']:
        if selected and entry['id'] not in selected: continue
        result[entry['id']] = bake(entry,folder,pin)
        OUT.parent.mkdir(parents=True,exist_ok=True)
        OUT.write_text(json.dumps(result,separators=(',',':'))+'\n',encoding='utf-8')
