extends SceneTree
## Real scene integration: selection, two cabs, controls, axle geometry and return.

func _initialize() -> void:
	call_deferred("_check")


func _check() -> void:
	set_meta("wap7_drive", true)
	change_scene_to_file("res://game/main.tscn")
	await process_frame
	await process_frame
	var game = current_scene
	game.paused = true
	var t: Train = game.train
	var view = game.tv
	var desk = game.dispatcher
	if not _expect(game.wap7_drive and game.train_views.size() == 1 and view.cars.size() == 1 and view._wheels.size() == 6, "one locomotive, six axles"):
		return
	if not _expect(game.cam.mode == 1 and view._cabs[0].visible and not view._cabs[1].visible and not desk._root.visible, "starts in Cab 1"):
		return
	var sound_axles: Array = view.sound_axles()
	for i in sound_axles.size():
		var loc := t.locate_behind(game.world.graph, sound_axles[i].x)
		var expected: Vector3 = game.world.graph.position(loc.edge, loc.s) + Vector3.UP * 1.046
		var found := false
		for wheel in view._wheels:
			if wheel.global_position.distance_to(expected) < .02:
				found = true
		if not _expect(found, "sound axle %d matches a physical wheelset on the rails" % i):
			return
	# Feed a held key through Input, exercise the real controller path and physics.
	var press := InputEventKey.new()
	press.physical_keycode = KEY_W
	press.pressed = true
	Input.parse_input_event(press)
	Input.flush_buffered_events()
	game.paused = false
	for i in 120:
		game._physics_process(1.0 / 60)
	var release := InputEventKey.new()
	release.physical_keycode = KEY_W
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	game.paused = true
	view.update()
	if not _expect(t.controller > .9 and t.speed > .5 and t.odometer > .1, "W drives the actual scene"):
		return
	var brake_press := InputEventKey.new()
	brake_press.physical_keycode = KEY_S
	brake_press.pressed = true
	Input.parse_input_event(brake_press)
	Input.flush_buffered_events()
	game.paused = false
	for i in 180:
		game._physics_process(1.0 / 60)
	var brake_release := InputEventKey.new()
	brake_release.physical_keycode = KEY_S
	Input.parse_input_event(brake_release)
	Input.flush_buffered_events()
	game.paused = true
	view.update()
	if not _expect(t.controller < -.9 and "BRAKE 100%" in view._cab_interior._display.text, "S moves through coast into service braking"):
		return
	_key(game, KEY_SPACE)
	game.world.step(10)
	view.update()
	if not _expect(t.speed == 0 and t.emergency and "EMERGENCY" in view._cab_interior._display.text, "emergency stops locomotive and updates DDU"):
		return
	_key(game, KEY_SPACE)
	_key(game, KEY_X)
	if not _expect(not t.emergency and t.controller == 0, "release and coast"):
		return
	_key(game, KEY_TAB)
	if not _expect(game.cam.mode == 0 and not view._cabs[0].visible and desk._root.visible, "overview and route desk"):
		return
	for pair in [["MRT-SE1", "KDP-H"], ["KDP-H", "BUFFER:KDP_B"]]:
		desk.select_signal(pair[0], true)
		desk._select_destination(pair[1])
		desk._set.pressed.emit()
	desk.toggle_driver()
	game.world.step(650)
	view.update()
	if not _expect(t.service_complete and game.world.events.is_empty(), "complete safe outbound trip"):
		return
	var physical_body: Transform3D = view._body.global_transform
	_key(game, KEY_R)
	view.update()
	_key(game, KEY_TAB)
	if not _expect(t.cab_end == 2 and view._cabs[1].visible and not view._cabs[0].visible and "CAB 2" in view._cab_interior._display.text, "R selects Cab 2"):
		return
	if not _expect(view._body.global_position.distance_to(physical_body.origin) < .001 and view._body.global_basis.z.distance_to(physical_body.basis.z) < .001, "changing ends preserves physical body orientation"):
		return
	var eye: Transform3D = view.cab_transform()
	if not _expect(eye.basis.z.dot(physical_body.basis.z) < -.9, "Cab 2 faces the return direction"):
		return
	for pair in [["KDP-S", "MRT-HW"], ["MRT-HW", "MRT-SW1"], ["MRT-SW1", "CPM-H"], ["CPM-H", "BUFFER:CPM_B1"]]:
		desk.select_signal(pair[0], true)
		desk._select_destination(pair[1])
		desk._set.pressed.emit()
	t.automatic = true
	game.world.step(650)
	if not _expect(t.service_complete and t.path[0].edge == "cpm_p1" and game.world.events.is_empty(), "safe return to Chennapuram"):
		return
	desk._scenario_button.pressed.emit()
	await process_frame
	await process_frame
	if not _expect(not current_scene.wap7_drive and current_scene.train_views.size() == 2, "button restores two-MEMU scenario"):
		return
	print("WAP7 playable: PASS (W/S input, emergency/release, six axles, both cabs, physical orientation, routes, round trip, scenario button)")
	quit(0)


func _key(game, key: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	game._unhandled_input(event)


func _expect(condition: bool, description: String) -> bool:
	if not condition:
		printerr("WAP7 playable FAIL: ", description)
		quit(1)
	return condition
