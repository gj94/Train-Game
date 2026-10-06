extends SceneTree
## Integration checks for pause/input safety and uncluttered display transitions.
func _initialize() -> void:
	call_deferred("_check")

func _key(game: Node, key: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	game._unhandled_input(event)

func _check() -> void:
	change_scene_to_file("res://game/main.tscn")
	await process_frame
	await process_frame
	var game = current_scene
	var hud = game.hud
	var desk = game.dispatcher
	if not _expect(game.traffic_drive and game.world.trains.size() == 6 and game.train_views.size() == 6, "default six-service traffic scenario"): return
	if not _expect(desk.auto_dispatch and desk.selected_train == game.train.id and game.audio.train == game.train, "random assignment binds desk, cab and audio"): return
	if not _expect(game.world.trains.values().filter(func(t): return not t.automatic).size() == 1 and not game.train.automatic, "other five services use AI"): return
	if not _expect(game.cam.mode == 1 and game.tv.cab_on and game._has_passengers(), "default starts in assigned passenger train's cab"): return
	if not _expect(not desk._root.visible and not hud._log.visible and game.wv.labels.all(func(l): return not l.visible), "uncluttered initial screen"): return
	_key(game, KEY_TAB) # Begin the exterior/dispatch transition checks from overview.
	_key(game, KEY_D)
	_key(game, KEY_TAB)
	if not _expect(not desk._root.visible and game.cam.mode == 1, "cab hides dispatch"): return
	_key(game, KEY_TAB)
	if not _expect(desk._root.visible, "exterior restores open desk"): return
	_key(game, KEY_D)
	_key(game, KEY_TAB)
	_key(game, KEY_TAB)
	if not _expect(not desk._root.visible, "exterior preserves closed desk"): return
	game.train.controller = .4
	_key(game, KEY_F1)
	if not _expect(hud._body.text.contains("YOUR SCENARIO") and hud._body.text.contains(game.train.id) and hud._body.text.contains("YOUR BOOKED STOPS") and hud._body.text.contains("Auto dispatch is ON"), "help explains this assignment and expected traffic"): return
	var before: float = game.world.time
	_key(game, KEY_X)
	game._physics_process(1)
	if not _expect(game.paused and hud.modal == "help" and game.world.time == before and game.train.controller == .4, "help pauses clock and blocks driving"): return
	_key(game, KEY_ESCAPE)
	if not _expect(not game.paused and hud.modal == "", "help returns to running service"): return
	_key(game, KEY_ESCAPE)
	_key(game, KEY_F1)
	_key(game, KEY_F1)
	if not _expect(game.paused and hud.modal == "pause", "help from pause returns to pause"): return
	_key(game, KEY_ESCAPE)
	_key(game, KEY_F6)
	_key(game, KEY_D)
	_key(game, KEY_F4)
	if not _expect(hud.clean_view and not hud._info.visible and not desk._root.visible and game.wv.labels.all(func(l): return not l.visible), "clean view hides HUD, board and labels"): return
	game.train.emergency = true
	game._process(0)
	if not _expect(hud._info.visible and "EMERGENCY BRAKE" in hud._info.text, "clean view retains emergency feedback"): return
	game.train.emergency = false
	_key(game, KEY_F4)
	if not _expect(desk._root.visible and game.wv.labels.all(func(l): return l.visible), "clean view restores previous display"): return
	_key(game, KEY_F8)
	hud.log_event({kind="spad", t=0.0, text="Test safety notice"})
	hud._process(10)
	if not _expect(hud._log.visible and not hud._toast.visible, "event history optional; toast expires"): return
	var old_train: Train = game.train
	_key(game, KEY_F3)
	if not _expect(hud.modal == "confirm" and game.paused and not game.lhb_drive, "F3 waits for confirmation"): return
	_key(game, KEY_ESCAPE)
	_key(game, KEY_ESCAPE)
	if not _expect(game.train == old_train and not game.paused, "cancel preserves current run"): return
	_key(game, KEY_ESCAPE)
	_key(game, KEY_F4)
	if not _expect(hud.clean_view and not game.paused and hud.modal == "", "F4 from pause resumes with clean view exactly once"): return
	_key(game, KEY_F4)
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	if not _expect(game.paused and hud.modal == "pause", "focus loss pauses safely"): return
	game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	if not _expect(hud.modal == "confirm" and game._pending_action == "quit", "window close asks before exit"): return
	print("QoL integration: PASS (default display, view restoration, modal input/clock safety, clean view, emergency feedback, event history, scenario cancel, focus loss and window close)")
	quit()

func _expect(condition: bool, label: String) -> bool:
	if not condition:
		printerr("QoL integration FAIL: ", label)
		quit(1)
	return condition
