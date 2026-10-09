extends RefCounted
## Shared, spatially instanced original assets with consistent PBR materials.
const ROOT := "res://assets/models/scenery/"
const Cells := preload("res://game/spatial_batches.gd")
var _view_ref: WeakRef
var view: Variant:
	get: return _view_ref.get_ref() if _view_ref!=null else null
var meshes := {}
var finishes := {}
var placements := {}
var counts := {}
const TREES := {
	"coconut_palm":Vector2(13.644375,6.201989),
	"young_palm":Vector2(12.346182,3.796909),
	"mango_tree":Vector2(12.399399,3.950090),
	"rain_tree":Vector2(15.785943,4.540256),
	"tree_small_02":Vector2(6.295639,2.275827)}
const TREE_DETAIL_DISTANCE := 175.0
var bounds := []
var catalog: Dictionary = {}
func _init(world_view=null) -> void:
	_view_ref=weakref(world_view) if world_view!=null else null
func place(kind: String,position: Vector3,angle: float=0.0,scale: Vector3=Vector3.ONE) -> void:
	if not placements.has(kind): placements[kind]=[]
	placements[kind].append(Transform3D(Basis(Vector3.UP,angle).scaled_local(scale),position))
	counts[kind]=counts.get(kind,0)+1
func material(kind: String) -> Material:
	if finishes.has(kind): return finishes[kind]
	var mat:=ShaderMaterial.new()
	mat.shader=load("res://game/shaders/scenery_surface.gdshader")
	if kind=="architecture":
		mat.shader=load("res://game/shaders/scenery_architecture.gdshader")
		for pair in [["wall","plastered_wall"],["roof","roof_tiles"]]:
			for suffix in [["albedo","diff"],["normal","nor_gl"],["rough","rough"]]:
				mat.set_shader_parameter(pair[0]+"_"+suffix[0],view.ph_tex(pair[1],suffix[1]))
		mat.set_shader_parameter("aged_wall",view.ph_tex("red_brick_plaster_patch_02","diff"))
		mat.set_shader_parameter("aged_normal",view.ph_tex("red_brick_plaster_patch_02","nor_gl"))
		finishes[kind]=mat
		return mat
	if kind=="broadleaf":
		mat.shader=load("res://game/shaders/scenery_scanned_leaf.gdshader")
		mat.set_shader_parameter("leaf_albedo",load(ROOT+"tree_small_02_tree_small_02_leaves_diff_1k.png"))
		mat.set_shader_parameter("leaf_normal",load(ROOT+"tree_small_02_tree_small_02_leaves_nor_gl_1k.png"))
		mat.set_shader_parameter("use_vertex_tint",true)
		finishes[kind]=mat
		return mat
	if kind in ["leaves","grass"]:
		mat.shader=load("res://game/shaders/scenery_foliage.gdshader")
		if kind=="grass":
			mat.set_shader_parameter("height_scale",1.5)
			mat.set_shader_parameter("wind_strength",.09)
		finishes[kind]=mat
		return mat
	var texture_name:=""
	var metres:=2.0
	match kind:
		"masonry":
			texture_name="plastered_wall"
			mat.set_shader_parameter("weathering",.62)
			mat.set_shader_parameter("paint_variation",.85)
		"bark":
			mat.set_shader_parameter("bark_surface",true)
			mat.set_shader_parameter("material_tint",Vector3(.60,.57,.50))
			mat.set_shader_parameter("weathering",.34)
		"roof":
			texture_name="roof_tiles"
			metres=1.15
			mat.set_shader_parameter("weathering",.18)
		"metal":
			mat.set_shader_parameter("metallic_value",.45)
			mat.set_shader_parameter("roughness_value",.63)
			mat.set_shader_parameter("weathering",.22)
		"glass":
			mat.set_shader_parameter("metallic_value",.27)
			mat.set_shader_parameter("roughness_value",.24)
			mat.set_shader_parameter("weathering",.045)
		"sign":
			mat.set_shader_parameter("roughness_value",.68)
			mat.set_shader_parameter("weathering",.1)
		_:
			mat.set_shader_parameter("weathering",.16)
	if not texture_name.is_empty():
		mat.set_shader_parameter("textured",true)
		mat.set_shader_parameter("metres",metres)
		for pair in [["surface_albedo","diff"],["surface_normal","nor_gl"],["surface_roughness","rough"]]:
			mat.set_shader_parameter(pair[0],view.ph_tex(texture_name,pair[1]))
	finishes[kind]=mat
	return mat
func asset(kind: String) -> Array:
	if meshes.has(kind): return meshes[kind]
	var scene: PackedScene=load(ROOT+kind+".glb")
	assert(scene!=null,"Scenery asset missing: "+kind)
	var instance:=scene.instantiate()
	var parts:=[]
	_collect(instance,Transform3D.IDENTITY,parts)
	instance.free()
	meshes[kind]=parts
	return parts
func _collect(node: Node,parent: Transform3D,parts: Array) -> void:
	var pose:=parent
	if node is Node3D: pose=parent*node.transform
	if node is MeshInstance3D:
		var mesh: Mesh=node.mesh.duplicate()
		for surface in mesh.get_surface_count():
			var source: Material=node.get_active_material(surface)
			if source!=null and source.resource_name.begins_with("PH_"):
				var original: StandardMaterial3D=source.duplicate()
				original.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				if original.resource_name.contains("leaves"):
					original.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
					original.alpha_scissor_threshold=.28
					original.alpha_antialiasing_mode=BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
					original.alpha_antialiasing_edge=.20
					original.cull_mode=BaseMaterial3D.CULL_DISABLED
				if original.resource_name.contains("leaves"):
					var leaves:=ShaderMaterial.new()
					leaves.shader=load("res://game/shaders/scenery_scanned_leaf.gdshader")
					leaves.set_shader_parameter("leaf_albedo",original.albedo_texture)
					leaves.set_shader_parameter("leaf_normal",original.normal_texture)
					mesh.surface_set_material(surface,leaves)
				else: mesh.surface_set_material(surface,original)
			else:
				var kind: String=source.resource_name.trim_prefix("SC_") if source!=null else "detail"
				mesh.surface_set_material(surface,material(kind))
		parts.append({mesh=mesh,transform=pose})
	for child in node.get_children(): _collect(child,pose,parts)
func flush() -> void:
	_flush_geometry()
	for kind in placements:
		if TREES.has(kind): _flush_impostors(kind)
	placements.clear()
func _flush_geometry() -> void:
	for kind in placements:
		for part in asset(kind):
			var transforms:=[]
			for placement in placements[kind]: transforms.append(placement*part.transform)
			for group in Cells.split(transforms,48.0 if kind=="coastal_grass" else (64.0 if TREES.has(kind) else (128.0 if kind in ["grass_tuft","verge_patch","reeds","shrub"] else 256.0))).values():
				var mm:=MultiMesh.new()
				mm.transform_format=MultiMesh.TRANSFORM_3D
				mm.use_custom_data=true
				mm.mesh=part.mesh
				mm.instance_count=group.transforms.size()
				for index in group.transforms.size():
					var transform: Transform3D=group.transforms[index]
					mm.set_instance_transform(index,transform)
					var p: Vector3=group.origin+transform.origin
					var seed:=float(posmod(roundi(p.x*17+p.z*31),127))/126.0
					mm.set_instance_custom_data(index,Color(seed,.5,.5,1))
				var batch:=MultiMeshInstance3D.new()
				batch.name="District_"+kind
				batch.set_meta("scenery_kind",kind)
				batch.position=group.origin
				batch.multimesh=mm
				batch.visibility_range_end=_range(kind)
				batch.visibility_range_end_margin=28 if TREES.has(kind) else 35
				if TREES.has(kind) or kind in ["verge_patch","coastal_grass"]: batch.visibility_range_fade_mode=GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				if kind in ["grass_tuft","verge_patch","coastal_grass","reeds"]: batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				if kind in ["mango_tree","rain_tree"]: batch.lod_bias=1.0
				view.root.add_child(batch)
func _range(kind: String) -> float:
	if kind in ["tree_small_02","mango_tree","rain_tree"]: return 115.0
	if TREES.has(kind): return TREE_DETAIL_DISTANCE
	if kind.begins_with("passenger_"): return 350.0
	if kind=="telecom_mast": return 3500
	if kind=="coastal_grass": return 125
	if kind=="verge_patch": return 150
	if kind=="grass_tuft": return 135
	if kind=="reeds": return 210
	if kind=="shrub": return 430
	if kind in ["hatchback","auto_rickshaw","motorcycle","motorcycle_rider","tea_kiosk","produce_cart"]: return 650
	if kind in ["utility_pole","transformer","bus_shelter"]: return 850
	return 1800
func _flush_impostors(kind: String) -> void:
	var size: Vector2=TREES[kind]
	var mesh:=QuadMesh.new()
	mesh.size=Vector2.ONE*size.x
	mesh.center_offset=Vector3(0,size.y,0)
	var mat:=ShaderMaterial.new()
	mat.shader=load("res://game/shaders/scenery_impostor.gdshader")
	mat.set_shader_parameter("centre_y",0.0)
	mat.set_shader_parameter("colour_atlas",load(ROOT+"impostors/"+kind+"_albedo.png"))
	mat.set_shader_parameter("normal_atlas",load(ROOT+"impostors/"+kind+"_normal.png"))
	mesh.material=mat
	for group in Cells.split(placements[kind],64).values():
		var mm:=MultiMesh.new()
		mm.transform_format=MultiMesh.TRANSFORM_3D
		mm.mesh=mesh
		mm.instance_count=group.transforms.size()
		for i in group.transforms.size(): mm.set_instance_transform(i,group.transforms[i])
		var batch:=MultiMeshInstance3D.new()
		batch.name="Canopy_"+kind
		batch.position=group.origin
		batch.multimesh=mm
		batch.extra_cull_margin=size.x
		batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		batch.visibility_range_begin=_range(kind)
		batch.visibility_range_begin_margin=28
		batch.visibility_range_end=2700
		batch.visibility_range_end_margin=180
		batch.visibility_range_fade_mode=GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		view.root.add_child(batch)
