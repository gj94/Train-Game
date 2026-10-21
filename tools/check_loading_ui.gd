extends SceneTree
## Stationary source-scene startup: visual loading and publication only.
func _initialize() -> void:
	set_meta("route","kerala_coast");set_meta("traffic_seed",0);set_meta("legacy_kerala_traffic",true)
	set_meta("benchmark",true);call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	var began:=Time.get_ticks_msec()
	var game=load("res://game/main.tscn").instantiate();root.add_child(game);current_scene=game
	game.set_physics_process(false);game._set_paused(true);game.hud.show_modal("")
	var built:=Time.get_ticks_msec()
	var clock: float=game.world.time
	var captured:=false
	while game.wv.loading and Time.get_ticks_msec()-began<240000:
		await process_frame
		if not captured and DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.local/r43-loading-live.png");captured=true
	var ready: bool=not game.wv.loading
	var report:={ready=ready,clock_unchanged=game.world.time==clock,scene_setup_seconds=(built-began)/1000.0,streaming_seconds=(Time.get_ticks_msec()-built)/1000.0,workers=game.wv.workers.size(),adapter=RenderingServer.get_video_adapter_name(),loaded=game.wv.loaded.size(),remaining_background=game.wv.queue.size(),version=game.wv._loading_panel.get_node("BuildVersion").text,trace=game.wv.job_trace}
	FileAccess.open("res://.local/r43-loading-report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LOADING_UI ","PASS" if ready and report.clock_unchanged else "FAIL"," setup_s=",report.scene_setup_seconds," scenery_s=",report.streaming_seconds," workers=",report.workers)
	if ready and DisplayServer.get_name()!="headless":
		game.hud.show_modal("pause");await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.local/r43-pause-live.png")
	# Use production's asynchronous return path: GPU-backed streaming work must
	# drain with the render loop alive before freeing the geographic scene.
	await game._return_to_landing()
	await process_frame;await process_frame
	var returned: bool=not is_instance_valid(game)
	report.returned_to_menu=returned
	FileAccess.open("res://.local/r43-loading-report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LOADING_RETURN ","PASS" if returned else "FAIL")
	ready=ready and returned
	quit(0 if ready and report.clock_unchanged else 1)
