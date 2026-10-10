extends SceneTree
## Source-game integration: HUD, service handover and nearby presentation lifetime.
var game
var checks:=0
var failures:=0

func _initialize() -> void:
	set_meta("route","kerala_coast")
	set_meta("traffic_seed",0)
	call_deferred("run")

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+message)

func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/journey-"+name+".png")

func run() -> void:
	root.size=Vector2i(1280,720)
	change_scene_to_file("res://game/main.tscn")
	await process_frame;await process_frame
	game=current_scene
	game.set_physics_process(false)
	var started:=Time.get_ticks_msec()
	while game.wv.loading and Time.get_ticks_msec()-started<120000: await process_frame
	game.set_process(false)
	game.cam.set_process(false)
	game._process(.3)
	check(game.world.trains.size()==100 and game.train.id=="K1","100 services with slow passenger selected")
	check(game.train_views.size()<5 and game.train_audio.size()==game.train_views.size(),"distant detailed trains/audio are not allocated")
	check(game.train.timetable.stops[1].name in game.hud._mode.text and " m · " in game.hud._mode.text and "min" in game.hud._mode.text,"HUD contains next stop, metres and minutes")
	check(not "PILOT" in game.hud._mode.text and not "OVERVIEW" in game.hud._mode.text,"HUD does not label the camera")
	print("JOURNEY_HUD ",game.hud._mode.text)
	game.hud._toast.text=""
	await shot("pilot")
	game._set_time_scale(8)
	game._process(.3)
	check("×8" in game.hud._mode.text,"clock still shows fast forward")
	var text_at_eight: String=game.hud._mode.text.split("\n")[0]
	game._set_time_scale(1)
	game._process(.3)
	check(game.hud._mode.text.split("\n")[0]==text_at_eight,"ETA remains in world minutes at any time scale")
	var resident_before: int=game.train_views.size()
	var buses_before:=AudioServer.bus_count
	game.train.controller=.3
	game._view_train_only("B011")
	check(game.train.id=="K1" and game.train.controller==.3,"view-only distant train preserves driving assignment and handle")
	check(game.train_views.has("B011") and game.train_audio.has("B011"),"view-only loads distant train and sound")
	check(game.traffic_presentation.followed_service=="B011","followed service remains pinned during camera transfer")
	game._pilot_camera()
	game.cam.global_transform=game.cam._target()
	game._process(.6)
	await process_frame;await process_frame
	check(not game.train_views.has("B011") and not game.train_audio.has("B011"),"returning to pilot releases distant presentation")
	check(game.train_views.size()==resident_before and AudioServer.bus_count==buses_before,"temporary view releases its nodes and audio buses")
	game._select_train("B020")
	check(game.train.id=="K1" and not game.train_views.has("B020"),"future service cannot create a ghost train or take control before entry")
	game._select_train("B011")
	game.cam.global_transform=game.cam._target()
	game._process(.3)
	check(game.train.id=="B011" and game.tv==game.train_views.B011 and game.audio==game.train_audio.B011,"distant service handover loads valid view and audio")
	check("Haripad" in game.hud._mode.text,"HUD switches to new service's booked stop immediately")
	check(game.world.trains.K1.automatic,"old service remains simulated under AI")
	game._select_train("K1")
	game._pilot_camera()
	game.cam.global_transform=game.cam._target()
	game._process(.6)
	game.dispatcher.set_open(true)
	check(not game.hud._dispatch_notice.visible,"driver wait banner hides immediately when dispatch opens")
	started=Time.get_ticks_msec()
	while game.wv.loading and Time.get_ticks_msec()-started<120000:
		game.wv.update();await process_frame
	check(not game.wv.loading,"dispatcher capture waits for scenery readiness")
	game.hud._toast.text=""
	await process_frame;await process_frame
	await shot("dispatcher")
	var snapshot: Dictionary=game.world.dispatcher().snapshot()
	check(snapshot.services.size()==100,"dispatcher exposes every scheduled service")
	game._view_train_only("B011")
	game.world.trains.B011.lifecycle="stored"
	game.traffic_presentation.update(1.0)
	check(not game.train_views.has("B011") and game.traffic_presentation.followed_service.is_empty() and not game.cam.follow,"depot storage releases a watched AI train without a ghost or dangling camera follow")
	print("Journey / traffic: %d checks, %d failures" % [checks,failures])
	game.queue_free()
	await process_frame;await process_frame
	quit(1 if failures else 0)
