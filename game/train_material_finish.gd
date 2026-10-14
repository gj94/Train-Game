extends RefCounted
## Only authored interior diffuser roles emit. Never brighten signs or glass.
static func fixture(key: String,role: String) -> Dictionary:
	if key.begins_with("lhb_") and role.ends_with("_Signs_and_diffusers"):
		# This source shares one material with signs. Only its ceiling sheets
		# exceed 3.4 m in the original Blender coordinate frame (Z is up).
		return {colour=Vector3(.80,.82,.78),minimum_height=3.4}
	if key=="wap7" and (role.ends_with("_Frosted lamp diffuser") or role.ends_with("_Fluorescent opal diffuser")):
		return {colour=Vector3(.74,.78,.71),minimum_height=-1000.0}
	if key.begins_with("icf_") and role.ends_with("_Warm light diffuser"):
		return {colour=Vector3(.80,.72,.54),minimum_height=-1000.0}
	if key.begins_with("vb_") and role.ends_with("_Diffused_daylight_LED"):
		return {colour=Vector3(.72,.80,.90),minimum_height=-1000.0}
	return {}

static func apply(material: ShaderMaterial,key: String) -> void:
	var setting:=fixture(key,material.resource_name)
	if setting.is_empty():return
	material.set_shader_parameter("train_fixture_emission",setting.colour)
	material.set_shader_parameter("train_fixture_min_height",setting.minimum_height)
