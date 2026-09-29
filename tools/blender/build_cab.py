"""Original Indian MEMU-inspired driving cab, built only in background Blender.

blender -b --factory-startup --python tools/blender/build_cab.py
Coordinates match build_memu.py: +Y forward, Z rail height, metres.
The design is an interpretation, not a replica of a particular unit or safety panel.
Static geometry is joined by material. Instrument pivots remain independently animated.
"""
import math
import os
import random
import bpy
from mathutils import Vector, Matrix

PROJECT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(PROJECT, "assets", "models", "memu_cab.glb")
M = {}
STATIC = []
ROOT = None


def material(name, color, rough=.55, metal=0, emission=0):
    m = bpy.data.materials.new("cab_" + name)
    m.use_nodes = True
    m.use_backface_culling = True
    m.diffuse_color = (*color, 1)
    bs = m.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value = (*color, 1)
    bs.inputs["Roughness"].default_value = rough
    bs.inputs["Metallic"].default_value = metal
    if emission:
        bs.inputs["Emission Color"].default_value = (*color, 1)
        bs.inputs["Emission Strength"].default_value = emission
    M[name] = m
    return m


def finish(ob, name, mat, parent=None, bevel=0):
    ob.name = name
    ob.data.materials.append(M[mat])
    if bevel:
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        mod = ob.modifiers.new("Soft manufactured edges", "BEVEL")
        mod.width = bevel
        mod.segments = 3
        bpy.ops.object.modifier_apply(modifier=mod.name)
        mod = ob.modifiers.new("Weighted corner normals", "WEIGHTED_NORMAL")
        bpy.ops.object.modifier_apply(modifier=mod.name)
    ob.parent = parent or ROOT
    if parent is None:
        STATIC.append(ob)
    return ob


def box(name, p, size, mat, bevel=0, parent=None, rot=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=p)
    ob = bpy.context.object
    ob.scale = size
    if rot:
        ob.rotation_euler = rot
    return finish(ob, name, mat, parent, bevel)


def cyl(name, p, radius, depth, mat, parent=None, rot=None, vertices=32):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=p)
    ob = bpy.context.object
    if rot:
        ob.rotation_euler = rot
    for poly in ob.data.polygons:
        poly.use_smooth = len(poly.vertices) == 4
    return finish(ob, name, mat, parent)


def rod(name, a, b, r, mat, parent=None, vertices=10):
    a, b = Vector(a), Vector(b)
    ob = cyl(name, (a+b)/2, r, (b-a).length, mat, parent, vertices=vertices)
    ob.rotation_euler = (b-a).to_track_quat("Z", "Y").to_euler()
    return ob


def torus(name, p, r, tube, mat, rot=None, parent=None):
    bpy.ops.mesh.primitive_torus_add(major_radius=r, minor_radius=tube,
                                   major_segments=48, minor_segments=8, location=p)
    ob = bpy.context.object
    if rot:
        ob.rotation_euler = rot
    for f in ob.data.polygons:
        f.use_smooth = True
    return finish(ob, name, mat, parent)


def text(name, content, p, size, mat="Letter", rot=None, parent=None, align="CENTER"):
    cr = bpy.data.curves.new(name, "FONT")
    cr.body, cr.size = content, size
    cr.align_x, cr.align_y = align, "CENTER"
    cr.resolution_u = 3
    cr.space_character = 1.1
    ob = bpy.data.objects.new(name, cr)
    bpy.context.collection.objects.link(ob)
    ob.location = p
    if rot:
        ob.rotation_euler = rot
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.convert(target="MESH")
    return finish(bpy.context.object, name, mat, parent)


def empty(name, p=(0, 0, 0), rot=None, parent=None):
    ob = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(ob)
    ob.location = p
    if rot:
        ob.rotation_euler = rot
    ob.parent = parent or ROOT
    return ob


def screw(p, rot=None):
    ob = cyl("Recessed screw", p, .010, .005, "Steel", rot=rot, vertices=12)
    # A dark slot reads better than a perfect silver dot at cab distance.
    slot = box("Screw slot", (0, 0, .004), (.012, .002, .001), "Rubber", parent=ob)
    return ob


def quad(name, coords, mat):
    me = bpy.data.meshes.new(name)
    me.from_pydata(coords, [], [tuple(range(len(coords)))])
    me.update()
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    return finish(ob, name, mat)


def surface_texture():
    """Small original tile embedded in glTF: grain and roughness, no external imagery."""
    rng = random.Random(94)
    image = bpy.data.images.new("Original painted metal micrograin", width=128, height=128)
    pixels = []
    for _ in range(128*128):
        g = rng.uniform(.54, .60)
        pixels.extend((g, g, g, 1))
    image.pixels = pixels
    image.pack()
    image.colorspace_settings.name = "Non-Color"
    for name in ["Desk", "Cream", "Panel", "Floor", "Seat"]:
        nodes = M[name].node_tree.nodes
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = image
        M[name].node_tree.links.new(tex.outputs["Color"], nodes.get("Principled BSDF").inputs["Roughness"])


def shell():
    # Contrasting painted steel, cream fibreglass lining, black window rubber.
    box("Cab floor", (0, 8.96, 1.20), (3.54, 3.38, .09), "Floor", .025)
    for y in [7.48, 8.40, 9.28, 10.40]:
        box("Floor panel seam", (0, y, 1.25), (3.48, .009, .006), "Rubber")
    for x in [-1.64, 1.64]:
        box("Aluminium floor edging", (x, 8.95, 1.26), (.05, 3.1, .025), "Steel", .005)
    # Raised anti-slip ribs on the driver's footwell.
    box("Foot mat", (-.77, 9.31, 1.267), (.90, .80, .018), "Rubber", .015)
    for n in range(20):
        box("Mat rib", (-.77, 8.94+n*.038, 1.282), (.86, .012, .010), "Floor", .003)
    box("Rear bulkhead", (0, 7.32, 2.37), (3.54, .08, 2.30), "Cream", .028)
    box("Rear door seal", (.10, 7.38, 2.20), (.82, .05, 1.96), "Rubber", .05)
    box("Rear door", (.10, 7.414, 2.20), (.75, .03, 1.88), "Desk", .035)
    box("Rear door window gasket", (.10, 7.44, 2.68), (.52, .04, .49), "Rubber", .045)
    box("Rear door obscure glass", (.10, 7.466, 2.68), (.45, .015, .42), "Obscure", .035)
    rod("Door handle", (.38, 7.49, 2.06), (.38, 7.49, 2.27), .014, "Steel")
    box("Door threshold", (.10, 7.52, 1.27), (.80, .20, .03), "Steel", .007)
    for x in [-1.77, 1.77]:
        box("Lower side lining", (x, 8.91, 1.78), (.055, 3.2, 1.12), "Cream", .012)
        box("Side window top", (x, 8.98, 3.28), (.075, 3.28, .30), "Cream", .014)
        box("Side rear pillar", (x, 7.72, 2.75), (.065, .80, 1.00), "Cream", .018)
        box("Side front pillar", (x, 10.33, 2.77), (.075, .28, 1.03), "Cream", .015)
        for y in [8.20, 10.18]:
            box("Side gasket upright", (x*.985, y, 2.77), (.062, .038, .83), "Rubber", .008)
        for z in [2.36, 3.18]:
            box("Side gasket horizontal", (x*.985, 9.19, z), (.065, 2.02, .038), "Rubber", .01)
        box("Sliding window stile", (x*.981, 9.35, 2.77), (.048, .035, .80), "Steel", .006)
        box("Window latch", (x*.967, 9.29, 2.41), (.065, .12, .035), "Steel", .006)
        box("Side padded sill", (x*.947, 9.2, 2.32), (.19, 2.06, .07), "Rubber", .02)
        box("Door kick plate", (x*.982, 8.13, 1.48), (.018, .52, .39), "Steel", .012)
        rod("Grab handle", (x*.93, 8.19, 2.16), (x*.93, 8.19, 2.65), .016, "Steel")
        rod("Grab handle upper return", (x*.93, 8.19, 2.65), (x, 8.19, 2.65), .016, "Steel")
        rod("Grab handle lower return", (x*.93, 8.19, 2.16), (x, 8.19, 2.16), .016, "Steel")
    # Curved headliner using longitudinal strips.
    profile = [(-1.77, 3.40), (-1.55, 3.57), (-1.20, 3.72), (-.65, 3.82),
               (0, 3.85), (.65, 3.82), (1.20, 3.72), (1.55, 3.57), (1.77, 3.40)]
    for (x,z), (xx,zz) in zip(profile, profile[1:]):
        quad("Ceiling liner", [(x,7.35,z),(x,10.10,z),(xx,10.10,zz),(xx,7.35,zz)], "Cream")
    cap = [(-1.77,3.39),(1.77,3.39)] + list(reversed(profile))
    quad("Front curved header",[(x,10.08,z) for x,z in cap],"Cream")
    quad("Rear curved header",[(x,7.35,z) for x,z in reversed(cap)],"Cream")
    for y in [7.6, 8.75, 10.02]:
        for (x,z), (xx,zz) in zip(profile, profile[1:]):
            rod("Headliner seam", (x,y,z-.012), (xx,y,zz-.012), .009, "Trim")


def windshield():
    def pt(x, z, inset=.08):
        return (x, 10.65-max(0,z-2.3)*.28-inset, z)
    box("Front lower lining", (0, 10.52, 1.80), (3.48, .08, 1.14), "Cream", .02)
    box("Front header", (0, 10.17, 3.43), (3.43, .16, .29), "Cream", .03)
    for x in [-1.69, 0, 1.69]:
        rod("Windscreen structural post", pt(x,2.37,.04), pt(x,3.33,.04), .053 if x==0 else .077, "Desk", vertices=16)
    for a,b in [(-1.61,-.065),(.065,1.61)]:
        for aa,bb in [((a,2.43),(b,2.43)),((b,2.43),(b,3.30)),((b,3.30),(a,3.30)),((a,3.30),(a,2.43))]:
            rod("Thick window rubber", pt(*aa),pt(*bb),.027,"Rubber",vertices=12)
            rod("Gasket inset piping",pt(*aa,.091),pt(*bb,.091),.006,"Trim",vertices=8)
        # Parked wiper arms: clear the central sightline.
        x = (a+b)/2
        rod("Wiper arm", pt(x,2.43,.13),pt(x-.395,2.71,.145),.009,"Steel")
        rod("Wiper rubber blade", pt(x-.51,2.50,.145),pt(x-.28,2.92,.145),.014,"Rubber")
        cyl("Wiper motor cover",pt(x,2.37,.14),.052,.12,"Panel",rot=(math.pi/2,0,0))
        box("Sun visor",(x,10.04,3.31),(1.27,.08,.17),"Visor",.028)
        rod("Visor hinge",(a+.1,10.09,3.38),(b-.1,10.09,3.38),.012,"Steel")
    box("Cab number plate",(0,10.073,3.45),(.29,.015,.086),"Panel",.007)
    text("Cab number","SR  21804",(0,10.061,3.45),.041,rot=(math.pi/2,0,0))


ANGLE = math.radians(57)
PANEL_ROT = (ANGLE,0,0)
PANEL_ORIGIN = Vector((-.62,9.99,2.25))
PANEL_MATRIX = Matrix.Rotation(ANGLE,3,"X")


def pp(x,y,z=0):
    return PANEL_ORIGIN+PANEL_MATRIX@Vector((x,y,z))


def panel_text(content,x,y,size=.024,mat="Letter",z=.048):
    return text("Panel legend",content,pp(x,y,z),size,mat,rot=PANEL_ROT)


def gauge(name, x, y, radius, maximum, label, unit):
    assembly = empty(name+"Housing", pp(x,y,.051), PANEL_ROT)
    cyl("Instrument outer bezel",(0,0,0),radius+.016,.035,"Steel",parent=assembly)
    cyl("Instrument rubber gasket",(0,0,.020),radius+.008,.026,"Rubber",parent=assembly)
    cyl("Instrument black face",(0,0,.036),radius,.008,"Dial",parent=assembly,vertices=64)
    torus("Bezel highlight",(0,0,.041),radius+.003,.006,"Trim",parent=assembly)
    count = 24 if maximum == 120 else 20
    for i in range(count+1):
        angle = math.radians(225-i*270/count)
        start = radius*(.80 if i%2==0 else .87)
        stop = radius*.96
        rod("Gauge tick",(math.cos(angle)*start,math.sin(angle)*start,.045),
            (math.cos(angle)*stop,math.sin(angle)*stop,.045),.0018,"Letter",parent=assembly,vertices=6)
        if i%4==0:
            text("Gauge numeral",str(round(maximum*i/count)),
                 (math.cos(angle)*radius*.65,math.sin(angle)*radius*.65,.047),radius*.145,
                 parent=assembly)
    text("Gauge title",label,(0,radius*.29,.047),radius*.14,parent=assembly)
    text("Gauge unit",unit,(0,-radius*.43,.047),radius*.18,parent=assembly)
    pivot = empty(name,(0,0,.051),parent=assembly)
    rod("Red instrument needle",(-radius*.16,0,0),(radius*.83,0,0),.0032,"Needle",parent=pivot,vertices=8)
    cyl("Needle centre",(0,0,.058),radius*.085,.015,"Steel",parent=assembly)
    pivot.rotation_euler.z = math.radians(225)
    return pivot


def desk():
    # A fabricated sloped desk instead of a stack of cubes.
    profile = [(9.48,1.93),(10.49,1.93),(10.49,2.415),(10.14,2.415),(9.84,1.953),(9.48,1.953)]
    verts = [(x,y,z) for x in [-1.64,1.64] for y,z in profile]
    n = len(profile)
    faces = [tuple(reversed(range(n))),tuple(range(n,2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    mesh = bpy.data.meshes.new("Formed desk shell")
    mesh.from_pydata(verts,[],faces)
    mesh.update()
    ob = bpy.data.objects.new("Formed desk shell",mesh)
    bpy.context.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    finish(ob,"Formed steel desk","Desk",bevel=.035)
    box("Left desk pedestal",(-1.43,9.98,1.61),(.42,1.02,.69),"Desk",.023)
    box("Right desk pedestal",(1.12,9.98,1.61),(1.04,1.02,.69),"Desk",.023)
    box("Footwell back lining",(-.35,10.40,1.65),(1.68,.06,.76),"Cream",.012)
    # Panel fits above the sloped shell, within the driver's view.
    box("Instrument mounting plate",pp(0,0,.0),(1.87,.44,.032),"Panel",.018,rot=PANEL_ROT)
    for x in [-.89,.89]:
        for y in [-.185,.185]:
            screw(pp(x,y,.021),PANEL_ROT)
    gauge("NeedleSpeed",-.37,0,.153,120,"SPEED","km/h")
    gauge("NeedlePower",.015,.005,.112,100,"POWER","%")
    gauge("NeedleBrake",.30,.005,.112,100,"BRAKE","%")
    panel_text("SOUTHERN RAILWAY",-.37,-.184,.018)
    panel_text("MEMU  /  DRIVER'S DESK",.18,-.171,.020)
    # Four annunciators have fixed housings and independently switched lenses.
    for name,label,x,mat in [("PowerLamp","POWER",-.80,"Green"),("CoastLamp","COAST",-.64,"Amber"),
                              ("BrakeLamp","BRAKE",.58,"Amber"),("EmergencyLamp","EMERGENCY",.78,"Red")]:
        box("Annunciator bezel",pp(x,.080,.040),(.126,.074,.032),"Rubber",.009,rot=PANEL_ROT)
        pivot = empty(name+"Mount",pp(x,.080,.063),PANEL_ROT)
        box(name,(0,0,0),(.10,.047,.013),mat,.007,parent=pivot)
        panel_text(label,x,.010,.017)
    # Lower control shelf.
    box("Control shelf",(-.68,9.64,2.045),(1.90,.33,.07),"Desk",.025)
    box("Rubber desk lip",(0,9.48,2.052),(3.26,.065,.073),"Rubber",.023)
    for x in [-1.60,1.60]:
        rod("Desk edge trim",(x,9.53,2.09),(x,10.23,2.43),.012,"Worn")
    # Master controller pivot is animated around its own Z axis.
    cyl("Controller pedestal",(-1.31,9.72,2.12),.122,.11,"Panel")
    cyl("Controller index ring",(-1.31,9.72,2.18),.132,.018,"Steel")
    controller = empty("ControllerPivot",(-1.31,9.72,2.205))
    cyl("Controller spindle",(0,0,0),.035,.09,"Steel",parent=controller)
    rod("Controller lever",(0,0,.045),(.16,0,.045),.024,"Steel",parent=controller)
    cyl("Bakelite handle",(.16,0,.08),.043,.095,"Rubber",parent=controller)
    for i,label in enumerate(["BRAKE","OFF","POWER"]):
        a = math.radians(150-i*75)
        text("Controller notch",label,(-1.31+.18*math.cos(a),9.72+.18*math.sin(a),2.09),.017)
    # Toggle switches, pushbuttons and durable engraved plates.
    for x,label in [(-.95,"LIGHT"),(-.76,"WIPER"),(-.57,"FAN"),(-.38,"CAB")]:
        box("Switch legend plate",(x,9.65,2.09),(.155,.19,.012),"Panel",.006)
        cyl("Toggle collar",(x,9.68,2.114),.023,.015,"Steel")
        rod("Toggle stem",(x,9.68,2.12),(x,9.70,2.168),.007,"Steel")
        text("Switch legend",label,(x,9.59,2.10),.020)
    cyl("Emergency button collar",(.04,9.65,2.10),.074,.025,"Steel")
    cyl("Emergency button stem",(.04,9.65,2.145),.035,.07,"Red")
    cyl("Emergency mushroom",(.04,9.65,2.183),.063,.032,"Red")
    text("Emergency legend","EMERGENCY",(.04,9.54,2.097),.021,"Letter")
    text("Emergency key","SPACE",(.04,9.78,2.10),.017,"Letter")
    # Assistant's tabletop, paperwork, radio, small equipment lockers.
    box("Assistant desk pad",(1.06,9.95,2.47),(1.01,.67,.025),"Rubber",.025)
    box("Timetable clipboard",(.95,9.93,2.495),(.36,.47,.014),"Board",.008)
    box("Paper",(.95,9.92,2.507),(.32,.42,.006),"Paper",.002)
    text("Paper heading","WORKING TIMETABLE",(.95,10.04,2.512),.020,"Ink")
    for k,line in enumerate(["CPM  06:15", "MRT  06:24", "KDL  06:32", "----------------", "Observe signals"]):
        text("Paper timetable",line,(.95,9.98-k*.04,2.512),.018,"Ink")
    box("Clipboard clip",(.95,10.13,2.519),(.11,.034,.018),"Steel",.004)
    box("Radio casing",(.48,10.07,2.51),(.25,.25,.09),"Rubber",.018)
    for k in range(7):
        box("Radio grille",(.48,10.04+k*.014,2.56),(.17,.006,.003),"Trim",.001)
    box("Radio display",(.48,9.985,2.558),(.15,.034,.008),"Green",.004)
    box("Handset",(.47,9.80,2.51),(.13,.21,.076),"Rubber",.025)
    for k in range(24):
        a = k*math.pi*.65
        b = (k+1)*math.pi*.65
        rod("Coiled handset cable",(.64+math.cos(a)*.014,9.80+k*.009,2.50+math.sin(a)*.014),
            (.64+math.cos(b)*.014,9.80+(k+1)*.009,2.50+math.sin(b)*.014),.003,"Rubber",vertices=6)
    for x,width in [(-1.43,.37),(1.12,.96)]:
        box("Desk access panel",(x,9.458,1.62),(width,.02,.60),"Panel",.015)
        for xx in [x-width/2+.03,x+width/2-.03]:
            for z in [1.40,1.92]:
                screw((xx,9.451,z),(math.pi/2,0,0))
        for z in [1.49,1.55,1.61,1.67]:
            box("Underdesk ventilation",(x,9.443,z),(width*.7,.012,.018),"Rubber",.004)
    text("Equipment plate","MEMU   21804   /   SR",(1.12,9.433,1.83),.040,rot=(math.pi/2,0,0))
    box("Deadman pedal",(-.79,9.39,1.33),(.24,.25,.065),"Panel",.017,rot=(.15,0,0))
    for x in [-.87,-.83,-.79,-.75,-.71]:
        box("Pedal tread",(x,9.39,1.372),(.012,.22,.009),"Steel")


def furniture():
    for x in [-.76,1.05]:
        cyl("Seat base",(x,8.55,1.30),.22,.09,"Panel")
        cyl("Seat pedestal",(x,8.55,1.51),.065,.38,"Steel")
        box("Seat cushion",(x,8.58,1.76),(.55,.53,.16),"Seat",.063)
        box("Seat back",(x,8.32,2.07),(.55,.14,.63),"Seat",.056,rot=(.08,0,0))
        for xx in [x-.22,x+.22]:
            rod("Seat stitch",(xx,8.34,1.85),(xx,8.37,2.28),.002,"Thread")
        rod("Seat seam",(x-.24,8.81,1.78),(x+.24,8.81,1.78),.003,"Thread")
        for xx in [x-.31,x+.31]:
            rod("Armrest support",(xx,8.4,1.63),(xx,8.4,2.01),.017,"Steel")
            box("Padded armrest",(xx,8.59,2.02),(.082,.39,.06),"Rubber",.025)
    # Overhead cage fans, a distinctive utilitarian cab detail.
    for x in [-1.17,1.17]:
        rod("Fan bracket",(x,9.42,3.59),(x,9.42,3.31),.023,"Desk")
        rot=(math.radians(78),0,0)
        hub=empty("FanAssembly",(x,9.42,3.30),rot)
        cyl("Fan motor",(0,0,-.085),.065,.14,"Desk",parent=hub)
        cyl("Fan centre",(0,0,.036),.036,.07,"Steel",parent=hub)
        for r in [.074,.116,.157,.203]:
            torus("Fan cage ring",(0,0,.054),r,.0035,"Steel",parent=hub)
        for k in range(12):
            a=k*math.tau/12
            rod("Fan cage spoke",(.03*math.cos(a),.03*math.sin(a),.055),
                (.205*math.cos(a),.205*math.sin(a),.014),.003,"Steel",parent=hub,vertices=6)
        for k in range(3):
            a=k*math.tau/3
            box("Fan blade",(.09*math.cos(a),.09*math.sin(a),0),(.17,.062,.012),"Desk",.024,parent=hub,rot=(0,0,a+.2))
        torus("Fan rim",(0,0,.0),.209,.009,"Panel",parent=hub)
    # Cab luminaire; emitted surface is modest, in-game local fill is separate.
    box("Light housing",(0,8.79,3.78),(.18,.88,.07),"Steel",.018)
    box("Light diffuser",(0,8.79,3.73),(.13,.80,.035),"Light",.018)
    box("Electrical cabinet",(-1.16,7.51,2.30),(.76,.30,1.82),"Desk",.025)
    for z in [1.7,2.2,2.7]:
        box("Cabinet door",(-1.16,7.68,z),(.69,.028,.43),"Panel",.014)
        cyl("Cabinet latch",(-.91,7.71,z),.025,.018,"Steel",rot=(math.pi/2,0,0))
    # Extinguisher and original safety labels on the rear wall.
    cyl("Fire extinguisher",(1.21,7.62,1.69),.105,.62,"Red")
    cyl("Extinguisher shoulder",(1.21,7.62,2.01),.075,.08,"Red")
    box("Extinguisher label",(1.21,7.724,1.73),(.13,.009,.22),"Paper",.008)
    text("Extinguisher type","ABC",(1.21,7.731,1.78),.036,"Red",rot=(math.pi/2,0,math.pi))
    text("Extinguisher instruction","FIRE\nPULL PIN",(1.21,7.731,1.69),.019,"Ink",rot=(math.pi/2,0,math.pi))
    box("Extinguisher handle",(1.21,7.62,2.095),(.15,.05,.07),"Panel",.012)
    rod("Extinguisher hose",(1.26,7.62,2.09),(1.35,7.66,1.53),.012,"Rubber")
    box("Safety notice",(.88,7.379,2.85),(.49,.016,.34),"Paper",.003)
    text("Safety heading","SAFETY FIRST",(.88,7.395,2.94),.038,"Red",rot=(math.pi/2,0,math.pi))
    text("Safety text","CHECK SIGNAL\nBEFORE STARTING",(.88,7.395,2.80),.029,"Ink",rot=(math.pi/2,0,math.pi))


def consolidate():
    # Bake hierarchy-independent static parts, keeping instruments and their pivots.
    bpy.context.view_layer.update()
    by_material = {}
    animated = {"NeedleSpeed", "NeedlePower", "NeedleBrake", "ControllerPivot",
                "PowerLamp", "CoastLamp", "BrakeLamp", "EmergencyLamp"}
    for ob in list(bpy.context.scene.objects):
        if ob.type != "MESH":
            continue
        ancestor = ob
        dynamic = False
        while ancestor:
            if ancestor.name in animated:
                dynamic = True
                break
            ancestor = ancestor.parent
        if dynamic:
            continue
        world = ob.matrix_world.copy()
        ob.parent = ROOT
        ob.matrix_world = world
        by_material.setdefault(ob.data.materials[0].name,[]).append(ob)
    for name, objects in by_material.items():
        bpy.ops.object.select_all(action="DESELECT")
        for ob in objects:
            ob.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        bpy.ops.object.join()
        bpy.context.object.name="Interior_"+name
    # Basic projected UVs for the small roughness tile; all labels are geometry.
    for ob in bpy.context.scene.objects:
        if ob.type != "MESH":
            continue
        mesh=ob.data
        if not mesh.uv_layers:
            uv=mesh.uv_layers.new(name="Surface grain")
            for poly in mesh.polygons:
                axis=max(range(3),key=lambda k: abs(poly.normal[k]))
                axes=[k for k in range(3) if k != axis]
                for li in poly.loop_indices:
                    co=mesh.vertices[mesh.loops[li].vertex_index].co
                    uv.data[li].uv=(co[axes[0]]*7,co[axes[1]]*7)


def build():
    global ROOT
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    ROOT=empty("CabInterior")
    material("Desk",(.105,.19,.155),.49,.18)
    material("Cream",(.63,.61,.49),.66)
    material("Panel",(.040,.061,.057),.53,.25)
    material("Rubber",(.009,.013,.013),.82)
    material("Floor",(.060,.073,.071),.87)
    material("Steel",(.30,.34,.34),.29,.82)
    material("Trim",(.20,.24,.23),.36,.65)
    material("Worn",(.31,.33,.27),.65,.35)
    material("Dial",(.008,.014,.018),.61)
    material("Letter",(.78,.82,.72),.48,emission=.15)
    material("Needle",(.94,.25,.07),.38,emission=.25)
    material("Green",(.03,.58,.18),.3,emission=.7)
    material("Amber",(.92,.42,.03),.3,emission=.7)
    material("Red",(.49,.028,.018),.4)
    material("Seat",(.037,.068,.082),.78)
    material("Thread",(.23,.28,.29),.8)
    material("Visor",(.095,.15,.14),.9)
    material("Obscure",(.077,.13,.14),.23,.15)
    material("Board",(.17,.087,.037),.8)
    material("Paper",(.73,.72,.63),.95)
    material("Ink",(.04,.055,.05),.9)
    material("Light",(.90,.85,.65),.4,emission=1.2)
    surface_texture()
    shell()
    windshield()
    desk()
    furniture()
    consolidate()
    bpy.ops.export_scene.gltf(filepath=OUT,export_format="GLB",export_apply=True,
                              export_yup=True,export_cameras=False,export_lights=False)
    meshes=[o for o in bpy.context.scene.objects if o.type=="MESH"]
    triangles=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes)
    print("CAB EXPORTED",OUT,"meshes",len(meshes),"triangles",triangles)


if __name__=="__main__":
    build()
