extends RefCounted
## Opt-in render-only finishing. Per-instance detail never mutates shared materials.
## Only GeographicWorld-owned origin uniforms are updated on its main-thread
## rebase path; immutable authored asset cache resources are never changed.
const SURFACE_SHADERS := [
	"res://game/shaders/geographic_ground.gdshader",
	"res://game/shaders/scenery_road.gdshader",
	"res://game/shaders/station_surface.gdshader",
	"res://game/shaders/geographic_water.gdshader"
]
const REFLECTION_STATE := "extreme_reflection_original"
const SURFACE_STATE := "extreme_surface_applied"

static func apply_surface(node: GeometryInstance3D, enabled: bool) -> void:
	if not supports_surface(node):
		if node.has_meta(SURFACE_STATE):
			# A runtime material replacement must not inherit our instance flag.
			node.set_instance_shader_parameter("extreme_detail",null)
			node.remove_meta(SURFACE_STATE)
		return
	# A per-instance uniform is safe for both ordinary meshes and MultiMeshes.
	# The zero default also keeps newly built, not-yet-activated geometry legacy.
	node.set_instance_shader_parameter("extreme_detail",1.0 if enabled else 0.0)
	node.set_meta(SURFACE_STATE,true)

static func supports_surface(node: GeometryInstance3D) -> bool:
	if _supported_material(node.material_override):
		return true
	if node.material_override!=null:
		return false
	if node is MeshInstance3D and node.mesh!=null:
		for surface in node.mesh.get_surface_count():
			if _supported_material(node.get_active_material(surface)):
				return true
	elif node is MultiMeshInstance3D and node.multimesh!=null and node.multimesh.mesh!=null:
		for surface in node.multimesh.mesh.get_surface_count():
			if _supported_material(node.multimesh.mesh.surface_get_material(surface)):
				return true
	return false

static func _supported_material(material: Material) -> bool:
	return material is ShaderMaterial and material.shader!=null and material.shader.resource_path in SURFACE_SHADERS

static func apply_route_origin(materials: Dictionary, origin: Vector3) -> void:
	# GeographicWorld owns this dictionary, including its road/station finishes.
	# Like its existing water origin, the offset is updated once per rebase.
	# Never pass authored-asset cache materials here or duplicate mesh resources.
	var seen := {}
	for material in materials.values():
		if not material is ShaderMaterial or material.shader==null:
			continue
		if material.shader.resource_path not in [
			"res://game/shaders/scenery_road.gdshader",
			"res://game/shaders/station_surface.gdshader"
		] or seen.has(material):
			continue
		material.set_shader_parameter("extreme_route_origin",origin)
		seen[material]=true

static func apply_environment(environment: Environment, enabled: bool) -> void:
	if environment==null:
		return
	if not environment.has_meta(REFLECTION_STATE):
		environment.set_meta(REFLECTION_STATE,{
			ssr_enabled=environment.ssr_enabled,
			ssr_max_steps=environment.ssr_max_steps,
			ssr_fade_in=environment.ssr_fade_in,
			ssr_fade_out=environment.ssr_fade_out,
			ssr_depth_tolerance=environment.ssr_depth_tolerance,
			sky=environment.sky,
			radiance_size=environment.sky.radiance_size if environment.sky!=null else -1
		})
	var original: Dictionary=environment.get_meta(REFLECTION_STATE)
	if enabled:
		environment.ssr_enabled=true
		environment.ssr_max_steps=96
		environment.ssr_fade_in=.15
		environment.ssr_fade_out=2.0
		environment.ssr_depth_tolerance=.25
		if environment.sky!=null:
			environment.sky.radiance_size=Sky.RADIANCE_SIZE_512
	else:
		for key in ["ssr_enabled","ssr_max_steps","ssr_fade_in","ssr_fade_out","ssr_depth_tolerance"]:
			environment.set(key,original[key])
		if environment.sky!=null and environment.sky==original.sky:
			environment.sky.radiance_size=original.radiance_size
