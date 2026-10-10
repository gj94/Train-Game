extends SceneTree
## Native source-game integration: responsive skip UI, no 3D/sound, safe return.
var checks:=0
var failures:=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL "+message)
func _initialize() -> void:
	set_meta("route","kerala_coast");set_meta("traffic_seed",0)
	call_deferred("run")
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/skip-"+name+".png")
func run() -> void:
	root.size=Vector2i(1280,720)
	change_scene_to_file("res://game/main.tscn")
	await process_frame;await process_frame
	var g=current_scene
	g.set_physics_process(false)
	var began:=Time.get_ticks_msec()
	while g.wv.loading and Time.get_ticks_msec()-began<120000:await process_frame
	g.set_process(false);g.cam.set_process(false)
	var clock: float=g.world.clock_seconds()
	var motion_distance: float=g.train_motions.K1._current_odometer
	g.dispatcher.auto_dispatch=false
	g.time_skip.open()
	check(g.hud.modal=="time_skip" and g.paused,"skip menu pauses driving")
	g.time_skip.clock_page()
	var selected: float=g.time_skip.selected_clock
	g.time_skip.action("skip:adjust:1")
	check(g.time_skip.selected_clock==selected+60 and g.hud._buttons.get_child(5).has_focus(),"clock adjustments preserve controller focus")
	g.time_skip.stop_page()
	check(g.hud._buttons.get_child_count()>40,"later-stop menu exposes the remaining passenger calls")
	g.time_skip.start(clock+180)
	check(g.get_viewport().disable_3d and g.process_mode==Node.PROCESS_MODE_DISABLED,"3D rendering and game processing disabled")
	check(AudioServer.is_bus_mute(0),"audio disabled during skip")
	check(g.world.trains.values().all(func(t):return t.automatic) and g.dispatcher.auto_dispatch and g.world.dispatcher().enabled,"all 100 services and dispatcher under AI, including the UI toggle")
	check(g.hud.can_process() and g.controller.can_process(),"progress menu and controller remain responsive")
	await shot("progress")
	while g.time_skip.running():await process_frame
	check(absf(g.world.clock_seconds()-clock-180)<.001,"returns at chosen time")
	check(g.train.odometer>motion_distance and absf(g.train_motions.K1._current_odometer-g.train.odometer)<.01,"real motion advanced and interpolation reset")
	check(not g.get_viewport().disable_3d and not AudioServer.is_bus_mute(0),"rendering and sound state restored")
	check(g.train.id=="K1" and g.cam.mode==1 and g.train.automatic,"same train pilot seat with AI still driving")
	check(g.paused and g.hud.modal=="time_skip","completion pauses for player choice")
	await shot("complete")
	g.time_skip.start(g.world.clock_seconds()+3600)
	while g.time_skip._preparing:await process_frame
	check(g.time_skip._worker!=null,"dedicated simulation worker owns the live railway")
	# Stale button callbacks cannot leave the progress page or touch live state.
	g._ui_action("resume");g._ui_action("save:quick")
	g.time_skip.action("skip:resume")
	check(g.paused and g.hud.modal=="time_skip","other UI actions are blocked during worker ownership")
	# A connected controller's menu/hint path must work without reading a train.
	var selected_train=g.train
	var controller_focused: bool=g.controller._focused
	g.train=null
	g.controller.active_device=123;g.controller.controller_mode=true;g.controller._focused=true
	g.controller._process(.016)
	check(g.hud._pad_hint.text.contains("D-pad / LS move"),"connected controller menu hints do not read worker-owned train state")
	g.train=selected_train
	g.controller.active_device=-1;g.controller._focused=controller_focused
	var cancelled:=Time.get_ticks_msec()
	g.controller._back()
	check(g.time_skip.running(),"controller Back requests asynchronous cancellation")
	while g.time_skip.running():await process_frame
	check(g.time_skip.trial.done and not g.time_skip.trial.ok and not g.get_viewport().disable_3d,"controller Back cancels and restores rendering")
	check(Time.get_ticks_msec()-cancelled<2000,"cancellation returns promptly at a simulation step boundary")
	check(g.world.trains.values().all(func(t):return t.automatic),"cancellation retains AI")
	g.time_skip.start(g.world.clock_seconds()+3600)
	while g.time_skip._preparing:await process_frame
	g.controller.active_device=123
	g.controller._connection_changed(123,false)
	while g.time_skip.running():await process_frame
	check(not g.time_skip.trial.ok and g.paused and g.hud.modal=="time_skip","controller disconnection stops safely without exposing the live railway")
	g.time_skip.start(g.world.clock_seconds()+3600)
	while g.time_skip._preparing:await process_frame
	g._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	check(g.time_skip.running() and g.hud.modal=="time_skip","window close waits for worker cancellation")
	while g.time_skip.running():await process_frame
	check(g.hud.modal=="confirm" and g._pending_action=="quit","quit confirmation opens only after worker returns")
	g._cancel_action()
	# Exercise the off-network return path; lifecycle/depot movement has separate
	# pure-simulation coverage and a full-day 100-service audit.
	g.train.lifecycle="stored"
	g.time_skip.start(g.world.clock_seconds()+1)
	while g.time_skip.running():await process_frame
	g._process(.6)
	check(g.cam.mode==0 and g.cam.free_flight and not g.cam.follow,"unavailable service returns to a platform observer")
	check(is_instance_valid(g.tv) and not g.traffic_presentation.roots.K1.visible,"inactive selected binding stays valid without a ghost train")
	g._pilot_camera()
	check(g.cam.mode==0,"cannot enter an off-network train")
	check(g.train.automatic,"platform return does not take manual control")
	var restored: Dictionary=preload("res://sim/world_snapshot.gd").restore(preload("res://sim/world_snapshot.gd").capture(g.world,g.save_load.capture_session()))
	check(restored.ok and g.save_load.validate_session(restored).is_empty(),"platform observer state remains saveable after service storage")
	await shot("platform")
	# This harness deliberately disables the game's _process. Pump its streaming
	# update before teardown, as normal gameplay does after a camera transfer.
	began=Time.get_ticks_msec()
	while g.wv.loading and Time.get_ticks_msec()-began<120000:
		g.wv.update();await process_frame
	check(not g.wv.loading,"destination scenery finishes loading after skip")
	# Drain outstanding far-scenery jobs while the render loop can still run.
	# Joining a worker inside scene teardown can otherwise await that loop.
	g.wv.queue.clear();began=Time.get_ticks_msec()
	while (not g.wv._asset_worker.job.is_empty() or g.wv.workers.any(func(w):return not w.runner.job.is_empty()) or not g.wv._activating.is_empty()) and Time.get_ticks_msec()-began<120000:
		g.wv.update();g.wv.queue.clear();await process_frame
	g.time_skip.start(g.world.clock_seconds()+3600)
	while g.time_skip._preparing:await process_frame
	check(g.time_skip._worker!=null,"worker active before scene teardown")
	g.queue_free();await process_frame;await process_frame
	check(not root.disable_3d and not AudioServer.is_bus_mute(0),"scene teardown joins the worker and restores viewport/audio")
	print("Time skip: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
