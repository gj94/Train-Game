extends RefCounted
## Faithful v02 material graphs, cached by rigid frame, shared between locomotives.
static var _materials: Dictionary = {}
static var _index: Dictionary = {}
static var _shadows: Dictionary = {}

static func apply(model: Node3D) -> Dictionary:
	if _index.is_empty():
		_index = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/ported/wap7_detail/materials.json"))
	if _shadows.is_empty():
		var shadow_scene: Node3D = (load("res://assets/models/ported/wap7_detail/shadows.glb") as PackedScene).instantiate()
		for part: MeshInstance3D in shadow_scene.find_children("*","MeshInstance3D",true,false):
			_shadows[str(part.name).trim_prefix("Shadow_")] = part.mesh
		shadow_scene.free()
	var stats := {paint=0, metal=0, glass=0, authored=true}
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var frame: Array = _index.frames.get(str(mesh.name), [])
		assert(frame.size()==4, "Missing detailed WAP-7 material frame: "+str(mesh.name))
		var transform := Transform3D(
			Basis(Vector3(frame[0][0],frame[1][0],frame[2][0]),
				Vector3(frame[0][1],frame[1][1],frame[2][1]),
				Vector3(frame[0][2],frame[1][2],frame[2][2])),
			Vector3(frame[0][3],frame[1][3],frame[2][3]))
		for i in mesh.mesh.get_surface_count():
			var original := mesh.mesh.surface_get_material(i)
			var key := str(mesh.name)+"/"+original.resource_name
			if not _materials.has(key):
				var entry: Dictionary = {}
				for candidate in _index.materials:
					if candidate.name == original.resource_name:
						entry = candidate
						break
				assert(not entry.is_empty(), "Missing authored material: "+original.resource_name)
				var material := ShaderMaterial.new()
				material.resource_name = original.resource_name
				material.shader = load("res://assets/models/ported/wap7_detail/shaders/"+entry.shader)
				material.set_shader_parameter("author_from_mesh",transform)
				material.set_shader_parameter("source_values",PackedFloat32Array(entry.source_values))
				material.set_shader_parameter("noise_volume",load("res://assets/models/ported/wap7_detail/microfinish.res"))
				for uniform in entry.textures:
					material.set_shader_parameter(uniform,load("res://assets/models/ported/wap7_detail/textures/"+entry.textures[uniform]))
				material.set_meta("optical_glass",entry.glass)
				_materials[key] = material
			var material: ShaderMaterial = _materials[key]
			mesh.set_surface_override_material(i,material)
			stats.glass += int(material.get_meta("optical_glass"))
			stats.paint += int("enamel" in original.resource_name.to_lower())
			stats.metal += int("steel" in original.resource_name.to_lower())
		# Keep the full interior close up. Godot's generated geometric LODs
		# reduce distant triangles without altering the original near meshes.
		if "INTERIOR" in str(mesh.name) or "Rear_door" in str(mesh.name):
			mesh.visibility_range_end = 100.0
			mesh.visibility_range_end_margin = 15.0
		assert(_shadows.has(str(mesh.name)), "Missing rigid shadow geometry")
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var shadow := MeshInstance3D.new()
		shadow.name = "Shadow_"+str(mesh.name)
		shadow.mesh = _shadows[str(mesh.name)]
		shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		shadow.visibility_range_end = mesh.visibility_range_end
		shadow.visibility_range_end_margin = mesh.visibility_range_end_margin
		mesh.add_child(shadow)
	model.set_meta("surface_finish",stats)
	model.set_meta("detailed_wap7",true)
	return stats
