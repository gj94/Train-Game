extends RefCounted
## Shared material updates, never one light or per-frame node search per house.
const WINDOW_SHADER:=preload("res://game/shaders/night_window.gdshader")
static var shutter_shader: Shader
var materials: Array[ShaderMaterial]=[]
var night:=0.0
var occupancy:=.7

static func occupied_fraction(hour: float) -> float:
	var h:=fposmod(hour,24.0)
	# A repeatable residential rhythm; smooth transitions survive skips/saves.
	if h<4:return lerpf(.43,.27,smoothstep(0,4,h))
	if h<7:return lerpf(.27,.70,smoothstep(4,7,h))
	if h<21:return .70
	return lerpf(.70,.43,smoothstep(21,24,h))

static func is_shutter(kind: String,material_name: String) -> bool:
	return (kind.begins_with("tf3_BLD_Home_") or kind=="tf3_BLD_Cottage_Hipped_01") and material_name.ends_with("_wood_teal")

static func window_material(source: StandardMaterial3D,shutter: bool=false) -> ShaderMaterial:
	if shutter and shutter_shader==null:
		shutter_shader=Shader.new()
		# Wooden shutters remain opaque and depth-writing in daylight and night.
		shutter_shader.code=WINDOW_SHADER.code.replace("ALPHA=mix(glass.a,.98,lit);","")
	var material:=ShaderMaterial.new();material.shader=shutter_shader if shutter else WINDOW_SHADER
	material.resource_name=source.resource_name;material.set_meta("scenery_window",true)
	material.set_meta("shuttered_window",shutter);material.set_shader_parameter("shuttered",shutter)
	material.set_shader_parameter("glass_colour",source.albedo_color)
	material.set_shader_parameter("glass_roughness",source.roughness)
	material.set_shader_parameter("glass_metallic",source.metallic)
	material.set_shader_parameter("glass_specular",source.metallic_specular)
	material.set_shader_parameter("uv_scale",source.uv1_scale)
	material.set_shader_parameter("uv_offset",source.uv1_offset)
	if source.albedo_texture!=null:
		material.set_shader_parameter("glass_texture",source.albedo_texture)
		material.set_shader_parameter("has_glass_texture",true)
	if source.normal_enabled and source.normal_texture!=null:
		material.set_shader_parameter("glass_normal",source.normal_texture)
		material.set_shader_parameter("normal_depth",source.normal_scale)
		material.set_shader_parameter("has_normal",true)
	for channel in ["roughness","metallic"]:
		var texture: Texture2D=source.get(channel+"_texture")
		if texture==null:continue
		material.set_shader_parameter("glass_"+channel+"_texture",texture)
		material.set_shader_parameter(channel+"_channel",texture_channel(source.get(channel+"_texture_channel")))
		material.set_shader_parameter("has_"+channel+"_texture",true)
	return material

static func texture_channel(channel: int) -> Vector4:
	match channel:
		BaseMaterial3D.TEXTURE_CHANNEL_GREEN:return Vector4(0,1,0,0)
		BaseMaterial3D.TEXTURE_CHANNEL_BLUE:return Vector4(0,0,1,0)
		BaseMaterial3D.TEXTURE_CHANNEL_ALPHA:return Vector4(0,0,0,1)
		BaseMaterial3D.TEXTURE_CHANNEL_GRAYSCALE:return Vector4(.333333,.333333,.333333,0)
	return Vector4(1,0,0,0)

static func porch_sites(library) -> Array:
	var sites:=[]
	for kind: String in library.placements:
		if not (kind.begins_with("tf3_BLD_Home_") or kind in ["tf3_BLD_Cottage_Hipped_01","tf3_BLD_TeaShop_Open_01","kerala_bungalow","tiled_house","tiled_cottage","shop_house"]):continue
		var box:=AABB();var first:=true
		for part in library.asset(kind):
			var bounds: AABB=part.transform*part.mesh.get_aabb()
			box=bounds if first else box.merge(bounds);first=false
		# Small reconstructed fixture under the street-facing veranda/eaves.
		var anchor:=Vector3(box.get_center().x,box.position.y+minf(2.65,box.size.y*.64),box.position.z+1.05)
		for pose: Transform3D in library.placements[kind]:
			var p:=pose.origin
			var seed:=float(posmod(roundi(p.x*17+p.z*31),127))/126.0
			sites.append({position=pose*anchor,seed=seed})
	return sites

func bind(library,extras: Array=[]) -> void:
	materials.clear()
	var seen:={}
	var candidates: Array=extras.duplicate()
	candidates.append_array(library.finishes.values())
	for parts in library.meshes.values():
		for part in parts:
			for surface in part.mesh.get_surface_count():candidates.append(part.mesh.surface_get_material(surface))
	for mesh in library.impostors.values():candidates.append(mesh.material)
	for material in candidates:
		if not material is ShaderMaterial or seen.has(material.get_instance_id()):continue
		if not material.shader.get_shader_uniform_list().any(func(p):return p.name=="window_night"):continue
		seen[material.get_instance_id()]=true;materials.append(material)

func update(night_amount: float,hour: float) -> void:
	night=night_amount;occupancy=occupied_fraction(hour)
	for material in materials:
		material.set_shader_parameter("window_night",night)
		material.set_shader_parameter("window_occupancy",occupancy)
