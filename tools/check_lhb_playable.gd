extends SceneTree
## Real game checks, including physical axle alignment, UI controls and arrival.

func _initialize() -> void:
	call_deferred("_check")


func _check() -> void:
	set_meta("lhb_drive", true)
	set_meta("wap7_drive", false)
	change_scene_to_file("res://game/main.tscn")
	await process_frame
	await process_frame
	var game = current_scene
	game.paused = true
	var t: Train = game.train
	var view = game.tv
	if not _expect(game.lhb_drive and view.cars.size() == 7 and view.coaches.size() == 6, "six coaches behind WAP-7"):
		return
	if not _expect(game.cam.mode == 1 and view._cabs[0].visible, "starts in the locomotive cab"):
		return
	var physical_axles: Array = view._wheels.duplicate()
	for group in view.coach_axles:
		physical_axles.append_array(group)
	var axles: Array = view.sound_axles()
	for i in axles.size():
		var loc := t.locate_behind(game.world.graph, axles[i].x)
		var expected: Vector3 = game.world.graph.position(loc.edge, loc.s) + Vector3.UP * (1.046 if i < 6 else .9575)
		if not _expect(physical_axles.any(func(a): return a.global_position.distance_to(expected) < .02), "sound axle %d sits on physical wheels" % i):
			return
	# Passenger controls must preserve AI and traction, including changing coach.
	t.automatic = true
	t.controller = .7
	_key(game, KEY_V)
	if not _expect(game.cam.mode == 2 and t.automatic and t.controller == .7 and view.passenger_on and not view._cabs[0].visible, "passenger view preserves driver"):
		return
	for i in 4:
		_key(game, KEY_PAGEDOWN)
	_key(game, KEY_RIGHT)
	_key(game, KEY_HOME)
	if not _expect(view.passenger_coach == 4 and view.passenger_bay == 1 and view.passenger_seat and "2 TIER" in view.passenger_name(), "A1 two-tier seat camera"):
		return
	var passenger: Transform3D = view.passenger_transform()
	if not _expect(passenger.origin.distance_to(view.coaches[4].global_position) < 12, "camera belongs to selected coach"):
		return
	game._process(0)
	if not _expect(game.audio.interior_listener.x > 120, "sound listener follows A1 instead of remaining in the locomotive"):
		return
	_key(game, KEY_LEFT)
	_key(game, KEY_LEFT)
	if not _expect(view.passenger_bay == -1 and "REAR VESTIBULE" in view.passenger_name(), "rear vestibule accessible"):
		return
	_key(game, KEY_LEFT)
	if not _expect(view.passenger_bay == 9 and "FRONT VESTIBULE" in view.passenger_name(), "front vestibule accessible"):
		return
	_key(game, KEY_B)
	if not _expect(view.berths_deployed and view.middle_berths[0].size() == 18 and absf(view.middle_berths[0][0].rotation.x) < .001, "3A middle berths deploy"):
		return
	_key(game, KEY_B)
	if not _expect(not view.berths_deployed and absf(view.middle_berths[0][0].rotation.x) > 1.5, "middle berths fold back into seats"):
		return
	_key(game, KEY_V)
	if not _expect(game.cam.mode == 1 and not t.automatic and t.controller == 0 and not view.passenger_on, "returning to the driving cab takes manual control"):
		return
	if not _expect(game.audio.interior_listener == game.TrainAudio.DRIVER, "cab restores original sound listener"):
		return
	_hold(game, KEY_W, 2)
	if not _expect(t.controller > .9 and t.speed > .3 and t.odometer > .1, "W drives the coupled passenger rake"):
		return
	_hold(game, KEY_S, 3)
	if not _expect(t.controller < -.9, "S moves from power into service brake"):
		return
	_key(game, KEY_SPACE)
	game.world.step(10)
	if not _expect(t.speed == 0 and t.emergency, "emergency stops passenger rake"):
		return
	_key(game, KEY_SPACE)
	_key(game, KEY_TAB)
	for pair in [["MRT-SE1", "KDP-H"], ["KDP-H", "BUFFER:KDP_B"]]:
		game.dispatcher.select_signal(pair[0], true)
		game.dispatcher._select_destination(pair[1])
		game.dispatcher._set.pressed.emit()
	t.automatic = true
	game.world.step(750)
	view.update()
	if not _expect(t.service_complete and t.path.size() == 1 and game.world.events.is_empty(), "safe arrival and tail clearance"):
		return
	var old_head := t.head_s
	_key(game, KEY_R)
	if not _expect(t.head_s == old_head and t.cab_end == 1 and "run-round" in game.hud._toast.text, "return requires run-round"):
		return
	game.dispatcher._lhb_button.pressed.emit()
	await process_frame
	await process_frame
	if not _expect(not current_scene.lhb_drive and current_scene.train_views.size() == 2, "F3 button restores original MEMU meet"):
		return
	print("LHB playable: PASS (30 axles, six coaches, both passenger classes, berth animation, W/S/brakes, safe arrival, run-round guard, scenario selection)")
	quit(0)


func _hold(game, key: int, seconds: float) -> void:
	var input := InputEventKey.new()
	input.physical_keycode = key
	input.pressed = true
	Input.parse_input_event(input)
	Input.flush_buffered_events()
	game.paused = false
	for i in int(seconds * 60):
		game._physics_process(1.0 / 60)
	input = InputEventKey.new()
	input.physical_keycode = key
	Input.parse_input_event(input)
	Input.flush_buffered_events()
	game.paused = true
	game.tv.update()


func _key(game, key: int) -> void:
	var input := InputEventKey.new()
	input.physical_keycode = key
	input.pressed = true
	game._unhandled_input(input)


func _expect(condition: bool, label: String) -> bool:
	if not condition:
		printerr("LHB playable FAIL: ", label)
		quit(1)
	return condition
