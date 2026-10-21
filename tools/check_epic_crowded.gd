extends SceneTree
## Source-game comparison. Five real full trains with passengers; railway paused.
var game
var fixture := preload("res://game/traffic_benchmark.gd").new()
var telemetry := preload("res://game/render_telemetry.gd").new()
var output := "res://art/performance/epic-2026-10-21/crowded"
var report := {complete=false,cases=[]}
var canopy_only := false
func _initialize() -> void:
	set_meta("route","kerala_coast");set_meta("traffic_seed",0)
	set_meta("benchmark",true)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
		if arg=="--canopy-only":canopy_only=true
	call_deferred("run")
func settle(label: String) -> bool:
	var start := Time.get_ticks_msec()
	for i in 10:await process_frame
	while game.wv.loading or game.wv.has_pending_work() or not game.traffic_presentation.builds.pending.is_empty():
		await process_frame
		if Time.get_ticks_msec()-start>300000:
			report.error="Timeout: "+label;write_report();quit(1);return false
	for i in 60:await process_frame
	return true
func stats(values: Array) -> Dictionary:
	values.sort()
	return {median=values[values.size()/2],p95=values[int(values.size()*.95)],samples=values.size()}
func write_report() -> void:
	FileAccess.open(output+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
func capture(label: String) -> bool:
	var wall:=[];var gpu:=[];var cpu:=[]
	var previous:=Time.get_ticks_usec()
	for i in 160:
		await process_frame
		var now:=Time.get_ticks_usec();wall.append((now-previous)*.001);previous=now
		var times:=telemetry.sample(root.get_viewport_rid());gpu.append(times.x);cpu.append(times.y)
	var counts: Dictionary=fixture.counters()
	var row:={id=label,frame_ms=stats(wall),gpu_ms=stats(gpu),render_cpu_ms=stats(cpu),traffic=counts,
		settings=game.graphics_options.values.duplicate(),clock=game.world.clock_seconds(),
		active_station_lights=game.wv.night_lights.active_lights,
		nearby_shadow_lights=game.wv.night_lights.lights.filter(func(l):return l.visible and l.shadow_enabled and l.global_position.distance_to(game.cam.global_position)<60).size(),
		loaded=game.wv.loaded.size(),origin=game.wv.coordinate_origin,
		draw_calls=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		primitives=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		gpu_bytes=Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		nodes=Performance.get_monitor(Performance.OBJECT_NODE_COUNT)}
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	row.pixels=[image.get_width(),image.get_height()]
	row.png=output.get_file()+"-"+label+".png"
	image.save_png(output.get_base_dir()+"/"+row.png)
	report.cases.append(row);write_report();print("EPIC_CASE ",JSON.stringify(row))
	if counts.resident_trains!=5 or counts.simulated_passengers!=report.fixture.passengers:
		report.error="Train/passenger lost: "+label
	if "pilot" in label and counts.rendered_seated!=0:report.error="Pilot renders seated passengers"
	if "passenger" in label and counts.rendered_seated==0:report.error="Passenger camera lost passengers"
	if canopy_only and "night" in label and "epic" in label and row.nearby_shadow_lights<4:report.error="Canopy fixture did not exercise lamp shadows"
	if report.has("error"):write_report();quit(1);return false
	return true
func run() -> void:
	if DisplayServer.get_name()=="headless":push_error("Real renderer required");quit(1);return
	root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1280,720)
	game=load("res://game/main.tscn").instantiate();root.add_child(game);current_scene=game
	game._set_paused(true);game.hud.show_modal("");game.profiling=true
	game.graphics_options.values.vsync=false;game.graphics_options.apply()
	if not await settle("startup"):return
	report.fixture=fixture.setup(game)
	if canopy_only:
		for id in fixture.ids:
			var train: Train=game.world.trains[id]
			game.world.place_train(train,train.path[0].edge,game.world.graph.edges[train.path[0].edge].length*.5+train.length*.5,1)
			game.train_motions[id].reset()
		game._render_trains(1)
		report.fixture.note="Five occupied full formations centred on ERS platforms for canopy-light stress; railway paused."
	if not await settle("five trains"):return
	report.adapter=RenderingServer.get_video_adapter_name()
	report.engine=Engine.get_version_info();report.resolution=[1280,720]
	report.method=RenderingServer.get_current_rendering_method()
	report.note="Development Radeon 780M, source debug, fixed five-train fixture. No target-PC FPS claim. No timetable replay."
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	for hour in [12.0,22.0]:
		game.world.time=hour*3600-game.world.clock_start;game.wv.update_environment(true)
		for view in (["canopy"] if canopy_only else ["pilot","passenger","platform","overview"]):
			if view=="canopy":
				var station: Dictionary=game.world.stations.filter(func(st):return st.code=="ERS")[0]
				var face: Dictionary=preload("res://sim/platform_faces.gd").entries(station)[0]
				var mid: float=game.world.graph.edges[face.edge].length*.5
				var forward: Vector3=game.world.graph.tangent(face.edge,mid,1)
				var eye: Vector3=game.world.graph.position_relative(face.edge,mid,game.wv.coordinate_origin)+forward.cross(Vector3.UP)*face.platform_side*(2.02+face.platform_width*.5)+Vector3.UP*2.9
				game.cam.enter_free(eye,forward);game.cam._blend=1;game._set_cab_visuals(false);game.dispatcher.set_open(false)
			else:fixture.set_view(view)
			for preset in ["High","Epic","High-restored"]:
				game.graphics_options.preset("High" if preset=="High-restored" else preset)
				game.graphics_options.values.vsync=false;game.graphics_options.apply()
				if not await settle(view+"-"+preset):return
				if not await capture(("day" if hour==12 else "night")+"-"+view+"-"+preset.to_lower()):return
	report.complete=true;write_report();telemetry.close()
	game.queue_free()
	for i in 10:await process_frame
	print("EPIC_CROWDED_COMPLETE");quit()
