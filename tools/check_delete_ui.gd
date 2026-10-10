extends SceneTree
var game
var checks:=0
var failures:=0
func _initialize() -> void:
	set_meta("legacy_kerala_traffic",true)
	set_meta("route","kerala_coast");set_meta("traffic_seed",0)
	call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func tap(button: int) -> void:
	for down in [true,false]:
		var event:=InputEventJoypadButton.new();event.device=13;event.button_index=button;event.pressed=down
		Input.parse_input_event(event);Input.flush_buffered_events()
		await process_frame;await process_frame
		game.controller._process(.016)
func run() -> void:
	root.size=Vector2i(1280,720)
	change_scene_to_file("res://game/main.tscn")
	await process_frame;await process_frame
	game=current_scene;game.set_physics_process(false)
	var started:=Time.get_ticks_msec()
	while game.wv.loading and Time.get_ticks_msec()-started<120000:await process_frame
	game.set_process(false);game.cam.set_process(false)
	game.controller.set_process(false);game.controller.settings_path="res://.local/delete-controller-test.cfg"
	game.controller.window_focus(true);game.controller._adopt(13);game.controller._set_mode(true)
	game.controller._process(.016)
	var desk=game.dispatcher
	desk.set_open(true);desk.inspect_train("K1")
	check(desk._delete_service.disabled,"assigned service deletion disabled")
	desk._prompt_delete();check(not desk._confirm.visible,"assigned service cannot open delete confirmation")
	desk.inspect_train("K2");desk._delete_service.pressed.emit()
	check(desk._confirm.visible and desk._confirm_delete,"delete opens existing controller modal")
	check("K2" in desk._confirm_text.text and "Northbound Morning LHB" in desk._confirm_text.text,"confirmation names exact service")
	await process_frame;await process_frame
	check(desk._root.get_global_rect().encloses(desk._confirm.get_global_rect()),"confirmation stays fully inside the viewport")
	check((desk._confirm.position+desk._confirm.size*.5-desk._root.size*.5).length()<1,"confirmation is centered within the dispatch UI")
	check(root.gui_get_focus_owner()==desk._confirm_no,"confirmation defaults to Keep service")
	await tap(JOY_BUTTON_B)
	check(game.world.trains.has("K2") and root.gui_get_focus_owner()==desk._delete_service,"cancel preserves service and restores controller focus")
	game._view_train_only("K2")
	desk.set_open(true);desk.inspect_train("K2")
	var buses_before:=AudioServer.bus_count
	desk._prompt_delete()
	if DisplayServer.get_name()!="headless":
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.local/delete-service-confirm.png")
	desk._confirm_yes.grab_focus();await tap(JOY_BUTTON_A)
	await process_frame;await process_frame
	check(not game.world.trains.has("K2"),"confirmed deletion removes simulation service")
	check(not desk._roster.has("K2") and desk.inspected_train=="K1","roster and inspector return to assigned service")
	check(game.train.id=="K1" and desk.selected_train=="K1","driver assignment preserved")
	check(not game.train_views.has("K2") and not game.train_audio.has("K2") and not game.train_motions.has("K2"),"view, sound and interpolated motion released")
	check(game.traffic_presentation.followed_service.is_empty() and game.cam.follow_point==game.tv.overview_position,"deleted viewed train returns camera to own service")
	check(AudioServer.bus_count<buses_before,"deleted service audio buses released")
	check(root.gui_get_focus_owner()==desk._roster.K1,"controller focus returns to a valid service")
	desk.show_timetable(true);desk._refresh();game._process(.3)
	check(desk._timetable._current_schedule==game.train.timetable,"timetable uses surviving service")
	desk.inspect_train("K3");desk._prompt_delete();desk.inspected_train="K4";desk._confirm_yes.pressed.emit()
	check(not game.world.trains.has("K3") and game.world.trains.has("K4"),"confirmation acts on captured service, not changed inspection")
	game.world.step(2)
	check(game.world.events.is_empty(),"simulation advances safely after deleting plan participants")
	print("Delete UI: %d checks, %d failures" % [checks,failures])
	game.queue_free();await process_frame;await process_frame
	quit(0 if failures==0 else 1)
