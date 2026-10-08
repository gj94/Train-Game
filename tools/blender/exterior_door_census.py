import bpy, json, hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
result={}
for family,folder in [('coach','.local/coach-v02-source'),('vb','.local/vb-v02-source'),('wap7','.local/wap7-v02-source')]:
    pin=json.loads((ROOT/f'tools/{family}_v02_sources.json').read_text())
    for entry in pin['models']:
        path=ROOT/folder/entry['path']
        raw=path.read_bytes()
        expected=next(p['sha'] for p in pin['files'] if p['path']==entry['path'])
        assert hashlib.sha1(f'blob {len(raw)}\0'.encode()+raw).hexdigest()==expected
        bpy.ops.wm.open_mainfile(filepath=str(path),load_ui=False,use_scripts=False)
        doors=[]; candidates=[]
        for ob in bpy.data.objects:
            if ob.type!='MESH' or 'door' not in ob.name.lower(): continue
            points=[ob.matrix_world @ Vector(p) for p in ob.bound_box]
            centre=sum(points,Vector())/8
            size=[max(p[i] for p in points)-min(p[i] for p in points) for i in range(3)]
            if abs(centre.y)>1.4 and size[2]>1.5: candidates.append([ob.name,list(centre),size])
            if abs(centre.y)<1.5 or not .5<size[0]<1.3 or size[1]>.15 or size[2]<1.7: continue
            point=[round(-centre.y,4),round(-centre.x,4)]
            if any(abs(d['point'][0]-point[0])<.15 and abs(d['point'][1]-point[1])<.25 for d in doors): continue
            doors.append(dict(point=point,source_object=ob.name))
        if entry['id'].startswith('lhb_'):
            jambs=[d for d in candidates if d[0].startswith('DOOR_portal_jamb')]
            for yside in [-1,1]:
                side=sorted([d for d in jambs if d[1][1]*yside>0],key=lambda d:d[1][0])
                assert len(side)%2==0,(entry['id'],side)
                for i in range(0,len(side),2):
                    pair=side[i:i+2]
                    doors.append(dict(point=[round(-sum(d[1][1] for d in pair)/2,4),round(-sum(d[1][0] for d in pair)/2,4)],source_object=' + '.join(d[0] for d in pair)))
        assert len(doors)>=4,(entry['id'],candidates)
        result[entry['id']]=dict(doors=doors,source_sha256=hashlib.sha256(raw).hexdigest(),revision=pin['revision'])
        print('DOORS',entry['id'],len(doors),flush=True)
(ROOT/'data/interiors/exterior_doors.json').write_text(json.dumps(result,indent=2)+'\n')
