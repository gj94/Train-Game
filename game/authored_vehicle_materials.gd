extends RefCounted
## Per-car source graph materials and shared simplified shadow geometry.
static var _bundles := {}
static var _mutex := Mutex.new()

static func apply(model: Node3D, key: String) -> Dictionary:
	var bundle:=_bundle(model,key)
	var materials: Dictionary=bundle.materials
	var stats:={paint=0,metal=0,glass=0,authored=true}
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		for i in mesh.mesh.get_surface_count():
			var original: Material=mesh.mesh.surface_get_material(i)
			var identity: String=str(mesh.name)+"/"+original.resource_name
			mesh.set_surface_override_material(i,materials[identity])
			stats.glass+=int(materials[identity].get_meta("optical_glass"))
		if "INTERIOR" in str(mesh.name):
			mesh.visibility_range_end=120
			mesh.visibility_range_end_margin=20
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var shadow:=MeshInstance3D.new()
		shadow.name="Shadow_"+str(mesh.name)
		shadow.mesh=bundle.shadows[str(mesh.name)]
		shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		shadow.visibility_range_end=mesh.visibility_range_end
		shadow.visibility_range_end_margin=mesh.visibility_range_end_margin
		mesh.add_child(shadow)
	model.set_meta("surface_finish",stats)
	model.set_meta("detailed_authored_vehicle",true)
	model.set_meta("detailed_vande_bharat",key.begins_with("vb_"))
	return stats

static func _bundle(model: Node3D,key: String) -> Dictionary:
	_mutex.lock()
	var cached: Dictionary=_bundles.get(key,{})
	_mutex.unlock()
	if not cached.is_empty():return cached
	# Build privately, then publish an immutable bundle. A station loader never
	# holds the cache lock while doing I/O or contends with live train materials.
	var root: String="res://assets/models/ported/"+key+"_detail/"
	var index: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(root+"materials.json"))
	var instance: Node3D=(load(root+"shadows.glb") as PackedScene).instantiate()
	var meshes:={}
	for part in instance.find_children("*","MeshInstance3D",true,false):
		meshes[str(part.name).trim_prefix("Shadow_")]=part.mesh
	instance.free()
	var materials:={}
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		var frame: Array=index.frames[str(mesh.name)]
		var transform:=Transform3D(Basis(
			Vector3(frame[0][0],frame[1][0],frame[2][0]),
			Vector3(frame[0][1],frame[1][1],frame[2][1]),
			Vector3(frame[0][2],frame[1][2],frame[2][2])),
			Vector3(frame[0][3],frame[1][3],frame[2][3]))
		for i in mesh.mesh.get_surface_count():
			var original: Material=mesh.mesh.surface_get_material(i)
			var identity: String=str(mesh.name)+"/"+original.resource_name
			if not materials.has(identity):
				var entry: Dictionary={}
				for candidate in index.materials:
					if candidate.name==original.resource_name:
						entry=candidate
						break
				assert(not entry.is_empty(),"Missing authored material: "+original.resource_name)
				var material:=ShaderMaterial.new()
				material.resource_name=original.resource_name
				material.shader=load(root+"shaders/"+entry.shader)
				material.set_shader_parameter("author_from_mesh",transform)
				material.set_shader_parameter("source_values",preload("res://game/coach_livery.gd").values(key,entry))
				for uniform in entry.get("textures",{}):
					material.set_shader_parameter(uniform,load(root+"textures/"+str(entry.textures[uniform])))
				material.set_shader_parameter("noise_volume",load("res://assets/models/ported/wap7_detail/microfinish.res"))
				material.set_meta("optical_glass",entry.glass)
				materials[identity]=material
	_mutex.lock()
	if not _bundles.has(key):_bundles[key]={materials=materials,shadows=meshes}
	cached=_bundles[key]
	_mutex.unlock()
	return cached
