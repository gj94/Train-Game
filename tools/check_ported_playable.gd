extends SceneTree
## Exercise the actual playable scene, fleet menu, routes and onboard controls.
const Stock := preload("res://sim/stock/ported_stock.gd")
var failures := 0
var capture := false
var views_only := false
var choices: Array = Stock.CHOICES.duplicate()

func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	views_only = "--views-only" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			choices = Array(arg.trim_prefix("--only=").split(","))
	if "--menu-only" in OS.get_cmdline_user_args(): choices = []
	call_deferred("_check")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _check() -> void:
	for choice in choices:
		set_meta("imported_fleet", choice)
		change_scene_to_file("res://game/main.tscn")
		await process_frame
		await process_frame
		var game = current_scene
		game._set_paused(true)
		game.hud.show_modal("")
		var train: Train = game.train
		check(game.imported_fleet == choice and game.train_views.size() == 1, choice + " actual scene selection")
		check(game.cam.mode == 1 and game.tv.cab_on, choice + " cab starts active")
		check(game.audio._sched.axles.size() == Stock.sound_axles(choice).size(), choice + " actual audio geometry")
		if capture:
			await screenshot(game, choice + "_cab")
		key(game, KEY_TAB)
		check(game.cam.mode == 0 and not game.tv.cab_on, choice + " exterior toggle")
		if capture:
			game.cam.follow = false
			game.cam.pivot = game.tv.cars[0].global_position
			game.cam.distance = 34
			game.cam.yaw = -.8
			game.cam.pitch = -.20
			await screenshot(game, choice + "_exterior")
		key(game, KEY_F9)
		check(game.hud.modal == "fleet" and game.paused, choice + " fleet menu pauses")
		check_fleet_menu(game, choice)
		if capture and choice == "wap7": await screenshot(game, "fleet_menu")
		game._ui_action("fleet:vb8")
		check(game.hud.modal == "confirm", choice + " selection confirmation")
		game._cancel_action()
		check(game.train == train and game.imported_fleet == choice, choice + " cancel preserves run")
		game.hud.show_modal("")
		if game._has_passengers():
			key(game, KEY_V)
			check(game.cam.mode == 2 and game.tv.passenger_on, choice + " passenger view")
			var seen := {}
			for i in game.tv.cars.size():
				seen[game.tv.formation[game.tv.passenger_coach].model] = true
				if capture: await screenshot(game, choice + "_interior_" + str(i))
				key(game, KEY_HOME)
				check(game.tv.passenger_transform().origin.is_finite(), choice + " seated viewpoint")
				key(game, KEY_HOME)
				key(game, KEY_PAGEDOWN)
			check(seen.size() == (7 if choice in ["icf", "lhb"] else (5 if choice == "vb8" else 6)), choice + " all passenger types reachable")
			key(game, KEY_TAB)
		if views_only:
			current_scene = null
			game.queue_free()
			await process_frame
			continue
		# W and S go through real held-key handling, then let the AI approach red.
		var press := InputEventKey.new()
		press.physical_keycode = KEY_W
		press.pressed = true
		Input.parse_input_event(press)
		Input.flush_buffered_events()
		game._set_paused(false)
		for i in 120: game._physics_process(1.0 / 60)
		var release := InputEventKey.new()
		release.physical_keycode = KEY_W
		Input.parse_input_event(release)
		Input.flush_buffered_events()
		game._set_paused(true)
		check(train.speed > .2 and train.controller > .9, choice + " throttle drives train")
		key(game, KEY_SPACE)
		game.world.step(10)
		check(train.speed == 0 and train.emergency, choice + " emergency braking")
		key(game, KEY_SPACE)
		train.automatic = true
		game.world.step(1500)
		check(train.speed < .1 and game.world.events.is_empty(), choice + " safe approach to red at Maruthur")
		for pair in [["MRT-E1", "E-AE1"], ["KDP-H", "BUFFER:KDP_B1"]]:
			var result: Dictionary = game.world.set_route(pair[0], pair[1])
			check(result.ok, choice + " onward route " + str(pair))
		game.world.step(1500)
		game.tv.update()
		check(train.service_complete and game.world.events.is_empty(), choice + " complete safe corridor trip")
		if train.can_change_ends:
			key(game, KEY_R)
			check(train.cab_end == 2, choice + " change ends")
			check(game.audio._sched.axles == game.tv.sound_axles(), choice + " reverse sound geometry")
			key(game, KEY_TAB)
			check(game.tv.cab_transform().origin.is_finite(), choice + " returning cab")
			if capture: await screenshot(game, choice + "_cab2")
		else:
			check(not game.world.reverse_train(train.id).ok, choice + " run-round guard")
		print("PLAYABLE ", choice)
		current_scene = null
		game.queue_free()
		await process_frame
	if views_only:
		print("Imported fleet visual captures: %d failures" % failures)
		quit(1 if failures else 0)
		return
	# Exercise an accepted menu choice, not only launch metadata.
	set_meta("imported_fleet", "wap7")
	change_scene_to_file("res://game/main.tscn")
	await process_frame
	await process_frame
	var game = current_scene
	key(game, KEY_F9)
	check_fleet_menu(game, "reloaded fleet")
	game._ui_action("fleet:wag12")
	game._confirm_action()
	await process_frame
	await process_frame
	check(current_scene.imported_fleet == "wag12" and current_scene.tv.cars.size() == 2, "confirmed menu selection reloads chosen train")
	print("Imported fleet playable checks: %d failures" % failures)
	quit(1 if failures else 0)

func check_fleet_menu(game, label: String) -> void:
	var buttons: Array = game.hud._buttons.get_children().map(func(button): return button.text)
	check(buttons.size() == Stock.CHOICES.size()+2 and "New random traffic service" in buttons, label + " traffic option and Back visible")
	for choice in Stock.CHOICES:
		check(Stock.LABELS[choice] in buttons, label + " fleet choice visible: " + choice)

func key(game, code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	game._unhandled_input(event)

func screenshot(game, label: String) -> void:
	game.cam._blend = 1.0
	game.cam._process(10)
	game.hud._toast_time = 0
	game.hud._refresh_visibility()
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.local/ported-preview")
	root.get_texture().get_image().save_png("res://.local/ported-preview/" + label + ".png")
