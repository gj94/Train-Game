extends RefCounted
## Opt-in render-only finishing. One global detail flag leaves materials immutable.
## Only GeographicWorld-owned origin uniforms are updated on its main-thread
## rebase path; immutable authored asset cache resources are never changed.
const SURFACE_SHADERS := [
	"res://game/shaders/geographic_ground.gdshader",
	"res://game/shaders/scenery_road.gdshader",
	"res://game/shaders/station_surface.gdshader",
	"res://game/shaders/geographic_water.gdshader",
	"res://game/shaders/station_boundary.gdshader",
	"res://game/shaders/track_ballast.gdshader",
	"res://game/shaders/track_concrete.gdshader",
	"res://game/shaders/track_rail.gdshader",
	"res://game/shaders/track_shoulder.gdshader"
]
const REFLECTION_STATE := "extreme_reflection_original"
const SKY_STATE := "extreme_sky_original"
const STATION_SHADOW_STATE := "extreme_station_shadow_original"
static var surface_detail_enabled := false

static func apply_station_shadow(light: OmniLight3D, enabled: bool) -> void:
	if not light.has_meta("station_shadow_rank"):
		return
	if not light.has_meta(STATION_SHADOW_STATE):
		light.set_meta(STATION_SHADOW_STATE,{
			shadow_enabled=light.shadow_enabled,light_size=light.light_size,
			shadow_blur=light.shadow_blur,distance_fade_shadow=light.distance_fade_shadow})
	# Uniform settings follow physical lamps when the nearest-first pool reorders.
	# A rank cutoff would abruptly swap shadows between fourth/fifth sites.
	# Never touch visibility, position, colour, energy, range or allocation.
	var original: Dictionary=light.get_meta(STATION_SHADOW_STATE)
	var detailed:=enabled
	light.shadow_enabled=true if detailed else original.shadow_enabled
	# A small emitting area better represents the existing fluorescent fixture
	# than an infinitesimal point. It affects shading only, never light energy.
	light.light_size=.12 if detailed else original.light_size
	light.shadow_blur=1.5 if detailed else original.shadow_blur
	# Godot independently fades shadows from 20 to 60 m with the existing
	# 40 m fade length, then skips their rendering. Light fade stays 90–130 m.
	light.distance_fade_shadow=20.0 if detailed else original.distance_fade_shadow

static func set_surface_detail(enabled: bool) -> void:
	# This preference is shared by the whole scene, including future streamed
	# geometry. Per-instance copies exhausted the renderer buffer at busy QLN.
	# Keep a CPU copy: reading the server value would synchronize render threads.
	if surface_detail_enabled==enabled:return
	surface_detail_enabled=enabled
	RenderingServer.global_shader_parameter_set("extreme_detail",1.0 if enabled else 0.0)

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

static func apply_environment(environment: Environment, reflections_enabled: bool, sky_detail_enabled: bool) -> void:
	if environment==null:
		return
	# SSR is an explicit advanced choice, not a prerequisite for sharper sky.
	# Capture each baseline only when that independent option first takes over.
	if reflections_enabled:
		if not environment.has_meta(REFLECTION_STATE):
			environment.set_meta(REFLECTION_STATE,{
				ssr_enabled=environment.ssr_enabled,
				ssr_max_steps=environment.ssr_max_steps,
				ssr_fade_in=environment.ssr_fade_in,
				ssr_fade_out=environment.ssr_fade_out,
				ssr_depth_tolerance=environment.ssr_depth_tolerance
			})
		environment.ssr_enabled=true
		environment.ssr_max_steps=96
		environment.ssr_fade_in=.15
		environment.ssr_fade_out=2.0
		environment.ssr_depth_tolerance=.25
	elif environment.has_meta(REFLECTION_STATE):
		var original: Dictionary=environment.get_meta(REFLECTION_STATE)
		for key in ["ssr_enabled","ssr_max_steps","ssr_fade_in","ssr_fade_out","ssr_depth_tolerance"]:
			environment.set(key,original[key])
		environment.remove_meta(REFLECTION_STATE)
	# If another presentation system replaces the sky, restore the old resource
	# before taking ownership of the new one. Never replace the sky reference.
	if environment.has_meta(SKY_STATE):
		var original: Dictionary=environment.get_meta(SKY_STATE)
		if not sky_detail_enabled or environment.sky!=original.sky:
			original.sky.radiance_size=original.radiance_size
			environment.remove_meta(SKY_STATE)
	if sky_detail_enabled and environment.sky!=null:
		if not environment.has_meta(SKY_STATE):
			environment.set_meta(SKY_STATE,{
				sky=environment.sky,radiance_size=environment.sky.radiance_size
			})
		environment.sky.radiance_size=Sky.RADIANCE_SIZE_512
