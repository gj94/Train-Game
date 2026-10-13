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
		if ResourceLoader.exists(ROOT+kind+"_windows.png"):
			material.set_shader_parameter("window_mask",load(ROOT+kind+"_windows.png"))
			material.set_shader_parameter("has_window_mask",true)
		quad.material=material;library.impostors[kind]=quad
		var hull:=BoxMesh.new();hull.size=Vector3(data.size[0],data.size[1],data.size[2])
		hulls[kind]=hull

static func flush(library,kind: String) -> void:
	var data: Dictionary=catalog[kind]
	var offset:=Transform3D(Basis.IDENTITY,Vector3(data.centre[0],0,data.centre[2]))
	var shadow_offset:=offset;shadow_offset.origin.y=data.centre[1]
	var parts: Array=library.asset(kind).duplicate()
	parts.append({mesh=library.impostors[kind],transform=offset,impostor=true})
	parts.append({mesh=hulls[kind],transform=shadow_offset})
	for group in preload("res://game/scenery_lod.gd").groups(library.placements[kind],parts):
		for part in library.asset(kind):
			_batch(library,kind,group,part.mesh,part.transform,0,NEAR,0)
		_batch(library,kind,group,library.impostors[kind],offset,NEAR,1800,1)
		_batch(library,kind,group,hulls[kind],shadow_offset,NEAR,700,2)

static func _batch(library,kind: String,group: Dictionary,mesh: Mesh,offset: Transform3D,start: float,finish: float,role: int) -> void:
	var node:=preload("res://game/scenery_lod.gd").instance(group,{mesh=mesh,transform=offset})
	node.name="HouseLOD_"+str(role)+"_"+kind
	node.set_meta("house_lod_role",role);node.set_meta("scenery_kind",kind)
	node.visibility_range_begin=start;node.visibility_range_end=finish
	node.visibility_range_begin_margin=25;node.visibility_range_end_margin=35
	node.visibility_range_fade_mode=GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	if role==1:
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.set_meta("impostor",true)
	elif role==2:node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	library.view.root.add_child(node)

static func set_reference(root: Node,enabled: bool) -> void:
	for node in root.find_children("HouseLOD_*","MultiMeshInstance3D",true,false):
		var role: int=node.get_meta("house_lod_role")
		if role==0:node.visibility_range_end=1800.0 if enabled else NEAR
		else:node.visible=not enabled
