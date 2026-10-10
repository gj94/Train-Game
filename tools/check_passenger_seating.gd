extends SceneTree
## Seated AI handover, local row head-outs and save compatibility in source game.
var checks:=0
var failures:=0
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL "+label)
func _initialize() -> void:
	set_meta("route","kerala_coast");set_meta("traffic_seed",0);set_meta("legacy_kerala_traffic",true)
	call_deferred("run")
func button(g, id: int) -> void:
	var event:=InputEventJoypadButton.new();event.button_index=id;event.pressed=true
	preload("res://game/controller_camera.gd").button(g.controller,event)
func run() -> void:
	root.size=Vector2i(1280,720)
	change_scene_to_file("res://game/main.tscn")
	await process_frame;await process_frame
	var g=current_scene
	g.set_physics_process(false)
	check(g.wv._loading_panel.get_node("BuildVersion").text=="Development build","loading screen displays the source version")
	check(preload("res://game/build_version.gd").describe("Build: TrainGame-Kerala-Coast-R27-Windows\nSource base: abc123\n")=="TrainGame-Kerala-Coast-R27-Windows · abc123","release identity comes from packaged metadata")
	var began:=Time.get_ticks_msec()
	while g.wv.loading and Time.get_ticks_msec()-began<120000:await process_frame
	g.set_process(false);g.cam.set_process(false)
	for id in ["K1","K2","K3","K5"]:
		g._select_train(id);g._render_trains(1)
		g.cam.global_transform=g.cam._target();g._geographic_frame();g._render_trains(1)
		g._passenger_preset(1)
		g.hud.show_modal("");g._set_paused(false)
		check(g.walker.stand(),id+" can stand in a passenger aisle")
		g.train.automatic=false
		check(g.walker.sit({kind="seat",seat=8}),id+" can sit in a passenger seat")
		check(g.train.automatic and g._passenger_seated(),id+" sitting transfers driving to AI")
		g.controller.shortcut("ai");g.controller.shortcut("coast");g.controller.shortcut("emergency");g.dispatcher.toggle_driver()
		check(g.train.automatic and not g.train.emergency,id+" driving shortcuts and desk toggle cannot override seated AI")
		var pad=g.controller
		pad.active_device=0;pad._focused=true;pad._armed=true;pad._context="drive";pad._axes[5]=1
		check(pad.drive_input()==0,id+" trigger cannot drive while seated")
		pad._axes[5]=0;pad._operation_down=false
		var car: Node3D=g.tv.cars[g.tv.passenger_coach]
		var seat: Vector3=car.to_local(g.tv.passenger_transform().origin)
		button(g,JOY_BUTTON_DPAD_LEFT)
		var left: Vector3=car.to_local(g.cam._target().origin)
		check(g._passenger_head_out() and g.cam.head_out_side==-1 and absf(left.z-seat.z)<.001,id+" left head-out stays at the exact selected row")
		check(g.train.automatic and g._passenger_seated(),id+" left head-out retains seated AI lock")
		button(g,JOY_BUTTON_DPAD_RIGHT)
		check(g.cam.mode==2 and g.tv.passenger_seat_index==8,id+" returns to the same seat")
		button(g,JOY_BUTTON_DPAD_RIGHT)
		var right: Vector3=car.to_local(g.cam._target().origin)
		print(id," row deltas: left ",left-seat," right ",right-seat)
		check(g._passenger_head_out() and g.cam.head_out_side==1 and absf(right.z-seat.z)<.001 and absf(right.x-left.x)>3.5,id+" right head-out is on the opposite side at the same row")
		var save=g.save_load.capture_session()
		var result=preload("res://sim/world_snapshot.gd").restore(preload("res://sim/world_snapshot.gd").capture(g.world,save))
		check(result.ok and g.save_load.validate_session(result).is_empty(),id+" passenger head-out state is saveable")
		g._pilot_camera();g.train.automatic=false;g.save_load.restore_view(save)
		check(g._passenger_head_out() and g._passenger_seated() and g.train.automatic,id+" load restores row head-out and AI lock")
		g.hud.show_modal("");g._set_paused(false)
		check(g.walker.stand() and g.walker.car==g.tv.passenger_coach and not g._passenger_seated(),id+" standing from head-out stays in that carriage and releases seat lock")
		g._pilot_camera();g.dispatcher.toggle_driver()
		check(not g.train.automatic,id+" normal driver toggle works after leaving the seat")
		# R26 and older saves lack the passenger head-out field.
		save.view.erase("passenger_head_out");save.camera.mode=2
		g.save_load.restore_view(save)
		check(g.cam.mode==2 and g.train.automatic,id+" old passenger save restores with AI and no missing field")
		g.hud.show_modal("");g._set_paused(false)
	g._select_train("K1");g._render_trains(1);g._passenger_preset(0)
	g.tv.passenger_seat=true;g._passenger_seating_changed();g._head_out_camera(1,false);g.cam.global_transform=g.cam._target();g._process(.01)
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/passenger-row-head-out.png")
	# Finish pending workers before scene teardown; the fixture disabled _process.
	g.cam.set_process(false);g.wv.queue.clear()
	began=Time.get_ticks_msec()
	while (not g.wv._asset_worker.job.is_empty() or g.wv.workers.any(func(w):return not w.runner.job.is_empty()) or not g.wv._activating.is_empty()) and Time.get_ticks_msec()-began<120000:
		g.wv.update();g.wv.queue.clear();await process_frame
	print("Passenger seating / row head-out / version: %d checks, %d failures" % [checks,failures])
	g.queue_free();await process_frame;await process_frame
	quit(1 if failures else 0)
