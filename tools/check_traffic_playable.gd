extends SceneTree
const Traffic := preload("res://sim/layouts/traffic_service.gd")
var failures := 0

func _initialize() -> void:
	# Exercise the default launch with a repeatable third departure assignment.
	for value in 120:
		if Traffic.selected_service(value) == "T5":
			set_meta("traffic_seed", value)
			break
	call_deferred("run_check")

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("Traffic integration FAIL: ", label)

func run_check() -> void:
	change_scene_to_file("res://game/main.tscn")
	await process_frame
	await process_frame
	var game = current_scene
	game.set_process(false)
	game.set_physics_process(false)
	game.cam.set_process(false)
	for sound in game.train_audio.values(): sound.set_process(false)
	check(game.traffic_drive and game.train.id == "T5", "random default assignment uses scenario seed")
	check(game.world.trains.size() == 6 and game.train_views.size() == 6 and game.train_audio.size() == 6, "all six services have visuals and independent audio")
	check(game.dispatcher.selected_train == "T5" and game.dispatcher.auto_dispatch, "driver and automatic dispatcher agree on assignment")
	check(game.world.aspect("CPM-E3") == RailWorld.Aspect.RED, "third departure initially waits for actual traffic")
	game._toggle_help()
	check(game.paused and game.hud._body.text.contains("T1, T3") and game.hud._body.text.contains("YOUR BOOKED STOPS"), "help explains both preceding trains and this service's stops")
	if "--screenshots" in OS.get_cmdline_user_args():
		game.cam._blend = 1.0
		game.cam._process(0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.local/traffic-help.png")
	game._close_help()
	game.paused = false
	# The player stays manual with brakes applied while the other trains depart.
	var route_cleared := false
	for i in 1000:
		game._physics_process(.5)
		if game.world.aspect("CPM-E3") != RailWorld.Aspect.RED:
			route_cleared = true
			break
	check(route_cleared and game.world.time > 30, "player route clears automatically after preceding movements")
	check(not game.train.automatic and game.train.speed == 0 and game.train.controller == -1, "routing never takes manual driving controls")
	check(game.world.trains.T1.odometer > 100 and game.world.trains.T3.odometer > 100, "both preceding trains really moved")
	check(game.world.events.is_empty(), "no traffic safety interventions")
	game._render_trains(1)
	for id in Traffic.SERVICES:
		var previous: Train = game.train
		game._select_train(id)
		game._passenger_preset(1)
		game.cam._blend = 1.0
		game.cam._process(0)
		check(game.cam.global_position.distance_to(game.tv.passenger_transform().origin) < .001, "selected service's passenger camera: "+id)
		check(game.audio.train == game.train and game.dispatcher.selected_train == id, "selected service's audio and desk: "+id)
		if previous != game.train: check(previous.automatic, "previous service returns to AI: "+previous.id)
		game._toggle_help()
		check(game.hud._body.text.contains("YOUR SCENARIO · "+id), "briefing follows selected service: "+id)
		game._close_help()
	game.dispatcher.auto_dispatch = false
	game.dispatcher.hold_arrivals = true
	game._toggle_help()
	check(game.hud._body.text.contains("Auto dispatch is OFF") and game.hud._body.text.contains("HOLD MRT is ON"), "briefing explains current dispatcher settings")
	game._close_help()
	game.hud.show_modal("fleet")
	check(game.hud._buttons.get_child(0).text == "New random traffic service", "new assignment accessible from fleet menu")
	print("Traffic integration: %d failures; six mixed services, genuine two-train wait, manual route release, passenger transfers and contextual Help" % failures)
	quit(1 if failures else 0)
