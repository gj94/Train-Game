extends SceneTree
## Fixed camera corridor replay: measures scenery throughput, not timetable speed.
## Same route, view, wall duration and 100 km/h × time scale in each A/B run.
var game
var enabled:=true
var multiplier:=32
var seconds:=60.0
var output:="res://.local/r44/stream"
var ranges:=[]
var failures:=0
var telemetry:=preload("res://game/render_telemetry.gd").new()
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg=="--baseline":enabled=false
		if arg.begins_with("--scale="):multiplier=int(arg.trim_prefix("--scale="))
		if arg.begins_with("--seconds="):seconds=float(arg.trim_prefix("--seconds="))
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	set_meta("route","kerala_coast");set_meta("traffic_seed",0);set_meta("legacy_kerala_traffic",true)
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720);Engine.max_fps=60
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	game=load("res://game/main.tscn").instantiate();root.add_child(game);current_scene=game
	game.set_physics_process(false);game._set_paused(true);game.hud.show_modal("")
	game.journey_tools.autosaves=false;game.journey_tools.set_process(false)
	var began:=Time.get_ticks_msec()
	while game.wv.loading and Time.get_ticks_msec()-began<240000:await process_frame
	if game.wv.loading:printerr("Initial streaming timeout");quit(2);return
	# Capture the actual game for the menu; no scene is loaded by the menu itself.
	if "--hero" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		game.hud.clean_view=true;game.hud._refresh_visibility();game.hud._toast_time=0
		game.cam.set_process(false);game.cam.set_mode(0);game.cam.follow=false
		var car: Node3D=game.tv.cars[0]
		game.cam.fov=55;game.cam.global_position=car.to_global(Vector3(8,4.8,-18));game.cam.look_at(car.to_global(Vector3(0,2,3)))
		for i in 20:await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://assets/ui")
		root.get_texture().get_image().save_png("res://assets/ui/kerala_home.png")
	game.set_process(false);game.cam.set_process(false);game.hud.hide()
	if "--target-budget" in OS.get_cmdline_user_args():
		game.wv.performance=preload("res://game/performance_profile.gd").for_adapter("NVIDIA GeForce RTX 4090 Laptop GPU",OS.get_processor_count())
	game.wv.prefetch_enabled=enabled;game.wv.collect_timing=false
	for id in game.world.graph.edges:
		var e: Dictionary=game.world.graph.edges[id]
		if e.has("chainage_start") and absf(e.chainage_end-e.chainage_start)>1 and not "DEPOT" in id:ranges.append({id=id,e=e})
	var ghost:=Train.new("STREAM_TEST",100);ghost.speed=100/3.6
	var chainage:=1500.0;var advanced:=0.0;var held:=0.0;var stalls:=0;var was_loading:=false
	var samples:=[];var gpu:=[];var cpu:=[];var visible_max:=0;var prefetch_max:=0;var memory_max:=0.0;var frames:=0
	var stamp:=Time.get_ticks_usec();began=Time.get_ticks_msec()
	while Time.get_ticks_msec()-began<seconds*1000:
		var now:=Time.get_ticks_usec();var delta:=minf(.25,(now-stamp)*.000001);stamp=now
		if game.wv.loading:held+=delta
		else:chainage+=ghost.speed*multiplier*delta;advanced+=ghost.speed*multiplier*delta
		for pair in ranges:
			var e: Dictionary=pair.e
			if chainage>=minf(e.chainage_start,e.chainage_end) and chainage<=maxf(e.chainage_start,e.chainage_end):
				ghost.path=[{edge=pair.id,dir=1 if e.chainage_end>e.chainage_start else -1}]
				ghost.head_s=(chainage-e.chainage_start)/(e.chainage_end-e.chainage_start)*e.length;break
		var eye: Vector3=preload("res://game/stream_lookahead.gd").position(game.wv.geo.route,chainage)+Vector3.UP*4
		var origin:=Vector3(floorf(eye.x/1024)*1024,0,floorf(eye.z/1024)*1024)
		if origin!=game.wv.coordinate_origin:game.wv.rebase(origin)
		game.cam.global_position=eye-origin
		game.cam.look_at(preload("res://game/stream_lookahead.gd").position(game.wv.geo.route,chainage+100)+Vector3.UP*4-origin)
		game.wv.set_travel_context(ghost,multiplier);game.wv.update()
		if game.wv.loading and not was_loading:stalls+=1
		was_loading=game.wv.loading;frames+=1
		visible_max=maxi(visible_max,game.wv.loaded.values().filter(func(c):return c.node.visible).size())
		prefetch_max=maxi(prefetch_max,game.wv.prefetch_count)
		memory_max=maxf(memory_max,Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
		samples.append(game.wv.last_stream_ms)
		var render:=telemetry.sample(root.get_viewport_rid());gpu.append(render.x);cpu.append(render.y)
		await process_frame
	var result:={prefetch=enabled,scale=multiplier,wall_seconds=(Time.get_ticks_msec()-began)/1000.0,route_metres=advanced,loading_seconds=held,loading_interruptions=stalls,stream_ms=preload("res://game/performance_benchmark.gd").stats(samples),frames=frames,visible_chunks_max=visible_max,prefetch_jobs_max=prefetch_max,gpu_bytes_max=memory_max,adapter=RenderingServer.get_video_adapter_name(),note="1280x720 scenery-only fixed camera replay; frozen railway, not a target-PC or full-game FPS benchmark"}
	result.gpu_ms=preload("res://game/performance_benchmark.gd").stats(gpu);result.render_cpu_ms=preload("res://game/performance_benchmark.gd").stats(cpu)
	result.profile=game.wv.performance;result.prefetch_completed=game.wv.prefetch_completed;result.prefetch_hits=game.wv.prefetch_hits;telemetry.close()
	FileAccess.open(output+".json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print("STREAM_RESULT ",JSON.stringify(result))
	game.wv.set_travel_context(null,1);game.wv._request(game.cam.global_position+game.wv.coordinate_origin)
	await game._return_to_landing();await process_frame;await process_frame
	quit(0)
