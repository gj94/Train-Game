extends SceneTree
## Actual default rake and camera, sampled between engine ticks.
var failures := 0
const Data := preload("res://game/joint_video_model_data.gd")

class ClockProbe extends Node:
	var game
	var finished: Callable
	var frames := 0
	var subframes := 0
	var stalls := 0
	var previous_tick := -1
	var previous := Vector3.ZERO
	var minimum := 1.0
	var maximum := 0.0
	var began := 0
	func _process(_delta: float) -> void:
		game.paused = false
		frames += 1
		var tick := Engine.get_physics_frames()
		var point: Vector3 = game.tv.cars[1].global_position
		if frames == 31: began = Time.get_ticks_usec()
		if frames > 30:
			var phase := Engine.get_physics_interpolation_fraction()
			minimum = minf(minimum,phase)
			maximum = maxf(maximum,phase)
			if tick == previous_tick:
				subframes += 1
				if point.distance_to(previous) < .00005: stalls += 1
		previous = point
		previous_tick = tick
		if frames == 210:
			set_process(false)
			print("Live engine interpolation: %d display-only frames, %d stalls; phase %.4f..%.4f" % [subframes,stalls,minimum,maximum])
			print("Probe display rate: %.1f FPS" % (179000000.0 / (Time.get_ticks_usec()-began)))
			if "--render-probe" in OS.get_cmdline_user_args():
				get_viewport().get_texture().get_image().save_png("res://.local/motion-close-up.png")
			finished.call(subframes > 20 and stalls == 0 and maximum-minimum > .5)

func _initialize() -> void: call_deferred("check_motion")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ",label)

func check_motion() -> void:
	change_scene_to_file("res://game/main.tscn")
	await process_frame
	await process_frame
	var game = current_scene
	game.set_process(false)
	game.set_physics_process(false)
	game.cam.set_process(false)
	for audio in game.train_audio.values(): audio.set_process(false)
	var t: Train = game.train
	game.world.place_train(t,"W_E0",460,1)
	game.train_motions[t.id].reset()
	game._render_trains(1)
	game.cam.mode = 0
	game.cam._blend = 1
	game.cam.distance = 3
	game.cam.pivot = game.tv.overview_position()
	game.cam._follow_anchor_valid = false
	game.cam._process(1.0/144)
	game.paused = false
	t.automatic = false
	t.controller = 0
	t.speed = 20
	var camera_error := 0.0
	var visual_steps := []
	var wheel := game.tv.axles[1][0] as Node3D
	var previous_wheel := wheel.rotation.x
	var previous: Vector3 = game.tv.cars[1].global_position
	for tick in 12:
		game._physics_process(1.0/60)
		for phase in [0.0,.25,.5,.75]:
			game._render_trains(phase)
			game.cam._process(1.0/240)
			camera_error = maxf(camera_error,game.cam.pivot.distance_to(game.tv.overview_position()))
			var now: Vector3 = game.tv.cars[1].global_position
			if tick > 0:
				visual_steps.append(now.distance_to(previous))
				check(absf(angle_difference(previous_wheel,wheel.rotation.x)) > .001,"wheel turns on intermediate display frame")
			previous = now
			previous_wheel = wheel.rotation.x
	check(camera_error < .002,"3 m follow camera stays attached to rendered train")
	check(visual_steps.min() > .075 and visual_steps.max() < .09,"body advances smoothly on every 240 Hz display sample")
	check(game.audio.motion == game.tv.motion,"audio and body use the same rendered railway position")
	for axle in game.audio._sched.axles.filter(func(a): return a.car == 1):
		var rendered: Dictionary = game.audio.motion.locate(axle.x)
		var expected: Vector3 = game.world.graph.position(rendered.edge,rendered.s)+Vector3.UP*.9575
		var distances := []
		for physical in game.tv.axles[1]: distances.append(physical.global_position.distance_to(expected))
		check(distances.min() < .025,"rendered axle remains on its scheduled track position")
	game._set_paused(true)
	game._process(1.0/144)
	var stopped: Vector3 = game.tv.cars[1].global_position
	for i in 8: game._process(1.0/144)
	check(game.tv.cars[1].global_position.is_equal_approx(stopped),"paused scene has no interpolation sawtooth")
	check(game.audio.clang_balance_db == 0 and Data.MODEL_ID == "joint-video-contact-v1","approved video strike bank is active")
	check(game.audio._kernels.size() == 28 and absf(game.audio._kernels[1].get_length()-Data.KERNEL_SECONDS) < .0001,"all 14 approved strike pairs are fully imported")
	print("Rendered motion: %d failures; camera error %.6f m; body frame step %.6f..%.6f m" % [failures,camera_error,visual_steps.min(),visual_steps.max()])
	if "--clock-probe" in OS.get_cmdline_user_args():
		Engine.physics_ticks_per_second = 10 # Test-only stress; shipped game stays 60 Hz.
		Engine.max_fps = 144
		game._set_paused(false)
		game.set_process(true)
		game.set_physics_process(true)
		game.cam.set_process(true)
		if "--render-probe" in OS.get_cmdline_user_args():
			game.hud.hide()
			game.cam.follow_point = func(): return game.tv.axles[1][0].global_position - Vector3.UP*.45
			game.cam.pivot = game.cam.follow_point.call()
			game.cam._follow_anchor_valid = false
		var probe := ClockProbe.new()
		probe.game = game
		probe.process_priority = 100
		probe.finished = func(ok):
			check(ok,"real engine interpolates between physics ticks")
			quit(1 if failures else 0)
		root.add_child(probe)
		return
	quit(1 if failures else 0)
