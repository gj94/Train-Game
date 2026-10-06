extends SceneTree
## Live six-train Forward+ cab/passenger soak; hardware timings are report-only.
var game
func _initialize() -> void:
	set_meta("traffic_seed",0)
	call_deferred("run_profile")
func run_profile() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	change_scene_to_file("res://game/main.tscn")
	await process_frame
	await process_frame
	game=current_scene
	game._select_train("T1")
	game._enter_cab()
	game.train.automatic=true
	game.performance_overlay.toggle()
	var started:=Time.get_ticks_msec()
	var next_sample:=10
	var phase:=0
	var report:=[]
	var audio_samples:=[]
	var peak_events:=0
	while Time.get_ticks_msec()-started<90000:
		await process_frame
		# A background benchmark must continue if another application takes focus.
		if game.paused: game._set_paused(false)
		var seconds:=(Time.get_ticks_msec()-started)*.001
		if seconds>=30 and phase==0:
			game._passenger_preset(0)
			phase=1
		if seconds>=60 and phase==1:
			game._enter_cab()
			game.train.automatic=true
			phase=2
		var audio_ms:=0.0
		var pending:=0
		for sound in game.train_audio.values():
			audio_ms+=sound.last_process_ms
			pending+=sound._events.size()
		audio_samples.append(audio_ms)
		peak_events=maxi(peak_events,pending)
		if seconds>=next_sample:
			var total:=0.0
			for sample in audio_samples: total+=sample
			var row:={seconds=seconds,view="passenger" if phase==1 else "cab",fps=Performance.get_monitor(Performance.TIME_FPS),gpu_ms=RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()),audio_ms=total/audio_samples.size(),events=pending,peak_events=peak_events,buses=AudioServer.bus_count,memory=Performance.get_monitor(Performance.MEMORY_STATIC)}
			report.append(row)
			print(JSON.stringify(row))
			var file:=FileAccess.open("res://.local/perf-runtime.json",FileAccess.WRITE)
			file.store_string(JSON.stringify(report,"\t"))
			audio_samples.clear()
			next_sample+=10
			if next_sample==30 or next_sample==60:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://.local/perf-runtime-%s.png"%row.view)
	print("Live interior soak completed")
	quit()
