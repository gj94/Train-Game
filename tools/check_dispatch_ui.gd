extends SceneTree
## Headless integration smoke: actual scene, buttons, routing, cab handoff,
## opposing meet and completion. Run after tests/run_tests.gd.

func _initialize() -> void:
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
	desk._roster.T2.pressed.emit()
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
	w.step(520)
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
	for asset in ["leafy_grass", "gravel_floor_02", "roof_tiles"]:
		var texture: Texture2D = load("res://assets/polyhaven/%s/%s_diff_2k.jpg" % [asset, asset])
		if not _expect(texture.get_image().has_mipmaps(), asset + " imported with mipmaps"):
			return
	print("Dispatch integration: PASS (buttons, two trains, cab, complete meet, mipmapped textures)")
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
