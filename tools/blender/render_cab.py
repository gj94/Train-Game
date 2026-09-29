"""Render the exported cab, not its source, for repeatable visual QA.
blender -b --factory-startup --python tools/blender/render_cab.py -- output-directory
"""
import math
import os
import sys
import bpy
from mathutils import Vector

project = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
out = sys.argv[sys.argv.index("--")+1]
os.makedirs(out, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=os.path.join(project, "assets", "models", "memu_cab.glb"))
scene=bpy.context.scene
scene.world=bpy.data.worlds.new("Daylight")
scene.world.use_nodes=True
bg=scene.world.node_tree.nodes.get("Background")
bg.inputs[0].default_value=(.53,.64,.79,1)
bg.inputs[1].default_value=.65
for name,loc,power,size,target in [
    ("Window daylight", (0,12,4),450,4,(0,9,2)),
    ("Side daylight", (-4,9,4),300,3,(0,9,2)),
    ("Cab ceiling light", (0,8.8,3.55),45,1,(0,9,1)),
]:
    data=bpy.data.lights.new(name,"AREA")
    data.energy=power
    data.shape="DISK"
    data.size=size
    ob=bpy.data.objects.new(name,data)
    scene.collection.objects.link(ob)
    ob.location=loc
    ob.rotation_euler=(Vector(target)-ob.location).to_track_quat("-Z","Y").to_euler()
cam=bpy.data.objects.new("InspectionCamera",bpy.data.cameras.new("InspectionCamera"))
scene.collection.objects.link(cam)
scene.camera=cam
scene.render.engine="CYCLES"
scene.cycles.device="CPU"
scene.cycles.samples=40
scene.cycles.use_denoising=True
scene.render.resolution_x,scene.render.resolution_y=1600,1000
scene.render.resolution_percentage=100
scene.view_settings.view_transform="AgX"
for name,loc,target,lens in [
    ("driver",(-.75,9.05,2.8),(-.45,10.1,2.43),19),
    ("cabin",(1.55,7.8,3.03),(-.45,9.7,2.28),20),
    ("desk",(-.48,8.97,2.94),(-.48,9.94,2.22),29),
    ("rear",(-1.42,9.56,2.99),(.32,7.63,2.18),20),
]:
    cam.location=loc
    cam.data.lens=lens
    cam.rotation_euler=(Vector(target)-cam.location).to_track_quat("-Z","Y").to_euler()
    scene.render.filepath=os.path.abspath(os.path.join(out,name+".png"))
    bpy.ops.render.render(write_still=True)
