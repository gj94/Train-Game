extends RefCounted
## Non-destructive PBR finishing of authored stock. Textures, labels and rigs stay intact.
const SURFACE := preload("res://game/shaders/fleet_surface.gdshader")

static func apply(model: Node3D, modern: bool = false) -> Dictionary:
	if model.find_child("CABV02_1_Rear_door_hinge", true, false) != null:
		return preload("res://game/wap7_detail.gd").apply(model)
	var stats := {paint=0, metal=0, glass=0}
	for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		var node_path := str(mesh.get_path()).to_lower()
		var wheel_part := "axle" in node_path or "wheelset" in node_path or "_wheel" in node_path
		var gear_part := wheel_part or "bogie" in node_path
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.get_active_material(surface) as StandardMaterial3D
			if source==null: continue
			var name := source.resource_name.to_lower()
			if source.emission_enabled or source.albedo_texture!=null: continue
			if "glass" in name or "glazing" in name:
				if "headlamp" in name or "lens" in name: continue
				var glass := source.duplicate() as StandardMaterial3D
				# Real exterior glazing has a dark reflection; it is cleared only for
				# the occupied cab/coach by the existing onboard camera code.
				if source.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					glass.albedo_color = Color(.035,.055,.065,.82 if modern else .67)
				else:
					glass.albedo_color = Color(.045,.078,.093,1)
				glass.metallic = .28
				glass.roughness = .10
				glass.metallic_specular = .8
				mesh.set_surface_override_material(surface,glass)
				stats.glass += 1
				continue
			var kind := _kind(name)
			if kind<0: continue
			var m := ShaderMaterial.new()
			m.shader = SURFACE
			m.resource_name = source.resource_name+"_ServiceFinish"
			m.set_shader_parameter("paint_color",source.albedo_color)
			m.set_shader_parameter("base_roughness",clampf(source.roughness,.27,.88))
			m.set_shader_parameter("base_metallic",source.metallic)
			m.set_shader_parameter("finish",kind)
			m.set_shader_parameter("wear_amount",.43 if modern else .8)
			m.set_shader_parameter("gear_part",gear_part)
			m.set_shader_parameter("wheel_part",wheel_part)
			m.set_shader_parameter("vehicle_from_mesh",model.global_transform.affine_inverse()*mesh.global_transform)
			mesh.set_surface_override_material(surface,m)
			stats.paint += int(kind==0)
			stats.metal += int(kind!=0)
	model.set_meta("surface_finish",stats)
	return stats

static func _kind(name: String) -> int:
	for protected in ["letter","flag","signs","sign_","control","gauge","desk","cab_","cab ","headlamp","tail","marker","warning","screen","display","diffuser","instrument","upholstery","seat","interior","liner","laminate","headrest"]:
		if protected in name: return -1
	if "roof" in name: return 1
	for word in ["tread","machined wheel","wheel rim","burnished","brushed","stainless","handrail","silver","steel","door"]:
		if word in name: return 3
	for word in ["under","bogie","graphite","spring","frame","brake","coupler","motor","damper","tank","pipe","rubber","equipment"]:
		if word in name: return 2
	for word in ["enamel","livery","body","pearl","cobalt","window band","belt","signal white","access_panel","ir_blue","cyan_chevron","nose_dark"]:
		if word in name: return 0
	if name in ["memu_white","memu_blue","memu_orange","memu_yellow","wap7_ivory","wap7_red","lhb_red","lhb_grey","lhb_blue"]:
		return 0
	return -1
