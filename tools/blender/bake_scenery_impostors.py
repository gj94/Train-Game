"""Bake tree geometry to eight-view colour/normal atlases, background only.

Original trees use original geometry/colours. The optional prepared Poly Haven
tree retains its registered CC0 photographic textures. Near trees use the GLB;
far trees keep their silhouette and lighting with a small set of billboard faces.
"""
import bpy, math, json, sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path(__file__).resolve().parent))
from build_scenery import reset
from scenery_vegetation import coconut_palm, young_palm, mango_tree, rain_tree
OUT=ROOT/'assets/models/scenery/impostors'
TILE=384

def bake(factory=None,prepared=None):
    if prepared is None:
        reset(); geometry=factory(); obj=geometry.finish()
    else:
        obj=prepared
        class GeometryName: name=obj.name
        geometry=GeometryName()
    sources={}
    if prepared is not None:
        for mat in obj.data.materials:
            principled=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
            colour=principled.inputs['Base Color'].links[0].from_node.image
            alpha_link=principled.inputs['Alpha'].links[0] if principled.inputs['Alpha'].is_linked else None
            alpha=(alpha_link.from_node.image,alpha_link.from_socket.name) if alpha_link else None
            sources[mat.name]=(colour,alpha)
    vertices=[v.co for v in obj.data.vertices]
    radius=max(math.hypot(v.x,v.y) for v in vertices)
    height=max(v.z for v in vertices)
    side=max(radius*2.15,height*1.10)
    centre=Vector((0,0,height*.5))
    scene=bpy.context.scene
    scene.render.engine='CYCLES'
    scene.cycles.device='CPU'; scene.cycles.samples=12
    scene.cycles.use_denoising=False
    scene.render.resolution_x=TILE; scene.render.resolution_y=TILE
    scene.render.resolution_percentage=100
    scene.render.film_transparent=True
    scene.render.image_settings.file_format='PNG'; scene.render.image_settings.color_mode='RGBA'
    scene.view_settings.view_transform='Standard'
    scene.view_settings.look='None'; scene.view_settings.exposure=0; scene.view_settings.gamma=1
    scene.world.color=(.7,.7,.7)
    camera_data=bpy.data.cameras.new('Impostor camera'); camera=bpy.data.objects.new('Impostor camera',camera_data)
    scene.collection.objects.link(camera); scene.camera=camera
    camera_data.type='ORTHO'; camera_data.ortho_scale=side
    atlas={key:[0.0]*(TILE*4*TILE*2*4) for key in ['albedo','normal']}
    for mode in ['albedo','normal']:
        for mat in obj.data.materials:
            mat.use_backface_culling=False
            nodes=mat.node_tree.nodes; nodes.clear(); links=mat.node_tree.links
            output=nodes.new('ShaderNodeOutputMaterial'); emission=nodes.new('ShaderNodeEmission')
            if mat.name in sources and sources[mat.name][1] is not None:
                transparent=nodes.new('ShaderNodeBsdfTransparent')
                mix=nodes.new('ShaderNodeMixShader')
                alpha=nodes.new('ShaderNodeTexImage'); alpha.image=sources[mat.name][1][0]
                links.new(alpha.outputs[sources[mat.name][1][1]],mix.inputs[0])
                links.new(transparent.outputs[0],mix.inputs[1]); links.new(emission.outputs[0],mix.inputs[2])
                links.new(mix.outputs[0],output.inputs['Surface'])
            else: links.new(emission.outputs[0],output.inputs['Surface'])
            if mode=='albedo':
                if mat.name in sources:
                    colour=nodes.new('ShaderNodeTexImage'); colour.image=sources[mat.name][0]
                else:
                    colour=nodes.new('ShaderNodeVertexColor'); colour.layer_name='Color'
                tint=nodes.new('ShaderNodeMixRGB'); tint.blend_type='MULTIPLY'; tint.inputs[0].default_value=1
                tint.inputs[2].default_value=(.60,.57,.50,1) if mat.name.startswith('SC_bark') else (1,1,1,1)
                links.new(colour.outputs['Color'],tint.inputs[1])
                ao=nodes.new('ShaderNodeAmbientOcclusion'); ao.inputs['Distance'].default_value=1.5
                ao.samples=8; ao.only_local=True
                mult=nodes.new('ShaderNodeMixRGB'); mult.blend_type='MULTIPLY'; mult.inputs[0].default_value=.58
                links.new(tint.outputs[0],mult.inputs[1]); links.new(ao.outputs['Color'],mult.inputs[2])
                links.new(mult.outputs[0],emission.inputs['Color'])
            else:
                normal=nodes.new('ShaderNodeNewGeometry')
                # Blender XYZ -> Godot X,Z,-Y, then signed normal to unit RGB.
                split=nodes.new('ShaderNodeSeparateXYZ'); links.new(normal.outputs['Normal'],split.inputs[0])
                combine=nodes.new('ShaderNodeCombineXYZ')
                for output_axis,input_axis,scale in [('X','X',.5),('Z','Y',.5),('Y','Z',-.5)]:
                    multiply=nodes.new('ShaderNodeMath'); multiply.operation='MULTIPLY_ADD'
                    multiply.inputs[1].default_value=scale; multiply.inputs[2].default_value=.5
                    links.new(split.outputs[output_axis],multiply.inputs[0]); links.new(multiply.outputs[0],combine.inputs[input_axis])
                links.new(combine.outputs[0],emission.inputs['Color'])
        for angle in range(8):
            theta=angle*math.tau/8
            # Godot camera vector (sin(theta),0,cos(theta)) maps to Blender (sin,-cos,0).
            camera.location=centre+Vector((math.sin(theta)*40,-math.cos(theta)*40,0))
            camera.rotation_euler=(centre-camera.location).to_track_quat('-Z','Y').to_euler()
            scene.render.filepath=str(ROOT/'.local'/f'impostor-{geometry.name}-{mode}-{angle}.png')
            bpy.ops.render.render(write_still=True)
            rendered=bpy.data.images.load(scene.render.filepath,check_existing=False)
            # Loaded byte PNG pixels are already encoded. Keep a byte atlas too:
            # a float image would apply a second colour transfer when saving.
            data=list(rendered.pixels); bpy.data.images.remove(rendered)
            col=angle%4; row=angle//4
            for y in range(TILE):
                start=((row*TILE+y)*(TILE*4)+col*TILE)*4
                atlas[mode][start:start+TILE*4]=data[y*TILE*4:(y+1)*TILE*4]
        image=bpy.data.images.new(geometry.name+'_'+mode,width=TILE*4,height=TILE*2,alpha=True,float_buffer=False)
        image.alpha_mode='STRAIGHT'; image.colorspace_settings.name='sRGB'
        image.pixels.foreach_set(atlas[mode])
        image.filepath_raw=str(OUT/(geometry.name+'_'+mode+'.png'))
        image.file_format='PNG'; image.save()
        bpy.data.images.remove(image)
    return {'width':side,'height':side,'centre_y':height*.5,'views':8,'columns':4,'rows':2,'tile_pixels':TILE}

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    path=OUT/'catalog.json'
    catalog=json.loads(path.read_text()) if path.exists() else {}
    for factory in [coconut_palm,young_palm,mango_tree,rain_tree]:
        catalog[factory.__name__]=bake(factory)
        print('IMPOSTOR COMPLETE',factory.__name__,catalog[factory.__name__],flush=True)
    path.write_text(json.dumps(catalog,indent=2)+'\n')

if __name__=='__main__': main()
