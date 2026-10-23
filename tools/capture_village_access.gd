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
	game._return_to_landing()
	for i in 10:await process_frame
	print("VILLAGE_CAPTURE_COMPLETE");quit()
