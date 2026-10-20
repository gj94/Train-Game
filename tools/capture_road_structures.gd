extends "res://tools/soak_coastal_streaming.gd"
## Source-only close views of explicit public road bridges. The supplied cases
## come from the static road-profile report, not a simulated journey.
func run() -> void:
	root.size=Vector2i(1440,900);started=Time.get_ticks_msec()
	var cases_path:="res://art/performance/overnight-2026-10-21/road-structure-cases.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--cases="):cases_path=arg.trim_prefix("--cases=")
	var cases: Array=JSON.parse_string(FileAccess.get_file_as_string(cases_path))
	if not await load_service("B012"):printerr("ROAD_CAPTURE initial load timeout");quit(2);return
	game.journey_tools.save_directory=output+"/fixture-saves"
	game._set_paused(true);game.set_physics_process(false)
	var frozen: float=game.world.time
	game.world.clock_start=15*3600-frozen
	game._set_cab_visuals(false);game.dispatcher.set_open(false);game.hud.hide()
	Engine.max_fps=30
	for item in cases:
		var centre:=Vector3(item.centre[0],item.centre[1],item.centre[2])
		var along:=Vector3(item.along[0],0,item.along[1]).normalized()
		var side:=along.cross(Vector3.UP)
		for view in ["deck","underside"]:
			var target:=centre-Vector3.UP*(.5 if view=="underside" else 0.0)
			var eye: Vector3=centre+side*38-along*22
			if view=="underside":
				eye=centre+side*item.get("underside_side",38.0)+along*item.get("underside_along",-22.0)
			eye.y=game.wv.geo.ground_at(eye.x,eye.z)+(4 if view=="underside" else 22)
			game.cam.enter_free(eye-game.wv.coordinate_origin,(target-eye).normalized())
			var now:=Time.get_ticks_msec()
			for i in 20:await process_frame
			while game.wv.loading or game.wv.has_pending_work():
				await process_frame
				if Time.get_ticks_msec()-now>180000:printerr("ROAD_CAPTURE streaming timeout");quit(2);return
			for i in 45:await process_frame
			if game.world.time!=frozen:printerr("ROAD_CAPTURE railway advanced");quit(2);return
			await RenderingServer.frame_post_draw
			var label: String=item.name+"-"+view
			root.get_texture().get_image().save_png(output+"/"+label+".png")
			record(label)
	await close_service()
	FileAccess.open(output+"/result.json",FileAccess.WRITE).store_string(JSON.stringify({complete=true,errors=errors,journeys=summaries,cases=cases,
		note="Native source close views, frozen railway. Not a timetable rehearsal or an FPS benchmark."},"\t"))
	log_file.close();print("ROAD_CAPTURE_COMPLETE");quit(1 if errors else 0)
