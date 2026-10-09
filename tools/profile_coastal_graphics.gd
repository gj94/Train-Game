extends SceneTree
## Same seed, paused clock, streamed tiles, cameras and sample counts for A/B.
var game
var output:="res://.local/coastal-graphics"
var report:=[]
func _initialize() -> void:
	set_meta("route","kerala_coast")
	set_meta("traffic_seed",0)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	call_deferred("_run")
func settle() -> void:
	var start:=Time.get_ticks_msec()
	for i in 10:await process_frame
	while (game.wv.loading or not game.wv.queue.is_empty() or game.wv.workers.any(func(w):return w.thread!=null)) and Time.get_ticks_msec()-start<150000:
		await process_frame
	for i in 60:await process_frame
func capture(label: String) -> void:
	for i in 45:await process_frame
	var samples:=[];var gpu:=[]
	var previous:=Time.get_ticks_usec()
	for i in 120:
		await process_frame
		var now:=Time.get_ticks_usec()
		samples.append((now-previous)*.001);previous=now
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
	report.append({view=label,frame_ms=stats(samples),gpu_ms=stats(gpu),draw_calls=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),primitives=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),loaded=game.wv.loaded.size(),pending=game.wv.queue.size(),resolution=root.size})
	print("GRAPHICS ",JSON.stringify(report[-1]))
	FileAccess.open(output+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"-"+label+".png")
func stats(values: Array) -> Dictionary:
	values.sort();var total:=0.0
	for value in values:total+=value
	return {mean=total/values.size(),median=values[values.size()/2],p95=values[int(values.size()*.95)]}
func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	game=load("res://game/main.tscn").instantiate()
	root.add_child(game);current_scene=game
	game._set_paused(true);game.hud.show_modal("")
	await settle()
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	await capture("pilot")
	game._passenger_preset(0);await settle();await capture("passenger")
	var st: Dictionary=game.world.stations.filter(func(s):return s.code=="KUMM")[0]
	game._visit_station(game.world.stations.find(st))
	var site:=preload("res://game/coastal_station_placement.gd").site(game.world,st,game.wv.coordinate_origin)
	game.cam.pivot=site.position-site.right*18
	game.cam.yaw=atan2(-site.right.x,-site.right.z)
	game.cam.distance=75;game.cam.pitch=-.36;game.cam._blend=1
	await settle();await capture("kumbalam")
	# Streaming rebases the local origin while arriving: recalculate before reuse.
	site=preload("res://game/coastal_station_placement.gd").site(game.world,st,game.wv.coordinate_origin)
	game.cam.pivot=site.position-site.right*18+Vector3.UP*3
	game.cam.distance=42;game.cam.pitch=-.14;game.cam._blend=1
	await settle();await capture("station-close")
	site=preload("res://game/coastal_station_placement.gd").site(game.world,st,game.wv.coordinate_origin)
	var candidates: Array=game.wv.root.find_children("District_kerala_bungalow","MultiMeshInstance3D",true,false)
	var nearest:=Vector3.INF;var distance:=INF;var facing:=Vector3.BACK
	for node in candidates:
		for i in node.multimesh.instance_count:
			var pose: Transform3D=node.global_transform*node.multimesh.get_instance_transform(i)
			var d:=pose.origin.distance_squared_to(site.position)
			if d<distance:distance=d;nearest=pose.origin;facing=-pose.basis.z.normalized()
	if distance<1000*1000:
		game.cam.pivot=nearest+Vector3.UP*2.2
		game.cam.yaw=atan2(facing.x,facing.z)+.35
		game.cam.distance=19;game.cam.pitch=-.12;game.cam._blend=1
		await settle();await capture("neighbourhood")
	print("GRAPHICS_COMPLETE")
	quit()
