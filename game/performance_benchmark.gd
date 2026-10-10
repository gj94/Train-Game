extends Node
## Portable opt-in instrumentation. Raw samples include loading and streaming.
## Buffered CSV writes and screenshots occur outside measured intervals.
var game
var report:={}
var output:="user://performance-benchmark.json"
var _csv: FileAccess
var _quick:=false
var _last:=0
var _pipeline_monitors:=[]
var _render_timing:=preload("res://game/render_telemetry.gd").new()
const HEADER:="ticks_us,unix_time,phase,frame_ms,gpu_ms,render_cpu_ms,engine_process_ms,engine_physics_ms,game_main_ms,simulation_ms,train_ms,crowd_ms,world_ms,hud_ms,audio_control_ms,draw_calls,primitives,gpu_bytes,texture_bytes,buffer_bytes,static_memory_bytes,nodes,resources,active_workers,queued_jobs,activating_chunks,resident_chunks,warm_chunks,cache_hits,completed_jobs,loading,presented_trains,simulated_trains,simulation_time,train_speed_mps,camera_x,camera_y,camera_z,pipeline_compilations"

func run(owner) -> void:
	game=owner
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--benchmark-output="):output=arg.trim_prefix("--benchmark-output=")
		if arg=="--benchmark-quick":_quick=true
	var csv_path:=output.get_basename()+"-frames.csv"
	_csv=FileAccess.open(csv_path,FileAccess.WRITE)
	if _csv==null:push_error("Cannot write benchmark frames: "+csv_path);get_tree().quit(1);return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	DisplayServer.window_move_to_foreground()
	for name in ClassDB.class_get_integer_constant_list("Performance"):
		if "PIPELINE_COMPILATIONS" in name:_pipeline_monitors.append({name=name,id=ClassDB.class_get_integer_constant("Performance",name)})
	var pipeline_names:=PackedStringArray(_pipeline_monitors.map(func(m):return m.name))
	_csv.store_line(HEADER+",window_focused,window_mode"+(","+",".join(pipeline_names) if not pipeline_names.is_empty() else ""))
	var settings:={}
	for property in ProjectSettings.get_property_list():
		if str(property.name).begins_with("rendering/"):settings[property.name]=ProjectSettings.get_setting(property.name)
	report={schema=2,complete=false,quick_validation=_quick,utc_start=Time.get_datetime_string_from_system(true),unix_start=Time.get_unix_time_from_system(),
		adapter=RenderingServer.get_video_adapter_name(),vendor=RenderingServer.get_video_adapter_vendor(),
		api=RenderingServer.get_video_adapter_api_version(),method=RenderingServer.get_current_rendering_method(),
		logical_cpus=OS.get_processor_count(),engine=Engine.get_version_info(),os=OS.get_name(),debug_build=OS.is_debug_build(),
		unavailable_metrics=[] if OS.is_debug_build() else ["static_memory_bytes"],
		monitor_note="Some built-in engine counters refresh up to one second late; wall-clock frame timing and custom stage timings are per frame.",
		render_timing_note="Asynchronous render-thread readback; GPU/CPU render samples may lag the main-thread frame. No main-thread timing getter barriers.",
		engine_arguments=OS.get_cmdline_args(),
		resolution=[get_window().size.x,get_window().size.y],viewport_size=get_viewport().get_visible_rect().size,
		render_target_size=[get_viewport().get_texture().get_width(),get_viewport().get_texture().get_height()],
		refresh_hz=DisplayServer.screen_get_refresh_rate(),vsync=DisplayServer.window_get_vsync_mode(),
		streaming_profile=game.wv.performance,rendering_settings=settings,
		graphics_preferences=game.graphics_options.values.duplicate(),graphics_preset=game.graphics_options.preset_name(),
		graphics_note="High baseline unless --benchmark-saved-graphics; benchmark always disables V-sync and frame cap.",
		initialization_ms=Time.get_ticks_msec(),traffic_seed=0,raw_frames=csv_path,
		pipeline_monitor_names=_pipeline_monitors.map(func(m):return m.name),cases=[]}
	_write()
	game._set_paused(true);game.hud.show_modal("")
	if not await _settle("startup"):return
	report.ready_ms=Time.get_ticks_msec()
	if OS.get_cmdline_user_args().has("--benchmark-traffic-only"):
		await _crowded_traffic()
		report.complete=not report.has("error");report.finished_ms=Time.get_ticks_msec()
		_write();_csv.close();print("BENCHMARK_COMPLETE ",ProjectSettings.globalize_path(output))
		get_tree().quit(0 if report.complete else 1);return
	await _capture("cab_static",8)
	game._passenger_preset(0)
	if not await _settle("passenger"):return
	await _capture("passenger_static",8)
	game._pilot_camera();game.train.automatic=true;game._set_paused(false)
	await _capture("live_traffic_cab",75)
	game._set_paused(true)
	var station: Dictionary=game.world.stations.filter(func(s):return s.code=="KUMM")[0]
	game._visit_station(game.world.stations.find(station))
	if not await _settle("kumbalam"):return
	var placement:=preload("res://game/coastal_station_placement.gd")
	var site:=placement.site(game.world,station,game.wv.coordinate_origin)
	game.cam.pivot=site.position-site.right*18
	game.cam.yaw=atan2(-site.right.x,-site.right.z)
	game.cam.distance=75;game.cam.pitch=-.36;game.cam._blend=1
	await _capture("station_wide",8)
	site=placement.site(game.world,station,game.wv.coordinate_origin)
	game.cam.pivot=site.position-site.right*18+Vector3.UP*3
	game.cam.distance=42;game.cam.pitch=-.14;game.cam._blend=1
	await _capture("station_close",8)
	var start: Vector3=game.cam.pivot+game.wv.coordinate_origin
	var direction: Vector3=site.forward.normalized()
	game.cam.distance=100;game.cam.pitch=-.35;game.cam.follow=false
	game._set_paused(false)
	await _capture("stream_outbound",25,start,direction)
	var end: Vector3=game.cam.pivot+game.wv.coordinate_origin
	await _capture("stream_return",25,end,-direction)
	game._set_paused(true)
	if not await _settle("revisit"):return
	await _capture("station_revisit",8)
	station=game.world.stations.filter(func(s):return s.code=="NCJ")[0]
	game._visit_station(game.world.stations.find(station))
	if not await _settle("nagercoil"):return
	game.cam.distance=180;game.cam.pitch=-.35;game.cam._blend=1
	await _capture("nagercoil_landscape",8)
	game._pilot_camera()
	if not await _settle("cab_return"):return
	await _capture("cab_return",8)
	await _crowded_traffic()
	report.complete=not report.has("error");report.finished_ms=Time.get_ticks_msec()
	_write();_csv.close()
	print("BENCHMARK_COMPLETE ",ProjectSettings.globalize_path(output))
	# This runner belongs to game, so queue shutdown after all results are saved.
	get_tree().quit()

func _crowded_traffic() -> void:
	var fixture:=preload("res://game/traffic_benchmark.gd").new()
	report.traffic_fixture=fixture.setup(game)
	if not await _settle("five_trains"):return
	for mode in ["pilot","passenger","platform","overview"]:
		fixture.set_view(mode)
		if not await _settle("five_"+mode):return
		for full in [true,false]:
			preload("res://game/train_visibility.gd").benchmark_full_interiors=full
			preload("res://game/track_detail.gd").set_reference(game.wv.root,full)
			preload("res://game/building_impostors.gd").set_reference(game.wv.root,full)
			preload("res://game/coastal_groundcover.gd").set_reference(game.wv.root,full)
			if not full:game.graphics_options.apply_tree(game.wv.root)
			for i in 45:await get_tree().process_frame
			await _capture("five_trains_"+mode+("_full" if full else "_culled"),12)
			var counts: Dictionary=fixture.counters()
			report.cases[-1].traffic=counts
			if counts.resident_trains!=5 or counts.simulated_passengers!=report.traffic_fixture.passengers:
				report.error="Crowded fixture lost a train or passenger"
			if mode=="pilot" and not full and counts.rendered_seated!=0:
				report.error="Pilot view still renders seated passengers"
			if mode=="passenger" and not full and counts.rendered_seated==0:
				report.error="Passenger view lost its visible passengers"
	preload("res://game/train_visibility.gd").benchmark_full_interiors=false
	if "--benchmark-diagnose" in OS.get_cmdline_user_args():
		await _diagnose_traffic(fixture)
	if "--benchmark-render-costs" in OS.get_cmdline_user_args():
		fixture.set_view("overview")
		if not await _settle("render_costs"):return
		await preload("res://game/render_cost_benchmark.gd").run(self)
	await _live_crowded(fixture)

func _live_crowded(fixture) -> void:
	fixture.set_view("overview")
	if not await _settle("five_live"):return
	var before: Dictionary=fixture.begin_coasting()
	await _capture("five_trains_live",12)
	game._set_paused(true)
	var counts: Dictionary=fixture.counters()
	counts["travelled_metres"]={}
	for id in fixture.ids:
		counts.travelled_metres[id]=game.world.trains[id].odometer-before[id]
		if counts.travelled_metres[id]<=1.0:report.error="Crowded live train did not move: "+id
	report.cases[-1].traffic=counts
	report.formation_build_steps=game.traffic_presentation.builds.timings
	if counts.resident_trains!=5:report.error="Crowded live fixture lost a train"

func _diagnose_traffic(fixture) -> void:
	fixture.set_view("overview")
	report.source_geometry_inventory=preload("res://game/render_inventory.gd").collect(game.wv.root,game.cam)
	var visibility:={}
	for chunk in game.wv.loaded.values():
		visibility[chunk.node]=chunk.node.visible
		chunk.node.hide()
	for i in 45:await get_tree().process_frame
	await _capture("diagnostic_trains_only",8)
	for node in visibility:
		if is_instance_valid(node):node.visible=visibility[node]
	for parent in game.traffic_presentation.roots.values():parent.hide()
	for i in 45:await get_tree().process_frame
	await _capture("diagnostic_world_only",8)
	for parent in game.traffic_presentation.roots.values():parent.show()

func _settle(label: String) -> bool:
	var began:=Time.get_ticks_msec()
	var samples:=[];_last=Time.get_ticks_usec()
	for i in 10:
		await get_tree().process_frame
		samples.append(_sample("loading_"+label))
	while game.wv.loading or game.wv.has_pending_work() or not game.traffic_presentation.builds.pending.is_empty():
		await get_tree().process_frame
		samples.append(_sample("loading_"+label))
		if Time.get_ticks_msec()-began>300000:
			report.error="Scenery did not settle: "+label
			_save_case("loading_"+label,samples,began)
			_write();get_tree().quit(1);return false
	for i in 60:
		await get_tree().process_frame
		samples.append(_sample("loading_"+label))
	_save_case("loading_"+label,samples,began)
	return true

func _capture(label: String,seconds: float,start: Vector3=Vector3.ZERO,direction: Vector3=Vector3.ZERO) -> void:
	var began:=Time.get_ticks_msec()
	var samples:=[];_last=Time.get_ticks_usec()
	if _quick:seconds=1
	while Time.get_ticks_msec()-began<seconds*1000 or samples.size()<(10 if _quick else 120):
		await get_tree().process_frame
		samples.append(_sample(label))
		if direction!=Vector3.ZERO:
			game.cam.pivot=start+direction*((Time.get_ticks_msec()-began)*.001*45)-game.wv.coordinate_origin
	_save_case(label,samples,began)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		var captured:=get_viewport().get_texture().get_image()
		report.cases[-1].captured_pixels=[captured.get_width(),captured.get_height()]
		report.cases[-1].window_pixels=[get_window().size.x,get_window().size.y]
		captured.save_png(output.get_basename()+"-"+label+".png")

func _sample(phase: String) -> Array:
	var now:=Time.get_ticks_usec()
	var delta:=(now-_last)*.001;_last=now
	var audio_ms:=0.0
	for sound in game.train_audio.values():audio_ms+=sound.last_process_ms
	var active:=0
	for worker in game.wv.workers:active+=int(not worker.runner.job.is_empty())
	var pipelines:=0
	var compilation_counts:=[]
	for monitor in _pipeline_monitors:
		var count:=roundi(Performance.get_monitor(monitor.id))
		pipelines+=count;compilation_counts.append(count)
	var camera: Vector3=game.cam.global_position+game.wv.coordinate_origin
	var costs: Dictionary=game.frame_costs
	var render_times:=_render_timing.sample(get_viewport().get_viewport_rid())
	var row: Array=[now,Time.get_unix_time_from_system(),phase,delta,
		render_times.x,render_times.y,
		Performance.get_monitor(Performance.TIME_PROCESS)*1000,Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,
		costs.get("total",0),game.simulation_ms,costs.get("trains",0),costs.get("crowd",0),costs.get("world",0),costs.get("hud",0),audio_ms,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED),
		Performance.get_monitor(Performance.MEMORY_STATIC),Performance.get_monitor(Performance.OBJECT_NODE_COUNT),Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		active,game.wv.queue.size(),game.wv._activating.size(),game.wv.loaded.size(),game.wv._warm.size(),game.wv.cache_hits,game.wv.completed_jobs,
		int(game.wv.loading),game.train_views.size(),game.world.trains.size(),game.world.time,game.train.speed,camera.x,camera.y,camera.z,pipelines]
	row.append_array([int(DisplayServer.window_is_focused()),DisplayServer.window_get_mode()])
	row.append_array(compilation_counts)
	return row

func _save_case(label: String,samples: Array,began: int) -> void:
	var headers:=HEADER.split(",")
	var result:={view=label,frames=samples.size(),duration_ms=Time.get_ticks_msec()-began,metrics={},first=samples[0],last=samples[-1]}
	for column in range(3,23):
		var values:=[]
		for sample in samples:values.append(sample[column])
		result.metrics[headers[column]]=stats(values)
	result.loading_frames=0
	result.unfocused_frames=0
	for sample in samples:
		result.loading_frames+=sample[30]
		result.unfocused_frames+=int(sample[39]==0)
		_csv.store_csv_line(PackedStringArray(sample.map(func(value):return str(value))))
	_csv.flush()
	result.presentation={camera_height=game.cam.global_position.y-game.wv.terrain_height(game.cam.global_position.x,game.cam.global_position.z),
		far_clip=game.cam.far,streamed_kinds={}}
	for job in game.wv.wanted.values():
		result.presentation.streamed_kinds[job.kind]=result.presentation.streamed_kinds.get(job.kind,0)+1
	result.completed_jobs=samples[-1][29]-samples[0][29]
	result.cache_hits=samples[-1][28]-samples[0][28]
	report.cases.append(result)
	_write()
	print("BENCHMARK ",label," frames=",samples.size()," p95_ms=",result.metrics.frame_ms.p95)

static func stats(values: Array) -> Dictionary:
	var sorted:=values.duplicate();sorted.sort()
	var total:=0.0;var over_8:=0;var over_16:=0;var over_33:=0;var over_50:=0
	for value in values:
		total+=value
		over_8+=int(value>8.333);over_16+=int(value>16.667);over_33+=int(value>33.333);over_50+=int(value>50)
	return {mean=total/values.size(),minimum=sorted[0],median=sorted[sorted.size()/2],p95=sorted[floori((sorted.size()-1)*.95)],
		p99=sorted[floori((sorted.size()-1)*.99)],maximum=sorted[-1],over_8_3=over_8,over_16_7=over_16,over_33_3=over_33,over_50=over_50}

func _write() -> void:
	var file:=FileAccess.open(output,FileAccess.WRITE)
	if file==null:push_error("Cannot write benchmark: "+output);return
	file.store_string(JSON.stringify(report,"\t"))
	var jobs:=FileAccess.open(output.get_basename()+"-jobs.json",FileAccess.WRITE)
	if jobs!=null:jobs.store_string(JSON.stringify(game.wv.job_trace,"\t"))

func _exit_tree() -> void:
	_render_timing.close()
