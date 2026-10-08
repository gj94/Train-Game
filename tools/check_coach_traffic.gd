extends SceneTree
## Native source-scene integration: real Kerala traffic, onboard controls and audio geometry.
var game
var failures := 0
var checks := 0

func _initialize() -> void:
	set_meta("route","kerala_coast")
	set_meta("traffic_seed",0)
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+message)

func settle() -> void:
	var start := Time.get_ticks_msec()
	for i in 10: await process_frame
	while (game.wv.loading or game.wv.queue.any(func(job):return job.priority<3600000)) and Time.get_ticks_msec()-start<120000:
		await process_frame
	check(not game.wv.loading,"local scenery streaming settled")
	for i in 90: await process_frame

func capture(label: String) -> void:
	game.cam._blend = 1.0
	game.hud._toast_time = 0
	game.hud._refresh_visibility()
	await settle()
	var start := Time.get_ticks_usec()
	for i in 120: await process_frame
	print("TRAFFIC_FRAME ",label," mean_ms=",(Time.get_ticks_usec()-start)/120000.0,
		" process_ms=",Performance.get_monitor(Performance.TIME_PROCESS)*1000,
		" draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		" primitives=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		" memory_mib=",Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/coach-traffic/"+label+".png")

func run() -> void:
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute("res://.local/coach-traffic")
	var start := Time.get_ticks_msec()
	game = load("res://game/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game._set_paused(true)
	game.hud.show_modal("")
	check(game.train.id=="K1" and game.train.stock_kind=="ported:icf","default slow passenger uses detailed ICF")
	check(game.train_views.size()==7,"seven traffic services instantiated")
	for id in game.train_views:
		var view = game.train_views[id]
		check(game.train_audio[id]._sched.axles==view.sound_axles(),id+" actual visual/audio axle positions agree")
		for i in view.models.size():
			if view.formation[i].model=="wap7": continue
			check(view.models[i].get_meta("detailed_authored_vehicle",false),id+" authored coach materials complete")
	print("TRAFFIC_SCENE_LOAD_MS ",Time.get_ticks_msec()-start)
	await capture("icf-pilot")
	for family in ["icf","lhb","vb8","vb16"]:
		var service: Train = game.world.trains.values().filter(func(t):return t.stock_kind=="ported:"+family)[0]
		game._select_train(service.id)
		for preset in 3:
			game._passenger_preset(preset)
			check(game.cam.mode==2 and game.tv.passenger_on,family+" passenger camera active")
			check(game.train.id==service.id,family+" passenger view preserves assignment")
			check(game.tv.passenger_transform().origin.is_finite(),family+" valid passenger position")
			await capture(family+"-pax-"+str(preset))
		game.tv.passenger_seat = true
		await capture(family+"-seat")
		game.tv.passenger_seat = false
		game.tv.set_passenger_view(false)
		game.cam.set_mode(0)
		game.cam.follow = false
		game.cam.pivot = game.tv.cars[1].global_position
		game.cam.yaw = .7
		game.cam.distance = 35
		game.cam.pitch = -.23
		await capture(family+"-exterior")
	game._select_train("K1")
	game._passenger_preset(1)
	game.train.automatic = true
	game._set_paused(false)
	var before: float = game.world.time
	for i in 180: await process_frame
	check(game.world.time>before,"live simulation advances with detailed traffic")
	check(game.world.events.is_empty(),"traffic remains safe during live source check")
	check(game.audio._sched.axles==game.tv.sound_axles(),"passenger switching preserves actual audio geometry")
	print("Coach traffic integration: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
