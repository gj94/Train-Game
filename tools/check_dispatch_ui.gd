extends SceneTree
## Headless integration smoke: actual scene, buttons, routing, cab handoff,
## timetables, opposing meet and completion. Run after tests/run_tests.gd.

func _initialize() -> void:
	set_meta("small_test_layout", true) # preserve the original layout regression fixture
	call_deferred("_check")

func _check() -> void:
	change_scene_to_file("res://game/main.tscn")
	await process_frame
	await process_frame
	var game = current_scene
	game.paused = true
	var desk = game.dispatcher
	var w: RailWorld = game.world
	if not _expect(game.train_views.size() == 2 and game.train_views.T1.cars.size() == 8 and game.train_views.T2.cars.size() == 8, "Two full MEMUs"):
		return
	desk._table_button.pressed.emit()
	if not _expect(desk.timetable_open and desk._timetable.visible and not desk._map.visible and desk._timetable._items.size() == 3, "Timetable button and three stop rows"):
		return
	var rows = desk._timetable._items
	if not _expect(rows[0].get_text(4) == "08:01:00" and rows[1].get_text(1) == "mrt_loop" and rows[1].get_text(2) == "+4 min" and rows[1].get_text(3) == "08:05:00" and rows[1].get_text(4) == "08:06:00", "Block, offset, planned arrival and departure cells"):
		return
	desk._roster.T2.pressed.emit()
	desk._refresh()
	if not _expect(desk._timetable._items[0].get_text(4) == "08:02:00" and desk._timetable._items[1].get_text(1) == "mrt_main", "Timetable follows selected service"):
		return
	desk.drive_requested.emit()
	if not _expect(game.train.id == "T2" and game.audio.train.id == "T2" and game.tv._cab_interior.visible and not w.trains.T2.automatic, "Selected cab and driver handoff"):
		return
	desk.toggle_driver()
	game.cam.set_mode(0)
	game._set_cab_visuals(false)
	_route(desk, "CPM-S1", "MRT-HE")
	_route(desk, "MRT-HE", "MRT-SE2")
	if not _expect(w.aspect("CPM-S1") == RailWorld.Aspect.GREEN, "Green requires onward route"):
		return
	# Cancel and restore an unused loop route through its real UI button.
	desk._cancel.pressed.emit()
	if not _expect(w.aspect("MRT-HE") == RailWorld.Aspect.RED and w.switch_lock_reason("MRT_1") == "", "Unused route cancellation"):
		return
	_route(desk, "MRT-HE", "MRT-SE2")
	_route(desk, "KDP-S", "MRT-HW")
	_route(desk, "MRT-HW", "MRT-SW1")
	w.step(50)
	if not _expect(w.trains.T1.odometer == 0 and w.trains.T2.odometer == 0, "Green routes still wait for timetable departure"):
		return
	w.step(470)
	if not _expect(w.trains.T1.path[0].edge == "mrt_loop" and w.trains.T2.path[0].edge == "mrt_main", "Opposing station arrivals"):
		return
	for pair in [["MRT-SE2", "KDP-H"], ["MRT-SW1", "CPM-H"], ["KDP-H", "BUFFER:KDP_B"], ["CPM-H", "BUFFER:CPM_B1"]]:
		_route(desk, pair[0], pair[1])
	w.step(800)
	desk._refresh()
	if not _expect(w.trains.T1.service_complete and w.trains.T2.service_complete and desk._restart.visible, "Both arrivals and restart UI"):
		return
	if not _expect(w.events.is_empty(), "No safety interventions"):
		return
	if not _expect(desk._timetable._items[2].get_text(6).begins_with("A 08:") and desk._timetable._items[2].get_text(7).begins_with("Arrived"), "Actual arrival and final status cells"):
		return
	w.time = 16 * 3600 + 1
	desk._refresh()
	if not _expect(desk._clock.text.begins_with("00:00:01  ·  D2") and desk._timetable._stamp(86460, 86340) == "00:01:00 +1d", "24-hour clock and overnight timetable display"):
		return
	for asset in ["leafy_grass", "gravel_floor_02", "roof_tiles"]:
		var texture: Texture2D = load("res://assets/polyhaven/%s/%s_diff_2k.jpg" % [asset, asset])
		if not _expect(texture.get_image().has_mipmaps(), asset + " imported with mipmaps"):
			return
	print("Dispatch integration: PASS (buttons, timetables, clock rollover, two trains, cab, complete meet, mipmapped textures)")
	quit(0)

func _route(desk, entrance: String, destination: String) -> void:
	desk.select_signal(entrance, true)
	desk._select_destination(destination)
	desk._set.pressed.emit()

func _expect(condition: bool, description: String) -> bool:
	if not condition:
		printerr("Dispatch integration FAIL: ", description)
		quit(1)
	return condition
