"""Prepare Rico Cilliers' CC0 Tree Small 02 for the game; source stays in .local.

Run fetch-scenery-tree.ps1 first. Explicit existing meshes only, no embedded
scripts, simulation or geometry-node evaluation is used. Original source URLs
and verified hashes accompany the derivative. Photographic texture pixels retain
their CC0 attribution; this asset is not represented as original project art.
"""
import bpy, json, sys, hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path(__file__).resolve().parent))
CACHE=ROOT/'.local/polyhaven-tree'
OUT=ROOT/'assets/models/scenery'
bpy.ops.wm.open_mainfile(filepath=str(CACHE/'tree_small_02_1k.blend'))
keepers=[bpy.data.objects['tree_small_02_LOD1'],bpy.data.objects['tree_small_02_trunk']]
for obj in list(bpy.data.objects):
    if obj not in keepers: bpy.data.objects.remove(obj,do_unlink=True)
for obj in keepers:
    if obj.name not in bpy.context.scene.collection.objects: bpy.context.scene.collection.objects.link(obj)
    bpy.context.view_layer.update()
    obj.hide_set(False); obj.hide_viewport=False; obj.hide_render=False
    obj.select_set(True); bpy.context.view_layer.objects.active=obj
    for modifier in list(obj.modifiers): bpy.ops.object.modifier_apply(modifier=modifier.name)
    simplify=obj.modifiers.new('Game silhouette-preserving reduction','DECIMATE')
    simplify.ratio=.12 if 'LOD1' in obj.name else .22
    bpy.ops.object.modifier_apply(modifier=simplify.name)
    obj.select_set(False)

def image(name):
    im=bpy.data.images.load(str(CACHE/'textures'/name),check_existing=True)
    return im

for material in bpy.data.materials:
    if material.name.endswith('_branches'): prefix='tree_small_02_branch'; diff_ext='png'; rough_ext='png'; normal_ext='png'
    elif material.name.endswith('_leaves'): prefix='tree_small_02_leaves'; diff_ext='png'; rough_ext='png'; normal_ext='png'
    else: prefix='tree_small_02'; diff_ext='jpg'; rough_ext='exr'; normal_ext='exr'
    material.use_nodes=True; material.use_backface_culling=False
    nodes=material.node_tree.nodes; nodes.clear(); links=material.node_tree.links
    output=nodes.new('ShaderNodeOutputMaterial'); principled=nodes.new('ShaderNodeBsdfPrincipled')
    links.new(principled.outputs[0],output.inputs['Surface'])
    for role,ext,socket in [('diff',diff_ext,'Base Color'),('rough',rough_ext,'Roughness')]:
        node=nodes.new('ShaderNodeTexImage'); node.image=image(f'{prefix}_{role}_1k.{ext}')
        if role=='rough': node.image.colorspace_settings.name='Non-Color'
        links.new(node.outputs['Color'],principled.inputs[socket])
    normal=nodes.new('ShaderNodeTexImage'); normal.image=image(f'{prefix}_nor_gl_1k.{normal_ext}'); normal.image.colorspace_settings.name='Non-Color'
    bump=nodes.new('ShaderNodeNormalMap'); bump.inputs['Strength'].default_value=.6
    links.new(normal.outputs['Color'],bump.inputs['Color']); links.new(bump.outputs['Normal'],principled.inputs['Normal'])
    if prefix.endswith('_leaves'):
        # The source diffuse already contains this exact cutout alpha. Keeping
        # RGB and alpha on one image avoids the glTF exporter's 16-bit channel
        # recombination, which encoded this source's RGB as linear byte values.
        diffuse=principled.inputs['Base Color'].links[0].from_node
        links.new(diffuse.outputs['Alpha'],principled.inputs['Alpha'])
    material.name='PH_'+material.name
for obj in keepers: obj.select_set(True)
bpy.context.view_layer.objects.active=keepers[0]
bpy.ops.object.join()
tree=bpy.context.object; tree.name='tree_small_02'; tree.location=(0,0,0)
# The branch material uses the source's second UV layer. Fold it into the first
# layer per face so both Blender and the glTF/Godot material use the same mapping.
if 'UV_map_01' in tree.data.uv_layers:
    destination=tree.data.uv_layers['UVMap']
    branch_uv=tree.data.uv_layers['UV_map_01']
    for poly in tree.data.polygons:
        if tree.data.materials[poly.material_index].name.endswith('_branches'):
            for loop in poly.loop_indices: destination.data[loop].uv=branch_uv.data[loop].uv
    tree.data.uv_layers.remove(branch_uv)
tree.data.calc_loop_triangles()
triangles=len(tree.data.loop_triangles)
print('PREPARED_PH_TREE',triangles,'triangles','dimensions',list(tree.dimensions),flush=True)
# Pack the derivative master so it remains editable without machine-specific paths.
for im in bpy.data.images:
    if im.source=='FILE' and im.has_data: im.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/scenery/tree_small_02_adapted.blend'),compress=True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'tree_small_02.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True,export_image_format='AUTO')
from bake_scenery_impostors import bake
catalog_path=OUT/'impostors/catalog.json'
catalog=json.loads(catalog_path.read_text())
catalog['tree_small_02']=bake(prepared=tree)
catalog_path.write_text(json.dumps(catalog,indent=2)+'\n')
record=json.loads((CACHE/'provenance.json').read_text(encoding='utf-8-sig'))
record['adaptation']={'triangles':triangles,'source_mesh':'tree_small_02_LOD1 + tree_small_02_trunk','reduction_ratios':[.12,.22],'tool':'tools/blender/prepare_ph_tree.py','units':'metres','original_species':'Burkea africana; used as an ornamental broadleaf asset, not labelled mango or native vegetation'}
record['runtime_sha256']=hashlib.sha256((OUT/'tree_small_02.glb').read_bytes()).hexdigest()
(OUT/'tree_small_02-provenance.json').write_text(json.dumps(record,indent=2)+'\n')
print('PH_TREE_IMPOSTOR',catalog['tree_small_02'],flush=True)
