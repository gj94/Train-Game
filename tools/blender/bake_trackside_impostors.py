"""Multi-view albedo/normal impostors of the actual source; background only."""
import bpy
import json
import math
import sys
from pathlib import Path
from mathutils import Vector
import numpy as np

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/models/trackside/impostors'
TILE=256
VIEWS=int(next((a[8:] for a in sys.argv if a.startswith('--views=')),'8'))
COLUMNS=8 if VIEWS>=32 else 4
ROWS=VIEWS//COLUMNS
SAMPLES=int(next((a[10:] for a in sys.argv if a.startswith('--samples=')),'1'))
OUT=Path(next((a[9:] for a in sys.argv if a.startswith('--output=')),str(OUT)))
assert VIEWS in (8,16,32,64) and SAMPLES>=1
NAMES=['BLD_Home_Verandah_01','BLD_Cottage_Hipped_01','BLD_Home_Concrete_01',
       'BLD_TeaShop_Open_01','BLD_Workshop_Corrugated_01','BLD_CoirYard_Shed_01',
       'KL_LS_Coconut_Tall_A','KL_LS_Coconut_Leaning_B','KL_LS_Coconut_Juvenile_C',
       'KL_LS_Jackfruit_Tree','KL_LS_Banana_Clump','KL_LS_Pandanus_Clump',
       'KL_LS_Colocasia_Clump','KL_LS_Fern_Clump']


def bake(name):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/models/trackside'/(name+'.gltf')))
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
    vertices=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
    lo=Vector([min(v[i] for v in vertices) for i in range(3)])
    hi=Vector([max(v[i] for v in vertices) for i in range(3)])
    centre=(lo+hi)*.5
    radius=max(math.hypot(v.x-centre.x,v.y-centre.y) for v in vertices)
    side=max(radius*2.08,(hi.z-lo.z)*1.06)
    scene=bpy.context.scene
    scene.render.engine='CYCLES'
    scene.cycles.samples=SAMPLES
    scene.cycles.use_denoising=False
    scene.render.resolution_x=TILE;scene.render.resolution_y=TILE
    scene.render.resolution_percentage=100;scene.render.film_transparent=True
    scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
    scene.view_settings.view_transform='Standard';scene.view_settings.look='None'
    scene.world=bpy.data.worlds.new('Transparent world')
    data=bpy.data.cameras.new('Impostor camera');cam=bpy.data.objects.new('Impostor camera',data)
    scene.collection.objects.link(cam);scene.camera=cam
    data.type='ORTHO';data.ortho_scale=side
    materials=list({m for o in objects for m in o.data.materials if m})
    channels={}
    for m in materials:
        p=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
        channels[m.name]={key:(p.inputs[key].links[0].from_socket if p.inputs[key].is_linked else tuple(p.inputs[key].default_value) if key=='Base Color' else p.inputs[key].default_value) for key in ['Base Color','Alpha']}
    for mode in ['albedo','normal']:
        atlas=np.zeros((TILE*ROWS,TILE*COLUMNS,4),dtype=np.float32)
        for m in materials:
            nodes=m.node_tree.nodes;links=m.node_tree.links
            output=next(n for n in nodes if n.type=='OUTPUT_MATERIAL')
            emission=nodes.new('ShaderNodeEmission')
            if mode=='albedo':
                source=channels[m.name]['Base Color']
                if isinstance(source,tuple):emission.inputs['Color'].default_value=source
                else:links.new(source,emission.inputs['Color'])
            else:
                normal=nodes.new('ShaderNodeNewGeometry');split=nodes.new('ShaderNodeSeparateXYZ')
                links.new(normal.outputs['Normal'],split.inputs[0]);combine=nodes.new('ShaderNodeCombineXYZ')
                for a,b,s in [('X','X',.5),('Z','Y',.5),('Y','Z',-.5)]:
                    multiply=nodes.new('ShaderNodeMath');multiply.operation='MULTIPLY_ADD'
                    multiply.inputs[1].default_value=s;multiply.inputs[2].default_value=.5
                    links.new(split.outputs[a],multiply.inputs[0]);links.new(multiply.outputs[0],combine.inputs[b])
                links.new(combine.outputs[0],emission.inputs['Color'])
            alpha=channels[m.name]['Alpha']
            if not isinstance(alpha,float) or alpha<.999:
                transparent=nodes.new('ShaderNodeBsdfTransparent');mix=nodes.new('ShaderNodeMixShader')
                if isinstance(alpha,float):mix.inputs[0].default_value=alpha
                else:links.new(alpha,mix.inputs[0])
                links.new(transparent.outputs[0],mix.inputs[1]);links.new(emission.outputs[0],mix.inputs[2])
                links.new(mix.outputs[0],output.inputs['Surface'])
            else:links.new(emission.outputs[0],output.inputs['Surface'])
        for angle in range(VIEWS):
            theta=angle*math.tau/VIEWS
            cam.location=centre+Vector((math.sin(theta)*50,-math.cos(theta)*50,0))
            cam.rotation_euler=(centre-cam.location).to_track_quat('-Z','Y').to_euler()
            scratch=ROOT/'.local'
            scratch.mkdir(parents=True,exist_ok=True)
            path=scratch/'impostor-tile.png'
            scene.render.filepath=str(path);bpy.ops.render.render(write_still=True)
            image=bpy.data.images.load(str(path),check_existing=False)
            pixels=np.empty(TILE*TILE*4,dtype=np.float32);image.pixels.foreach_get(pixels)
            bpy.data.images.remove(image)
            atlas[(angle//COLUMNS)*TILE:(angle//COLUMNS+1)*TILE,(angle%COLUMNS)*TILE:(angle%COLUMNS+1)*TILE]=pixels.reshape(TILE,TILE,4)
        image=bpy.data.images.new(name+'_'+mode,width=TILE*COLUMNS,height=TILE*ROWS,alpha=True,float_buffer=False)
        image.alpha_mode='STRAIGHT';image.colorspace_settings.name='sRGB'
        image.pixels.foreach_set(atlas.ravel());image.filepath_raw=str(OUT/(name+'_'+mode+'.png'))
        image.file_format='PNG';image.save()
    return dict(width=side,centre=[centre.x,centre.z,-centre.y],views=VIEWS,columns=COLUMNS,tile_pixels=TILE,samples=SAMPLES)


if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True)
    path=OUT/'catalog.json';catalog=json.loads(path.read_text()) if path.exists() else {}
    only=next((a[7:].split(',') for a in sys.argv if a.startswith('--only=')),NAMES)
    for name in only:
        catalog['tf3_'+name]=bake(name)
        path.write_text(json.dumps(catalog,indent=2)+'\n')
        print('BAKED',name,flush=True)
