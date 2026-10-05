"""Builds Indian Railways MEMU cars with detailed, rigged running gear and fittings.

Run headless (never touches an open Blender session):
  "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" --background --factory-startup --python tools/blender/build_memu.py
Optional: add `-- --preview <png>` to also render a preview image.

Blender axes: X across the car, Y along it (cab front at +Y), Z up, Z=0 at rail top.
glTF export maps Blender +Y to glTF -Z, so the cab front ends up facing Godot -Z.

Exported root nodes: CabCar, TrailerCar, MotorCar (trailer + pantograph + more underfloor kit).
Lamp meshes on the cab front are named Lamp_L / Lamp_R so the game can light them.
"""
import math
import os
import bpy
import bmesh
import mathutils
import sys
sys.path.insert(0,os.path.dirname(__file__))
import memu_detail

PROJECT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(PROJECT, "assets", "models", "memu.glb")

L = 21.337        # RDSO body length, metres (docs/stations.md)
HALF_W = 1.83     # half body width (3.66 m broad-gauge MEMU)
Z_FLOOR = 1.15    # body bottom above rail
CAB_SLOPE_FROM = 2.3
CAB_SLOPE = 0.28  # metres of set-back per metre of height above CAB_SLOPE_FROM

# Body cross-section (half, x >= 0), bottom centre -> roof centre.
PROFILE = [
    (0.0, Z_FLOOR), (HALF_W - 0.05, Z_FLOOR), (HALF_W, 1.35),
    (HALF_W, 2.0), (HALF_W, 2.15), (HALF_W, 3.25),
    (HALF_W - 0.05, 3.45), (1.65, 3.62), (1.3, 3.8), (0.7, 3.92), (0.0, 3.95),
]


def band_material(z):
    if z < 2.0:
        return "Blue"
    if z < 2.15:
        return "Orange"
    if z < 3.4:
        return "White"
    return "Roof"


# --- scene + materials --------------------------------------------------------

def fresh_scene():
    """Background session: reuse the factory scene, emptied."""
    if not bpy.app.background:
        raise RuntimeError('Run this builder only in background Blender.')
    scn = bpy.context.scene
    for ob in list(scn.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    return scn


MATS = {}


def material(name, color, rough=0.5, metal=0.0, emit=0.0):
    m = bpy.data.materials.get("memu_" + name) or bpy.data.materials.new("memu_" + name)
    m.use_nodes = True
    m.use_backface_culling = True   # single-sided in glTF, so the shell is invisible from inside the cab
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if emit > 0:
        bsdf.inputs["Emission Color"].default_value = (*color, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emit
    MATS[name] = m
    return m


def make_materials():
    material("White", (0.88, 0.88, 0.86), 0.32)
    material("Blue", (0.03, 0.14, 0.42), 0.35)
    material("Orange", (0.9, 0.35, 0.03), 0.35)
    material("Roof", (0.36, 0.37, 0.39), 0.6, 0.3)
    material("Glass", (0.02, 0.03, 0.04), 0.06, 0.4)
    material("Door", (0.55, 0.57, 0.6), 0.3, 0.8)
    material("Under", (0.05, 0.05, 0.05), 0.8)
    material("Steel", (0.35, 0.35, 0.36), 0.35, 1.0)
    material("Yellow", (0.95, 0.68, 0.02), 0.4)
    material("Lamp", (1.0, 0.97, 0.88), 0.2, 0.0, 2.0)
    material("Rubber", (0.02, 0.02, 0.02), 0.9)


def new_object(name, bm, scn, parent=None, smooth=False):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    scn.collection.objects.link(ob)
    if parent:
        ob.parent = parent
    return ob


def assign(ob, names):
    """Attach the named materials to the object; returns name -> slot index."""
    idx = {}
    for n in names:
        ob.data.materials.append(MATS[n])
        idx[n] = len(ob.data.materials) - 1
    return idx


# --- body ---------------------------------------------------------------------

def full_profile():
    right = PROFILE
    left = [(-x, z) for (x, z) in reversed(PROFILE[1:-1])]
    return right + left   # closed loop, counter-clockwise seen from +Y


def body(scn, name, cab):
    bm = bmesh.new()
    prof = full_profile()
    ys = [-L / 2, -L / 2 + 0.5, 0.0, L / 2 - 1.4, L / 2]
    rings = []
    for y in ys:
        ring = []
        for (x, z) in prof:
            yy = y
            if cab and y == L / 2 and z > CAB_SLOPE_FROM:
                yy = y - (z - CAB_SLOPE_FROM) * CAB_SLOPE
            ring.append(bm.verts.new((x, yy, z)))
        rings.append(ring)
    n = len(prof)
    faces = []
    for r in range(len(rings) - 1):
        a, b = rings[r], rings[r + 1]
        for i in range(n):
            j = (i + 1) % n
            f = bm.faces.new((a[i], a[j], b[j], b[i]))
            faces.append(f)
    # End caps.
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.normal_update()
    ob = new_object(name + "_Body", bm, scn)
    idx = assign(ob, ["White", "Blue", "Orange", "Roof", "Yellow"])
    for poly in ob.data.polygons:
        c = poly.center
        if abs(poly.normal.y) > 0.9 and abs(c.y) > L / 2 - 0.6:
            poly.material_index = idx["Yellow" if (cab and c.y > 0) else "White"]
        else:
            poly.material_index = idx[band_material(c.z)]
        poly.use_smooth = c.z > 3.4 and abs(poly.normal.y) < 0.5
    return ob


def quad(bm, corners):
    vs = [bm.verts.new(c) for c in corners]
    return bm.faces.new(vs)


def side_panels(scn, name, cab, parent):
    """Windows, doors and livery details as thin panels just proud of the sides."""
    bm = bmesh.new()
    mats = []   # material name per face, in creation order
    x = HALF_W + 0.012
    door_ys = [-L / 2 + 4.2, L / 2 - 4.2]
    door_w = 1.35
    # Windows between the doors, and short runs outside them.
    spans = [(-L / 2 + 0.9, door_ys[0] - door_w / 2 - 0.4),
             (door_ys[0] + door_w / 2 + 0.4, door_ys[1] - door_w / 2 - 0.4),
             (door_ys[1] + door_w / 2 + 0.4, L / 2 - (2.2 if cab else 0.9))]
    for side in (-1, 1):
        sx = side * x
        for (y0, y1) in spans:
            length = y1 - y0
            if length < 0.8:
                continue
            count = max(1, round(length / 1.45))
            w = length / count
            for k in range(count):
                a = y0 + k * w + 0.12
                b = y0 + (k + 1) * w - 0.12
                c = [(sx, a, 2.35), (sx, b, 2.35), (sx, b, 3.08), (sx, a, 3.08)]
                f = quad(bm, c if side > 0 else list(reversed(c)))
                mats.append("Glass")
        for dy in door_ys:
            c = [(sx, dy - door_w / 2, 1.22), (sx, dy + door_w / 2, 1.22), (sx, dy + door_w / 2, 3.22), (sx, dy - door_w / 2, 3.22)]
            quad(bm, c if side > 0 else list(reversed(c)))
            mats.append("Door")
            # door windows
            for half in (-1, 1):
                ya = dy + half * 0.33 - 0.22
                yb = dy + half * 0.33 + 0.22
                c = [(sx * 1.001, ya, 2.4), (sx * 1.001, yb, 2.4), (sx * 1.001, yb, 3.0), (sx * 1.001, ya, 3.0)]
                quad(bm, c if side > 0 else list(reversed(c)))
                mats.append("Glass")
        if cab:
            # Cab side window and driver's door.
            y0, y1 = L / 2 - 1.95, L / 2 - 0.6
            c = [(sx, y0, 2.4), (sx, y1, 2.4), (sx, y1 - 0.15, 3.1), (sx, y0, 3.1)]
            quad(bm, c if side > 0 else list(reversed(c)))
            mats.append("Glass")
    bm.normal_update()
    ob = new_object(name + "_Panels", bm, scn, parent)
    idx = assign(ob, ["Glass", "Door"])
    for i, poly in enumerate(ob.data.polygons):
        poly.material_index = idx[mats[i]]
    return ob


def cab_front(scn, name, parent):
    bm = bmesh.new()
    mats = []

    def y_at(z):
        return L / 2 - max(0.0, z - CAB_SLOPE_FROM) * CAB_SLOPE + 0.012

    # Two windscreen panes.
    for (xa, xb) in ((-1.55, -0.06), (0.06, 1.55)):
        za, zb = 2.45, 3.3
        quad(bm, [(xb, y_at(za), za), (xa, y_at(za), za), (xa, y_at(zb), zb), (xb, y_at(zb), zb)])
        mats.append("Glass")
    # Destination board above the windscreen.
    za, zb = 3.38, 3.62
    quad(bm, [(0.9, y_at(za), za), (-0.9, y_at(za), za), (-0.9, y_at(zb), zb), (0.9, y_at(zb), zb)])
    mats.append("Glass")
    # Gangway door outline in the middle of the cab front (lower part).
    quad(bm, [(0.45, y_at(1.3), 1.3), (-0.45, y_at(1.3), 1.3), (-0.45, y_at(2.3), 2.3), (0.45, y_at(2.3), 2.3)])
    mats.append("Door")
    bm.normal_update()
    ob = new_object(name + "_CabFront", bm, scn, parent)
    idx = assign(ob, ["Glass", "Door"])
    for i, poly in enumerate(ob.data.polygons):
        poly.material_index = idx[mats[i]]

    # Headlamps (named so the game can colour them per direction).
    for side, lname in ((-1, "Lamp_L"), (1, "Lamp_R")):
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, segments=16, radius1=0.16, radius2=0.16, depth=0.08,
                              matrix=mathutils.Matrix.Translation((side * 1.2, L / 2 + 0.04, 1.75))
                              @ mathutils.Matrix.Rotation(math.radians(90), 4, "X"))
        lamp = new_object(lname, bm, scn, parent)
        assign(lamp, ["Lamp"])
    return ob


def gangway(scn, name, parent, y_sign):
    bm = bmesh.new()
    y = y_sign * (L / 2 + 0.15)
    bmesh.ops.create_cube(bm, size=1.0, matrix=mathutils.Matrix.LocRotScale(
        (0, y - y_sign * 0.05, 2.2), None, (0.95, 0.2, 2.0)))
    ob = new_object(name + ("_GangwayF" if y_sign > 0 else "_GangwayB"), bm, scn, parent)
    assign(ob, ["Rubber"])
    return ob


# --- running gear and underframe -----------------------------------------------

def box(bm, center, size):
    bmesh.ops.create_cube(bm, size=1.0, matrix=mathutils.Matrix.LocRotScale(center, None, size))


def roof_kit(scn, name, parent, pantograph):
    bm = bmesh.new()
    # Roof ventilators along the centre line.
    for k in range(6):
        y = -L / 2 + 2.5 + k * (L - 5.0) / 5
        box(bm, (0, y, 4.0), (0.6, 0.9, 0.12))
    ob = new_object(name + "_RoofKit", bm, scn, parent)
    assign(ob, ["Roof"])
    if pantograph:
        bm = bmesh.new()
        box(bm, (0, 0, 4.05), (1.6, 1.8, 0.1))                 # base frame
        for s in (-1, 1):
            box(bm, (s * 0.7, 0, 4.2), (0.12, 0.12, 0.2))      # insulators
            # Lower + upper arms (a folded diamond), then the pan head.
        for (y0, z0, y1, z1) in ((-0.5, 4.2, 0.25, 4.85), (0.25, 4.85, -0.1, 5.5)):
            mid = ((y0 + y1) / 2, (z0 + z1) / 2)
            length = math.hypot(y1 - y0, z1 - z0)
            ang = math.atan2(z1 - z0, y1 - y0)
            for bx in (-0.4, 0.4):   # a pair of thin tubes per arm
                bmesh.ops.create_cube(bm, size=1.0, matrix=mathutils.Matrix.LocRotScale(
                    (bx, mid[0], mid[1]), mathutils.Euler((ang, 0, 0)), (0.05, length, 0.05)))
        box(bm, (0, -0.1, 5.575), (1.9, 0.25, 0.05))
        ob = new_object(name + "_Pantograph", bm, scn, parent)
        assign(ob, ["Steel"])


# --- assembly -------------------------------------------------------------------

def car(scn, name, cab, motor):
    root = bpy.data.objects.new(name, None)
    scn.collection.objects.link(root)
    b = body(scn, name, cab)
    b.parent = root
    side_panels(scn, name, cab, root)
    if cab:
        cab_front(scn, name, root)
        gangway(scn, name, root, -1)
    else:
        gangway(scn, name, root, -1)
        gangway(scn, name, root, 1)
    memu_detail.running_gear(sys.modules[__name__],scn,name,root,motor)
    roof_kit(scn, name, root, motor)
    memu_detail.exterior(sys.modules[__name__],scn,name,root,cab,motor)
    return root


def build():
    scn = fresh_scene()
    make_materials()
    memu_detail.materials(sys.modules[__name__])
    cars = [car(scn, "CabCar", True, False), car(scn, "TrailerCar", False, False), car(scn, "MotorCar", False, True)]
    for i, c in enumerate(cars):   # spread out for previewing; the game positions them itself
        c.location.x = i * 5.0
    return scn, cars


def export(scn, cars):
    for c in cars:
        c.location.x = 0.0
    bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=False,
                              export_apply=True, export_yup=True)
    master=os.path.join(PROJECT,'art','memu')
    os.makedirs(master,exist_ok=True)
    with open(os.path.join(master,'.gdignore'),'w') as handle: handle.write('')
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(master,'memu_detailed.blend'))
    return OUT


def preview(scn, cars, png):
    for i, c in enumerate(cars):
        c.location.x = i * 5.0
    cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
    scn.collection.objects.link(cam)
    cam.data.lens = 35
    cam.location = (22, 22, 7)
    cam.rotation_euler = (mathutils.Vector((5, 3, 2)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    sun = bpy.data.objects.new("PreviewSun", bpy.data.lights.new("PreviewSun", "SUN"))
    scn.collection.objects.link(sun)
    sun.data.energy = 4.0
    sun.rotation_euler = (math.radians(50), 0, math.radians(35))
    scn.camera = cam
    scn.world = scn.world or bpy.data.worlds.new("World")
    scn.world.use_nodes = True
    bg = scn.world.node_tree.nodes.get("Background")
    bg.inputs[0].default_value = (0.55, 0.65, 0.8, 1)
    scn.render.resolution_x, scn.render.resolution_y = 1280, 720
    scn.render.filepath = png
    bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    import sys
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    scn, cars = build()
    print("MEMU exported:", export(scn, cars), sum(len(o.data.polygons) for o in scn.objects if o.type == "MESH"), "faces")
    if "--preview" in argv:
        preview(scn, cars, argv[argv.index("--preview") + 1])
