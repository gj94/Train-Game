"""Repeatable GLB inspection renders: blender -b --python this.py -- model.glb outdir.

Imports the exported asset, rather than rendering the source scene, to catch export defects.
No changes are made to the model. CPU Cycles makes the comparison independent of the GPU.
"""
import os
import sys
import math
import bpy
from mathutils import Vector

model, outdir = sys.argv[sys.argv.index("--") + 1:][:2]
os.makedirs(outdir, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=os.path.abspath(model))
scene = bpy.context.scene
for root in [bpy.data.objects.get(n) for n in ("TrailerCar", "MotorCar")]:
    if root:
        for ob in list(root.children_recursive) + [root]:
            bpy.data.objects.remove(ob, do_unlink=True)

def mat(name, color, metallic=0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Metallic"].default_value = metallic
    b.inputs["Roughness"].default_value = .65
    return m

def box(name, loc, size, material):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    ob = bpy.context.object
    ob.name = name
    ob.scale = size
    ob.data.materials.append(material)

ground = mat("studio_ground", (.15, .18, .20))
rail = mat("studio_rails", (.22, .23, .23), .75)
ties = mat("studio_sleepers", (.24, .25, .24))
box("Ground", (0, 0, -.3), (200, 200, .2), ground)
for x in [-.838, .838]:
    box("Rail", (x, 0, -.035), (.065, 45, .07), rail)
for k in range(-34, 35):
    box("Sleeper", (0, k*.65, -.13), (2.8, .24, .15), ties)

world = bpy.data.worlds.new("StudioWorld")
world.use_nodes = True
world.node_tree.nodes.get("Background").inputs[0].default_value = (.44, .51, .63, 1)
world.node_tree.nodes.get("Background").inputs[1].default_value = .55
scene.world = world
for name, loc, power, size in [("Key", (-8, 10, 17), 2800, 12), ("Fill", (8, 2, 10), 1600, 10)]:
    data = bpy.data.lights.new(name, "AREA")
    data.energy = power
    data.shape = "DISK"
    data.size = size
    ob = bpy.data.objects.new(name, data)
    scene.collection.objects.link(ob)
    ob.location = loc
    ob.rotation_euler = (Vector((0, 0, 2))-ob.location).to_track_quat("-Z", "Y").to_euler()
data = bpy.data.lights.new("Sun", "SUN")
data.energy = 2.0
data.angle = .15
ob = bpy.data.objects.new("Sun", data)
scene.collection.objects.link(ob)
ob.rotation_euler = (.5, -.5, -.6)

cam = bpy.data.objects.new("InspectionCamera", bpy.data.cameras.new("InspectionCamera"))
scene.collection.objects.link(cam)
scene.camera = cam
cam.data.lens = 48
scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = 24
scene.cycles.use_denoising = True
scene.render.resolution_x, scene.render.resolution_y = 1440, 900
scene.render.resolution_percentage = 100
scene.view_settings.view_transform = "AgX"
for name, pos, target in [
    ("hero", (-15, 24, 8), (0, 2, 1.85)),
    ("front", (-4.5, 21, 4), (0, 9.4, 2.2)),
    ("side", (-28, 2, 6), (0, 0, 2)),
]:
    cam.location = pos
    cam.rotation_euler = (Vector(target)-cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = os.path.abspath(os.path.join(outdir, name+".png"))
    bpy.ops.render.render(write_still=True)
