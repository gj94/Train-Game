"""Separate shadow-only geometry; never reduces the visible detailed model."""
import bpy
import bmesh

def export_shadows(visuals, path):
    collection=bpy.data.collections.new('GODOT_SHADOWS')
    bpy.context.scene.collection.children.link(collection)
    material=bpy.data.materials.new('WAP7_ShadowOnly')
    material.diffuse_color=(.1,.1,.1,1)
    material.use_backface_culling=False
    shadows=[]
    for source in visuals:
        mesh=source.data.copy()
        # Optical glazing and label cards must not become solid shadow sheets.
        transparent=set()
        for i,m in enumerate(mesh.materials):
            if m and any(word in m.name.lower() for word in ('glass','decal','_art_','engraved ivory','legend')):
                transparent.add(i)
        bm=bmesh.new(); bm.from_mesh(mesh)
        bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.material_index in transparent],context='FACES')
        # Weld UV/material seams before simplification, keep silhouette boundaries.
        bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001)
        bm.to_mesh(mesh); bm.free()
        for uv in list(mesh.uv_layers): mesh.uv_layers.remove(uv)
        mesh.materials.clear(); mesh.materials.append(material)
        for p in mesh.polygons: p.material_index=0
        ob=bpy.data.objects.new('Shadow_'+source.name,mesh)
        collection.objects.link(ob)
        dec=ob.modifiers.new('Shadow silhouette only','DECIMATE')
        dec.ratio=.12 if 'PANTO' in source.name else .025
        dec.use_collapse_triangulate=True
        shadows.append(ob)
    bpy.ops.object.select_all(action='DESELECT')
    for ob in shadows: ob.select_set(True)
    bpy.context.view_layer.objects.active=shadows[0]
    bpy.context.view_layer.update()
    dg=bpy.context.evaluated_depsgraph_get()
    triangles=0
    for ob in shadows:
        evaluated=ob.evaluated_get(dg); mesh=evaluated.to_mesh()
        triangles+=sum(len(p.vertices)-2 for p in mesh.polygons)
        evaluated.to_mesh_clear()
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
        export_yup=True,export_animations=False,export_cameras=False,export_lights=False,
        export_apply=True,export_texcoords=False,export_normals=False,export_vertex_color='NONE')
    return triangles
