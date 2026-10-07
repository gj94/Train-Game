extends SceneTree
var game
func _init() -> void:
	set_meta("route","kerala_coast")
	set_meta("traffic_seed",0)
	call_deferred("_run")
func settle() -> void:
	var start:=Time.get_ticks_msec()
	for i in 10: await process_frame
	while (game.wv.loading or game.wv.queue.any(func(job): return job.priority<3600000)) and Time.get_ticks_msec()-start<120000:
		await process_frame
	for i in 60: await process_frame
	print("SETTLED ",game.wv.loaded.size()," pending=",game.wv.queue.size()," loading=",game.wv.loading," origin=",game.wv.coordinate_origin," camera=",game.cam.global_position," memory=",Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0)
func capture(label: String) -> void:
	var start:=Time.get_ticks_usec()
	for i in 30: await process_frame
	print("FRAME_TIME ",label," mean_ms=",(Time.get_ticks_usec()-start)/30000.0," process_ms=",Performance.get_monitor(Performance.TIME_PROCESS)*1000," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," primitives=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/kerala-"+label+".png")
func _run() -> void:
	game=load("res://game/main.tscn").instantiate()
	root.add_child(game); current_scene=game
	await settle()
	game._set_paused(true)
	game.hud.show_modal("")
	await capture("pilot-final")
	for code in ["ERS","TVC","NCJ"]:
		var index: int=game.world.stations.find(game.world.stations.filter(func(st): return st.code==code)[0])
		game._visit_station(index)
		var st: Dictionary=game.world.stations[index]
		var eid: String=st.platform_tracks[0]
		var f: Vector3=game.world.graph.tangent(eid,game.world.graph.edges[eid].length*.5,1)
		var side:=f.cross(Vector3.UP)
		game.cam.pivot-=side*25
		game.cam.yaw=atan2(-side.x,-side.z)
		game.cam.distance=125; game.cam.pitch=-.27
		await settle()
		await capture(code.to_lower()+"-final")
	# A mapped bridge span north of Alappuzha, retaining actual water polygons.
	var span: Dictionary=game.world.scenery.route.spans.filter(func(s): return s.tags.get("bridge","no")!="no" and s.start>7000 and s.end-s.start>150)[0]
	var builder=preload("res://sim/layouts/kerala_coast.gd").new()
	builder.data=game.world.scenery.route; builder.distance=PackedFloat64Array(builder.data.chainage)
	var p: Array=builder.point((span.start+span.end)*.5)
	game.cam.jump_to(Vector3(p[0],p[1],p[2])-game.wv.coordinate_origin)
	game.cam._blend=1; game.cam.distance=240; game.cam.pitch=-.38
	await settle()
	await capture("backwaters-final")
	game._select_train("K7")
	game._pilot_camera()
	await settle()
	var t: Train=game.train
	var actual: Vector3=game.tv._point(0)+game.wv.coordinate_origin
	print("POSITION_ERROR_METRES ",actual.distance_to(game.world.graph.position(t.path[0].edge,t.head_s)))
	game.dispatcher.set_open(true)
	game.dispatcher._map.focus_station(55)
	for i in 10: await process_frame
	await capture("dispatch-final")
	game.dispatcher.set_open(false)
	game._select_train("K3")
	game._pilot_camera()
	await settle()
	await capture("vb-pilot")
	game._passenger_preset(1)
	await settle()
	await capture("vb-passenger")
	game.cam.set_mode(0)
	game.cam.follow=false
	game.cam.pivot=game.tv.cars[0].global_position
	game.cam.yaw=.7;game.cam.distance=39;game.cam.pitch=-.23
	await settle()
	await capture("vb-exterior")
	game._select_train("K5")
	game._passenger_preset(1)
	await settle()
	await capture("vb16-passenger")
	game.set_physics_process(false)
	var maximum: float=game.train.max_speed
	for rate in [1,2,4,8,16,32]:
		game._set_time_scale(rate)
		game.paused=false
		var before: float=game.world.time
		game._physics_process(1.0/60.0)
		assert(absf(game.world.time-before-rate/60.0)<.00001,"Fast forward must advance world time exactly")
		assert(game.train.max_speed==maximum,"Fast forward must not change stock speed limits")
		assert(AudioServer.playback_speed_scale==rate,"Audio clock did not follow world rate")
		game.paused=true
		before=game.world.time
		game._physics_process(1.0/60.0)
		assert(game.world.time==before,"Pause advanced the world")
	game._set_time_scale(1)
	assert(game.train_audio.values().all(func(a):return a.simulation_rate==1))
	game.world.dispatch_notices[game.train.id]="Expect a wait here until Coastal Stopping Passenger (K1) crosses"
	game._pilot_camera()
	for i in 90:await process_frame
	assert(game.hud._dispatch_notice.visible and game.hud._dispatch_notice.text.contains("(K1) crosses"))
	await capture("wait-indication")
	game.world.dispatch_notices.clear()
	for i in 2:await process_frame
	assert(not game.hud._dispatch_notice.visible)
	print("FAST_FORWARD_AND_LIVE_NOTICE_PASS")
	print("KERALA_GEOGRAPHY_DONE")
	quit()
