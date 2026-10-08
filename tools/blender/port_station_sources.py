"""Port the pinned station buildings/interiors at full geometry resolution.

The authoring yards remain in the hash-verified masters: their static tracks,
signals and platform polygons cannot replace the live operating graph. This
export keeps whole architectural assemblies, including their original text,
fittings, bevels, glass and source material graphs; no geometry decimation.
Run in background Blender only. Source scripts/auto-execution stay disabled.
"""
import bpy
import hashlib
import json
import math
import sys
from pathlib import Path
from mathutils import Matrix, Vector

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path(__file__).parent))
from wap7_materials import export_materials
from wap7_shadows import export_shadows
from split_gltf_buffers import split_glb

SELECTION={
 'ers':['01 |','02 |','03 |','04 |','16 |','19 |'],
 'tvc':['01_','02_','03_','04_','05_','06_','18_','24_','80_'],
 'ncj':['01_','02_','03_','04_','05_','10_','11_','12_','13_'],
 'ers_east':['11 |','16 |','19 |'],
 'ers_workshop':['15 |']}

def export(code):
    station=code.split('_')[0]
    source=ROOT/'.local/station-v02-source/south_indian_stations_v02'/station/(station.upper()+'_full_station_v02.blend')
    expected=json.loads((Path(str(source)+'.parts')/'manifest.json').read_text())
    assert hashlib.sha256(source.read_bytes()).hexdigest()==expected['sha256'],'Source master changed'
    bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False,use_scripts=False)
    key='station_'+code
    out=ROOT/'assets/models/ported'
    detail=out/(key+'_detail');detail.mkdir(parents=True,exist_ok=True)
    members=[];excluded=[]
    for ob in bpy.data.objects:
        if ob.type not in {'MESH','FONT','CURVE'} or ob.hide_render:continue
        if not any(any(c.name.startswith(p) for p in SELECTION[code]) and not c.hide_render for c in ob.users_collection):continue
        # ERS finishing collections also contain distant east-hall fittings.
        # Their intact assembly is retained in the master, not scattered here.
        bounds=[ob.matrix_world@Vector(v) for v in ob.bound_box]
        if code=='ers' and min(v.y for v in bounds)>25:
            excluded.append(ob.name);continue
        if code=='ers_east' and max(v.y for v in bounds)<90:
            excluded.append(ob.name);continue
        members.append(ob)
    coll=bpy.data.collections.new('GODOT_STATION');bpy.context.scene.collection.children.link(coll)
    groups={}
    for ob in members:
        p=ob.matrix_world.translation
        groups.setdefault((math.floor(p.x/32),math.floor(p.y/32)),[]).append(ob)
    mats={};sources={};frames={};all_bounds=[];triangles=0
    dg=bpy.context.evaluated_depsgraph_get()
    inverse=Matrix.Rotation(math.pi/2,4,'X')
    for cell,objects in sorted(groups.items()):
        vertices=[];faces=[];normals=[];uvs=[];coords=[];gens=[];indices=[];slots=[]
        for ob in objects:
            ev=ob.evaluated_get(dg);mesh=ev.to_mesh(preserve_all_data_layers=True,depsgraph=dg)
            if not mesh or not mesh.vertices:ev.to_mesh_clear();continue
            matrix=ob.matrix_world;normal_matrix=matrix.to_3x3().inverted().transposed()
            offset=len(vertices)
            world=[matrix@v.co for v in mesh.vertices]
            vertices.extend(tuple(v) for v in world);all_bounds.extend(world)
            minimum=Vector([min(v.co[a] for v in mesh.vertices) for a in range(3)])
            extent=Vector([max(v.co[a] for v in mesh.vertices) for a in range(3)])-minimum
            uv=mesh.uv_layers.active
            for poly in mesh.polygons:
                mat=mesh.materials[poly.material_index] if poly.material_index<len(mesh.materials) else None
                assert mat and mat.use_nodes,ob.name+' missing node material'
                if mat.name not in mats:
                    sources[mat.name]=mat;copy=mat.copy();copy.name=key+'_'+mat.name
                    copy.use_backface_culling=mat.use_backface_culling
                    mats[mat.name]=copy
                copy=mats[mat.name]
                if copy not in slots:slots.append(copy)
                faces.append(tuple(offset+v for v in poly.vertices));indices.append(slots.index(copy));triangles+=len(poly.vertices)-2
                for loop in poly.loop_indices:
                    normals.append(tuple((normal_matrix@mesh.corner_normals[loop].vector).normalized()))
                    uvs.append(tuple(uv.data[loop].uv) if uv else (0,0))
                    v=mesh.vertices[mesh.loops[loop].vertex_index].co
                    gen=[(v[a]-minimum[a])/extent[a] if extent[a]>1e-9 else 0 for a in range(3)]
                    coords.append((*v,gen[2]));gens.append(gen[:2])
            ev.to_mesh_clear()
        if not faces:continue
        name='StationTile_%d_%d'%cell
        mesh=bpy.data.meshes.new(name);mesh.from_pydata(vertices,[],faces)
        for mat in slots:mesh.materials.append(mat)
        for p,i in zip(mesh.polygons,indices):p.material_index=i;p.use_smooth=True
        mesh.normals_split_custom_set(normals)
        for name_uv,values in [('UVMap',uvs),('GeneratedXY',gens),('ObjectXY',[c[:2] for c in coords]),('ObjectZ_GeneratedZ',[c[2:] for c in coords])]:
            layer=mesh.uv_layers.new(name=name_uv);layer.data.foreach_set('uv',[v for row in values for v in row])
        mesh.uv_layers.active_index=0
        visual=bpy.data.objects.new(name,mesh);coll.objects.link(visual)
        frames[name]=[list(row) for row in inverse]
    shaders=export_materials(sources.values(),detail/'textures',key)
    (detail/'shaders').mkdir(exist_ok=True)
    for entry in shaders:(detail/'shaders'/entry['shader']).write_text(entry['code'],encoding='utf-8')
    (detail/'materials.json').write_text(json.dumps({'materials':[{k:v for k,v in e.items() if k!='code'} for e in shaders],'frames':frames},indent=2)+'\n',encoding='utf-8')
    bpy.ops.object.select_all(action='DESELECT')
    for ob in coll.objects:ob.select_set(True)
    bpy.context.view_layer.objects.active=next(iter(coll.objects))
    temp=ROOT/'.local'/(key+'-export.glb')
    bpy.ops.export_scene.gltf(filepath=str(temp),export_format='GLB',use_selection=True,export_yup=True,export_animations=False,export_cameras=False,export_lights=False,export_extras=False,export_materials='EXPORT',export_vertex_color='NONE',export_attributes=True)
    dependencies=split_glb(temp,out/(key+'.glb'))
    shadows=export_shadows(list(coll.objects),detail/'shadows.glb')
    report={'source_revision':'1585bc27960fb67d970a1b5c75208ddf53597191','source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'source_objects':len(members),'triangles':triangles,'tiles':len(frames),'materials':len(shaders),'shadow_triangles':shadows,'dependencies':dependencies,'source_bounds':[[min(v[a] for v in all_bounds) for a in range(3)],[max(v[a] for v in all_bounds) for a in range(3)]],'collections':SELECTION[code],'excluded_remote_finishing_objects':excluded,'scope':'Full-resolution entrance architecture, furnished interiors and attached forecourt; operational yard is the simulation graph.'}
    (detail/'provenance.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('STATION_PORT',code,len(members),triangles,len(frames),'tiles',flush=True)

for code in sys.argv[sys.argv.index('--')+1:]:export(code.lower())
