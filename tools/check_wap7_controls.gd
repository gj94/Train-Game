extends SceneTree
## End-to-end new cab controls, optical state, and F2/F3 scenario selection.
var game
var failures := 0
var checks := 0
func _initialize() -> void:
	set_meta("imported_fleet","wap7")
	set_meta("traffic_drive",false)
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+message)
func frames() -> void:
	for i in 3: await process_frame
func key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode=code
	event.pressed=true
	game._unhandled_input(event)
func bind_game() -> void:
	game=current_scene
	game.set_physics_process(false)
	game.controller.set_process(false)
	for sound in game.train_audio.values(): sound.set_process(false)
func run() -> void:
	change_scene_to_file("res://game/main.tscn")
	await frames()
	bind_game()
	check(game.train.stock_kind=="ported:wap7","solo WAP-7 selects detailed imported stock")
	check(game.tv.models[0].get_meta("detailed_wap7",false),"detailed model installed")
	var eye: Vector3=game.tv.cab_transform().origin
	for position in 4:
		key(KEY_HOME)
		check(game.tv.cab_position==(position+1)%4,"Home cycles cab inspection position")
	check(game.tv.cab_transform().origin.distance_to(eye)<.001,"inspection cycle returns to driver")
	var pane: Dictionary=game.tv.glass[0][0]
	check(pane.node.get_active_material(pane.surface)==pane.clear,"cab uses onboard window optics")
	key(KEY_TAB)
	check(pane.node.get_active_material(pane.surface)==pane.exterior,"exterior restores source glazing")
	key(KEY_TAB)
	check(pane.node.get_active_material(pane.surface)==pane.clear,"returning to cab restores clear optics")
	key(KEY_F3)
	check(game.hud.modal=="confirm","F3 requires the existing scenario-change confirmation")
	game._confirm_action()
	await frames()
	bind_game()
	check(game.train.stock_kind=="ported:lhb" and game._has_passengers(),"F3 loads detailed WAP-7 with mixed LHB")
	check(game.tv.models[0].get_meta("detailed_wap7",false),"LHB receives same detailed locomotive")
	key(KEY_V)
	var seat: bool=game.tv.passenger_seat
	key(KEY_HOME)
	check(game.tv.passenger_seat!=seat,"passenger Home still switches aisle and seat")
	key(KEY_F2)
	game._confirm_action()
	await frames()
	bind_game()
	check(game.train.stock_kind=="ported:wap7","F2 switches to detailed light engine")
	key(KEY_F2)
	game._confirm_action()
	await frames()
	bind_game()
	check(game.imported_fleet.is_empty() and game.world.trains.size()==6,"second F2 returns to MEMU services")
	print("Detailed WAP-7 controls: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
