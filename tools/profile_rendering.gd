extends SceneTree
## Repeatable Forward+ camera profiles. Run without --headless; no quality overrides.
var game
func _initialize() -> void:
	set_meta("traffic_seed",0)
	call_deferred("run_profile")
func run_profile() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	change_scene_to_file("res://game/main.tscn")
	await process_frame
	await process_frame
	game = current_scene
	game._select_train("T1")
	# Freeze simulation for exactly comparable geometry in every before/after shot.
	game.set_physics_process(false)
	for sound in game.train_audio.values(): sound.set_process(false)
	game.controller.set_process(false)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	var output := "res://.local/render-profile"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	var report := []
	for view in ["cab","exterior","passenger"]:
		if view == "cab": game._enter_cab()
		elif view == "passenger": game._passenger_preset(0)
		else:
			game.cam.set_mode(0)
			game._set_cab_visuals(false)
			game.cam.distance = 75
			game.cam.pitch = -.25
		game.cam._blend = 1
		for warmup in 45: await process_frame
		var times := []
		var gpu := []
		var cpu := []
		var process_ms := []
		var previous := Time.get_ticks_usec()
		for sample in 120:
			await process_frame
			var now := Time.get_ticks_usec()
			times.append((now-previous)*.001)
			previous = now
			gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
			cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()))
			process_ms.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
		var row := {view=view,frame_ms=stats(times),gpu_ms=stats(gpu),render_cpu_ms=stats(cpu),process_ms=stats(process_ms),draw_calls=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),primitives=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),objects=Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),nodes=Performance.get_monitor(Performance.OBJECT_NODE_COUNT),memory=Performance.get_monitor(Performance.MEMORY_STATIC),resolution=root.size}
		report.append(row)
		print(JSON.stringify(row))
		var file := FileAccess.open(output+".json",FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"\t"))
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output+"-"+view+".png")
	quit()
func stats(values: Array) -> Dictionary:
	values.sort()
	var total := 0.0
	for value in values: total += value
	return {mean=total/values.size(),median=values[values.size()/2],p95=values[int(values.size()*.95)]}
