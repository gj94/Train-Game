extends SceneTree
## Native visual/performance check; synthetic paused railway, no timetable claim.
var game
var checks:=0
var failures:=0
var output:="res://.local/day-night"
var report:={cases=[]}
var timing:=preload("res://game/render_telemetry.gd").new()

func _initialize() -> void:
	set_meta("route","kerala_coast");set_meta("traffic_seed",0);set_meta("legacy_kerala_traffic",true)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	call_deferred("run")

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)

func settle() -> void:
	for i in 8:await process_frame
	var began:=Time.get_ticks_msec()
	while game.wv.loading or game.wv.has_pending_work() or not game.traffic_presentation.builds.pending.is_empty():
		await process_frame
		if Time.get_ticks_msec()-began>180000:
			check(false,"scenery settled");return
	for i in 20:await process_frame

func platform_view() -> void:
	var station: Dictionary=game.world.stations[0]
	var road: String=station.platform_tracks[0]
	var face: Dictionary=station.platform_details[road]
	var s: float=game.world.graph.edges[road].length*.5+96
	var forward: Vector3=game.world.graph.tangent(road,s,1)
	var right:=forward.cross(Vector3.UP)
	var eye: Vector3=game.world.graph.position(road,s)+right*face.platform_side*(2.02+face.platform_width*.7)+Vector3.UP*2.91
	game.cam.enter_free(eye-game.wv.coordinate_origin,(-forward-right*face.platform_side*.14).normalized())
	game._set_cab_visuals(false);game.dispatcher.set_open(false)

func capture(label: String,hour: float) -> void:
	game.world.time=hour*3600-game.world.clock_start
	game.wv.update_environment(true)
	await settle()
	var samples:=[];var gpu:=[];var last:=Time.get_ticks_usec()
	var start:=Time.get_ticks_msec()
	while Time.get_ticks_msec()-start<5000 or samples.size()<120:
		await process_frame
		var now:=Time.get_ticks_usec();samples.append((now-last)*.001);last=now
		gpu.append(timing.sample(root.get_viewport_rid()).x)
	samples.sort();gpu.sort()
	await RenderingServer.frame_post_draw
	var captured:=root.get_texture().get_image()
	captured.save_png(output+"/"+label+".png")
	var cycle=game.wv.day_night
	check(absf(cycle.state.hour-hour)<.001,"clock follows "+label)
	check(game.wv.night_lights.active_lights<=24,"bounded local lights: "+label)
	if hour==22:check(not cycle.sun.visible and cycle.moon.visible,"sun below horizon at night")
	if hour==12:check(cycle.sun.visible and game.wv.night_lights.active_lights==0,"daylight disables station lights")
	report.cases.append({name=label,hour=hour,frames=samples.size(),frame_median_ms=samples[samples.size()/2],
		frame_p95_ms=samples[floori((samples.size()-1)*.95)],gpu_median_ms=gpu[gpu.size()/2],
		station_lights=game.wv.night_lights.active_lights,fixtures=game.wv.night_lights.visible_fixtures,
		pixels=[captured.get_width(),captured.get_height()]})
	print("DAY_NIGHT ",JSON.stringify(report.cases[-1]))

func run() -> void:
	root.size=Vector2i(1600,900)
	change_scene_to_file("res://game/main.tscn");await process_frame;await process_frame
	game=current_scene;game._set_paused(true)
	game.graphics_options.preset("High");game.graphics_options.set_option("vsync",false);game.graphics_options.set_option("fps",0);game.graphics_options.apply()
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	await settle()
	var fixture:=preload("res://game/traffic_benchmark.gd").new()
	report.fixture=fixture.setup(game)
	report.adapter=RenderingServer.get_video_adapter_name();report.cpu=OS.get_processor_name()
	report.engine=Engine.get_version_info().string;report.note="Paused source-game lighting comparison; not a timetable or target-PC benchmark."
	await settle()
	platform_view()
	for entry in [["platform_day",12.0],["platform_sunset",18.25],["platform_night",22.0],["platform_dawn",6.2]]:
		await capture(entry[0],entry[1])
	fixture.set_view("pilot");await capture("cab_night",22)
	fixture.set_view("passenger");await capture("passenger_night",22)
	fixture.set_view("overview");await capture("five_trains_night",22)
	await capture("five_trains_day",12)
	check(fixture.counters().resident_trains==5,"five occupied formations remain resident")
	timing.close()
	report.checks=checks;report.failures=failures;report.complete=true
	FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("Day/night: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
