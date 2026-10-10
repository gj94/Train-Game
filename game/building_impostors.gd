extends RefCounted
## Native-material, six-palette atlases for the existing architectural kit.
const ROOT:="res://assets/models/scenery/impostors/"
const Cells:=preload("res://game/spatial_batches.gd")
const NEAR:=220.0
static var catalog:={}
static var hulls:={}
static func prepare(library) -> void:
	catalog=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"buildings_catalog.json"))
	for kind in catalog:
		var data: Dictionary=catalog[kind]
		var quad:=QuadMesh.new();quad.size=Vector2.ONE*float(data.width)
		quad.center_offset=Vector3(0,data.centre[1],0)
		var material:=ShaderMaterial.new();material.shader=load("res://game/shaders/scenery_impostor.gdshader")
		material.set_shader_parameter("centre_y",0.0);material.set_shader_parameter("palettes",6.0)
		material.set_shader_parameter("colour_atlas",load(ROOT+kind+"_albedo.png"))
		material.set_shader_parameter("normal_atlas",load(ROOT+kind+"_normal.png"))
		quad.material=material;library.impostors[kind]=quad
		var hull:=BoxMesh.new();hull.size=Vector3(data.size[0],data.size[1],data.size[2])
		hulls[kind]=hull

static func flush(library,kind: String) -> void:
	var data: Dictionary=catalog[kind]
	for group in Cells.split(library.placements[kind],64).values():
		for part in library.asset(kind):
			_batch(library,kind,group,part.mesh,part.transform,0,NEAR,0)
		var offset:=Transform3D(Basis.IDENTITY,Vector3(data.centre[0],0,data.centre[2]))
		_batch(library,kind,group,library.impostors[kind],offset,NEAR,1800,1)
		offset.origin.y=data.centre[1]
		_batch(library,kind,group,hulls[kind],offset,NEAR,700,2)

static func _batch(library,kind: String,group: Dictionary,mesh: Mesh,offset: Transform3D,start: float,finish: float,role: int) -> void:
	var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_custom_data=true
	mm.mesh=mesh;mm.instance_count=group.transforms.size()
	for i in group.transforms.size():
		var pose: Transform3D=group.transforms[i]
		mm.set_instance_transform(i,pose*offset)
		var point: Vector3=group.origin+pose.origin
		var seed:=float(posmod(roundi(point.x*17+point.z*31),127))/126.0
		mm.set_instance_custom_data(i,Color(seed,.5,.5,1))
	var node:=MultiMeshInstance3D.new();node.multimesh=mm;node.position=group.origin
	node.name="HouseLOD_"+str(role)+"_"+kind
	node.set_meta("house_lod_role",role);node.set_meta("scenery_kind",kind)
	node.visibility_range_begin=start;node.visibility_range_end=finish
	node.visibility_range_begin_margin=25;node.visibility_range_end_margin=35
	node.visibility_range_fade_mode=GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	if role==1:
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.extra_cull_margin=float(catalog[kind].width);node.set_meta("impostor",true)
	elif role==2:node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	library.view.root.add_child(node)

static func set_reference(root: Node,enabled: bool) -> void:
	for node in root.find_children("HouseLOD_*","MultiMeshInstance3D",true,false):
		var role: int=node.get_meta("house_lod_role")
		if role==0:node.visibility_range_end=1800.0 if enabled else NEAR
		else:node.visible=not enabled
