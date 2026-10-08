extends SceneTree
var failures:=0
func _initialize() -> void:
	call_deferred("_check")
func _check() -> void:
	root.size=Vector2i(1600,900)
	var scene:=Node3D.new();root.add_child(scene)
	var environment:=WorldEnvironment.new();scene.add_child(environment)
	var env:=Environment.new();environment.environment=env
	env.background_mode=Environment.BG_COLOR;env.background_color=Color(.49,.61,.71)
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color(.76,.82,.88);env.ambient_light_energy=.8
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	var sun:=DirectionalLight3D.new();scene.add_child(sun);sun.rotation_degrees=Vector3(-45,-30,0);sun.light_energy=1.8;sun.shadow_enabled=true;sun.directional_shadow_max_distance=500
	var camera:=Camera3D.new();scene.add_child(camera);camera.current=true;camera.fov=55;camera.far=2000
	var ground:=MeshInstance3D.new();scene.add_child(ground)
	var plane:=PlaneMesh.new();plane.size=Vector2(600,400);ground.mesh=plane;ground.position.y=-.15
	var material:=StandardMaterial3D.new();material.albedo_color=Color(.25,.27,.22);ground.material_override=material
	for code in ["ERS","TVC","NCJ","ERS_EAST","ERS_WORKSHOP"]:
		var assembly: Dictionary=preload("res://game/authored_station.gd").add_building(scene,code,Vector3.ZERO,Vector3.RIGHT,Vector3.BACK,code.contains("_"))
		var count:=0
		for mesh in assembly.model.find_children("*","MeshInstance3D",true,false):
			if str(mesh.name).begins_with("Shadow_"):continue
			for i in mesh.mesh.get_surface_count():
				if not mesh.get_surface_override_material(i) is ShaderMaterial:failures+=1
				count+=mesh.mesh.surface_get_array_index_len(i)/3
		var provenance: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/ported/station_"+code.to_lower()+"_detail/provenance.json"))
		if count!=int(provenance.triangles):failures+=1;printerr("Geometry count changed: "+code)
		camera.position=Vector3(65,24,-92) if code!="TVC" else Vector3(70,30,-115)
		if code.contains("_"):camera.position=Vector3(35,16,-40)
		camera.look_at(Vector3(-10,5,0))
		for i in 10:await process_frame
		await RenderingServer.frame_post_draw
		if DisplayServer.get_name()!="headless":root.get_texture().get_image().save_png("res://.local/station-"+code.to_lower()+"-game.png")
		print("STATION_MODEL ",code," triangles=",count," footprint=",assembly.footprint)
		assembly.model.queue_free();await process_frame
	print("STATION_MODELS failures=",failures)
	quit(failures)
