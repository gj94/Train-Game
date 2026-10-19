extends RefCounted
## Shared static head/ladder batches plus three small directional optical sources.
static var shell: ArrayMesh
static var metal: ArrayMesh
static var dark: StandardMaterial3D
static var trim: StandardMaterial3D
static var lenses: Array[ShaderMaterial]=[]
static var unlit: ShaderMaterial
const COLOURS := [Color("24ff72"),Color("ffb921"),Color("ff2615")]

static func material(colour: Color, metallic: float=0.0) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new();m.albedo_color=colour;m.roughness=.68;m.metallic=metallic;return m
static func box(batch: SurfaceTool, size: Vector3, pos: Vector3) -> void:
	var shape:=BoxMesh.new();shape.size=size
	batch.append_from(shape,0,Transform3D(Basis.IDENTITY,pos))
static func cylinder(batch: SurfaceTool, radius: float, height: float, pos: Vector3, basis: Basis=Basis.IDENTITY) -> void:
	var shape:=CylinderMesh.new();shape.top_radius=radius;shape.bottom_radius=radius
	shape.height=height;shape.radial_segments=16;shape.rings=1
	batch.append_from(shape,0,Transform3D(basis,pos))
static func prepare() -> void:
	if shell!=null:return
	dark=material(Color("171c1d"));trim=material(Color("797e7b"),.45)
	var a:=SurfaceTool.new();a.begin(Mesh.PRIMITIVE_TRIANGLES)
	var b:=SurfaceTool.new();b.begin(Mesh.PRIMITIVE_TRIANGLES)
	box(a,Vector3(.66,1.8,.29),Vector3(0,5.6,.02))
	box(b,Vector3(.96,2.08,.035),Vector3(0,5.6,.19))
	box(a,Vector3(.90,2.02,.04),Vector3(0,5.6,.16))
	for k in 3:
		var y:=6.1-k*.5
		cylinder(b,.149,.04,Vector3(0,y,-.15),Basis(Vector3.RIGHT,PI*.5))
		cylinder(a,.130,.045,Vector3(0,y,-.18),Basis(Vector3.RIGHT,PI*.5))
		# Curved upper visor; open below so the lens is visible on approach.
		for segment in 10:
			var angle:=PI*float(segment)/9.0
			box(a,Vector3(.052,.035,.37),Vector3(cos(angle)*.18,y+sin(angle)*.18,-.34))
	# Rear access ladder, standoff brackets and a compact service platform.
	for x in [-.23,.23]:box(b,Vector3(.035,5.5,.035),Vector3(x,2.95,.55))
	for rung in 17:box(b,Vector3(.49,.025,.03),Vector3(0,.35+rung*.31,.55))
	for y in [1.1,3.1,4.9]:box(b,Vector3(.055,.055,.5),Vector3(0,y,.28))
	box(b,Vector3(.65,.05,.48),Vector3(0,4.47,.46))
	shell=a.commit();metal=b.commit()
	unlit=ShaderMaterial.new();unlit.shader=preload("res://game/signal_lens.gdshader")
	unlit.set_shader_parameter("lit",false)
	for colour in COLOURS:
		var m:=ShaderMaterial.new();m.shader=unlit.shader
		m.set_shader_parameter("light_color",colour);m.set_shader_parameter("lit",true);lenses.append(m)

static func build(parent: Node3D) -> Array:
	prepare()
	for entry in [[shell,dark],[metal,trim]]:
		var body:=MeshInstance3D.new();body.mesh=entry[0];body.material_override=entry[1];parent.add_child(body)
	var lamps:=[]
	for i in 3:
		# The central illuminated disc is approximately 125 mm across close up.
		var lamp:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(.18,.18)
		lamp.mesh=quad;lamp.rotation.y=PI;lamp.position=Vector3(0,6.1-i*.5,-.213)
		lamp.custom_aabb=AABB(Vector3(-3.5,-3.5,-.1),Vector3(7,7,.2))
		lamp.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lamp.material_override=unlit;parent.add_child(lamp);lamps.append(lamp)
	return lamps

static func apply(lamps: Array, aspect: int) -> void:
	if lamps[0].get_meta("aspect",-1)==aspect:return
	lamps[0].set_meta("aspect",aspect)
	var lit:=2-clampi(aspect,0,2)
	for i in 3:lamps[i].material_override=lenses[i] if i==lit else unlit
