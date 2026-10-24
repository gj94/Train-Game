extends "res://tools/capture_rural_terrain.gd"
## Native source views of exact statically audited village approaches.
func run() -> void:
	root.size=Vector2i(1440,900)
	output="res://.local/map-2026-10-24/village-native"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var cases_path:="res://art/performance/map-2026-10-24/village/village-cases.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--cases="):cases_path=arg.trim_prefix("--cases=")
	var cases: Array=JSON.parse_string(FileAccess.get_file_as_string(cases_path))
	game=load("res://game/main.tscn").instantiate()
	game.set_physics_process(false);root.add_child(game);current_scene=game
	game._set_paused(true);game.set_physics_process(false);game.hud.hide()
	frozen=game.world.time;game.world.clock_start=15*3600-frozen
	game.journey_tools.save_directory=output+"/fixture-saves"
	if not await settle():printerr("VILLAGE_CAPTURE initial timeout");quit(2);return
	game._set_cab_visuals(false);game.dispatcher.set_open(false)
	var probe=SubViewport.new();probe.size=Vector2i(8,8);probe.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(probe)
	var rect=ColorRect.new();rect.size=Vector2(8,8)
	var material=ShaderMaterial.new();material.shader=Shader.new()
	material.shader.code="shader_type canvas_item; global uniform float extreme_detail; void fragment(){COLOR=vec4(vec3(extreme_detail),1.0);}"
	rect.material=material;probe.add_child(rect)
	for row in cases:
		var a:=Vector3(row.a[0],row.a[1],row.a[2]);var b:=Vector3(row.b[0],row.b[1],row.b[2])
		var direction: Vector3=(b-a).normalized();direction.y=0;direction=direction.normalized()
		var side:=direction.cross(Vector3.UP)
		var eye: Vector3=a+direction*float(row.get("distance",14))+side*float(row.get("side",8))+Vector3.UP*float(row.get("height",4))
		var target: Vector3=a+Vector3.UP*float(row.get("target_height",1.5))-direction*float(row.get("look_back",1.5))
		game.cam.enter_free(eye-game.wv.coordinate_origin,(target-eye).normalized());game.hud.hide()
		if not await settle():printerr("VILLAGE_CAPTURE streaming timeout");quit(2);return
		if game.world.time!=frozen:printerr("VILLAGE_CAPTURE railway advanced");quit(2);return
		await RenderingServer.frame_post_draw
		var label:="km-%06.1f-%s" % [row.km,row.kind]
		root.get_texture().get_image().save_png(output+"/"+label+".png")
		var counts:={}
		for node in game.wv.root.find_children("Geography_*","Node3D",true,false):
			for key in node.get_meta("kerala_details",{}):counts[key]=counts.get(key,0)+node.get_meta("kerala_details")[key]
		report.append({view=label,building=row.building,eye=[eye.x,eye.y,eye.z],target=[target.x,target.y,target.z],details=counts,draw_calls=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),triangles=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),railway_time=game.world.time})
		FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
		print("VILLAGE_CAPTURE ",JSON.stringify(report[-1]))
		for preset in ["High","Epic","High"]:
			game.graphics_options.preset(preset);game.graphics_options.apply()
			for frame in 12:await process_frame
			await RenderingServer.frame_post_draw
			var folder=output+"/"+preset+("-restored" if bool(probe.get_meta("captured",false)) and preset=="High" else "")
			probe.set_meta("captured",true)
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
			root.get_texture().get_image().save_png(folder+"/qln.png")
			uniform_report(folder)
			var actual=probe.get_texture().get_image().get_pixel(4,4).r
			print("GPU_GLOBAL ",preset," ",actual)
			if absf(actual-(1.0 if preset=="Epic" else 0.0))>.01:printerr("UNIFORM_GLOBAL_MISMATCH ",actual);quit(2);return
	game._return_to_landing()
	for i in 10:await process_frame
	print("VILLAGE_CAPTURE_COMPLETE");quit()

func uniform_report(folder):
	var counts={total=0,visible=0,portal_shader=0,extreme_shader=0,portal_parameter=0,extreme_parameter=0}
	var paths={};var shaders={}
	for node in game.find_children("*","GeometryInstance3D",true,false):
		counts.total+=1
		if node.is_visible_in_tree():counts.visible+=1
		var portal=node.get_instance_shader_parameter("passenger_openings")!=null
		var extreme=node.get_instance_shader_parameter("extreme_detail")!=null
		if portal:counts.portal_parameter+=1
		if extreme:counts.extreme_parameter+=1
		var has_portal=false;var has_extreme=false
		if node is MeshInstance3D and node.mesh!=null:
			for surface in node.mesh.get_surface_count():
				var material=node.get_active_material(surface)
				if not material is ShaderMaterial or material.shader==null:continue
				has_portal=has_portal or "instance uniform vec4 passenger_openings" in material.shader.code
				has_extreme=has_extreme or "instance uniform float extreme_detail" in material.shader.code
				if "instance uniform" in material.shader.code:shaders[material.shader.resource_path]=shaders.get(material.shader.resource_path,0)+1
		if has_portal:counts.portal_shader+=1
		if has_extreme:counts.extreme_shader+=1
		if portal or extreme:
			var path=str(node.get_path()).split("/")
			var group="/".join(path.slice(0,5));paths[group]=paths.get(group,0)+1
	var result={counts=counts,paths=paths,shaders=shaders,global_enabled=preload("res://game/extreme_visuals.gd").surface_detail_enabled,buffer_size=ProjectSettings.get_setting("rendering/limits/global_shader_variables/buffer_size")}
	if counts.extreme_parameter!=0 or counts.extreme_shader!=0:printerr("UNIFORM_INSTANCE_LEAK");quit(2)
	FileAccess.open(folder+"/uniform-diagnostic.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print("UNIFORM_COUNTS ",JSON.stringify(counts))
