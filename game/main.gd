extends Node3D
## Two-train station meet: rendering and controls consume the independent sim.

const FirstLine := preload("res://sim/layouts/first_line.gd")
const WorldView := preload("res://game/world_view.gd")
const TrainView := preload("res://game/train_view.gd")
const CameraRig := preload("res://game/camera_rig.gd")
const Hud := preload("res://game/hud.gd")
const TrainAudio := preload("res://game/train_audio.gd")
const AxleJoint := preload("res://game/axle_joint.gd")
const Dispatcher := preload("res://game/dispatcher.gd")

const HANDLE_RATE := 0.8   # handle travel per second while W/S held

var world: RailWorld
var train: Train
var wv
var tv
var cam
var hud
var audio
var dispatcher
var train_views := {}
var train_audio := {}
var paused := false
var time_scale := 1
var _last_event := 0


func _ready() -> void:
	world = FirstLine.build_dispatch()
	train = world.trains.T1
	wv = WorldView.new()
	wv.build(world, self)
	for t in world.trains.values():
		var view := TrainView.new()
		view.build(t, world.graph, self, wv)
		train_views[t.id] = view
	tv = train_views[train.id]
	cam = CameraRig.new()
	cam.cab_transform = tv.cab_transform
	cam.follow_point = tv.overview_position
	add_child(cam)
	cam.make_current()
	# Axles of the MEMU as modelled by TrainView (21.3 m bodies, 0.6 m gaps, bogies 3 m in).
	var axles := AxleJoint.rake_axles(tv.cars.size(), TrainView.CAR_LENGTH + TrainView.CAR_GAP,
		TrainView.CAR_LENGTH, TrainView.BOGIE_INSET, 2.5)
	for t in world.trains.values():
		var sound := TrainAudio.new()
		add_child(sound)
		sound.setup(t, world, cam, axles)
		train_audio[t.id] = sound
	audio = train_audio[train.id]
	# Rail-joint markers: yellow bars that flash red whenever an axle hits them (J toggles).
	wv.build_joints(TrainAudio.JOINT_SPACING, TrainAudio.JOINT_OFFSET)
	wv.set_joints_visible(false)
	for sound in train_audio.values():
		sound.joint_hit.connect(func(edge: String, k: int, _cls: int): wv.flash_joint(edge, k))
	hud = Hud.new()
	add_child(hud)
	dispatcher = Dispatcher.new()
	add_child(dispatcher)
	dispatcher.setup(world)
	dispatcher.train_selected.connect(_select_train)
	dispatcher.drive_requested.connect(_enter_cab)
	dispatcher.pause_requested.connect(_toggle_pause)
	dispatcher.restart_requested.connect(func(): get_tree().reload_current_scene())
	dispatcher.result_message.connect(_report)
	hud.toast("Two services are waiting. Set their routes from the dispatch board.")


func _physics_process(delta: float) -> void:
	if paused:
		return
	var dir := 0.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir += 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir -= 1.0
	if dir != 0.0:
		train.automatic = false
		train.controller = clampf(train.controller + dir * HANDLE_RATE * delta, -1.0, 1.0)
	for i in time_scale:
		world.step(delta)


func _process(delta: float) -> void:
	for view in train_views.values():
		view.update()
	wv.update()
	wv.update_joints(delta)
	for e in world.events:
		if e.seq > _last_event:
			_last_event = e.seq
			hud.log_event(e)
	var ns := world.next_signal(train)
	hud.refresh({
		train_id = train.id,
		cars = tv.cars.size(),
		speed = train.speed,
		limit = world.speed_limit_for(train),
		controller = train.controller,
		emergency = train.emergency,
		next_signal = ns,
		next_aspect = world.aspect(ns.id) if not ns.is_empty() else 0,
		buffer = world.distance_to_buffer(train, 600.0),
		protection = world.protection,
		cab = cam.mode == CameraRig.Mode.CAB,
		time_scale = time_scale,
		automatic = train.automatic,
		paused = paused,
		world_clock = world.clock_text(),
		world_day = world.clock_day(),
	})


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_TAB:
				if cam.mode == CameraRig.Mode.CAB:
					cam.set_mode(CameraRig.Mode.OVERVIEW)
					_set_cab_visuals(false)
				else:
					_enter_cab()
			KEY_D:
				dispatcher.toggle()
			KEY_M:
				dispatcher.toggle_timetable()
			KEY_A:
				dispatcher.toggle_driver()
			KEY_ESCAPE:
				_toggle_pause()
			KEY_X:
				train.automatic = false
				train.controller = 0.0
			KEY_H:
				audio.horn()
			KEY_BRACKETLEFT, KEY_BRACKETRIGHT:
				var db: float = audio.adjust_track_level(-2.0 if event.physical_keycode == KEY_BRACKETLEFT else 2.0)
				hud.toast("Track sound %+.0f dB" % db)
			KEY_COMMA, KEY_PERIOD:
				var bal: float = audio.adjust_clang_balance(-1.0 if event.physical_keycode == KEY_COMMA else 1.0)
				hud.toast("Clang (2nd wheel) vs cling (1st wheel): %+.0f dB" % bal)
			KEY_SPACE:
				if train.emergency:
					_report(world.release_emergency(train.id), "Emergency brake released")
				else:
					train.emergency = true
			KEY_C:
				var next := world.next_signal(train)
				if not next.is_empty():
					dispatcher.set_open(true)
					dispatcher.select_signal(next.id, true)
			KEY_R:
				var res := world.reverse_train(train.id)
				if res.ok:
					audio.reset_positions()
					train.destination = "Kadalur" if train.path[0].dir > 0 else "Chennapuram"
				_report(res, "Changed ends — you are now driving from the other cab")
			KEY_J:
				wv.set_joints_visible(not wv.joints_visible())
				hud.toast("Rail-joint markers " + ("on" if wv.joints_visible() else "off"))
			KEY_F:
				cam.follow = true
				cam.set_mode(CameraRig.Mode.OVERVIEW)
				_set_cab_visuals(false)
			KEY_P:
				world.protection = not world.protection
				hud.toast("Train protection " + ("on" if world.protection else "off"))
			KEY_T:
				time_scale = 1 if time_scale >= 4 else time_scale * 2
			KEY_F1:
				hud.toggle_help()
			KEY_1, KEY_2, KEY_3:
				var idx: int = event.physical_keycode - KEY_1
				if idx < world.stations.size():
					cam.jump_to(world.stations[idx].building)
					cam.distance = 180.0
					_set_cab_visuals(false)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if cam.drag_moved < 6.0 and cam.mode == CameraRig.Mode.OVERVIEW:
			_pick(event.position)


func _set_cab_visuals(cab: bool) -> void:
	tv.set_cab_view(cab)
	wv.set_labels_visible(not cab)
	for sound in train_audio.values():
		if sound != audio:
			sound.set_interior(false)
	audio.set_interior(cab)
	dispatcher.set_open(not cab)


func _enter_cab() -> void:
	train.automatic = false
	train.controller = 0.0
	cam.set_mode(CameraRig.Mode.CAB)
	_set_cab_visuals(true)


func _toggle_pause() -> void:
	paused = not paused
	for sound in train_audio.values():
		for player in sound.get_children():
			if player is AudioStreamPlayer:
				player.stream_paused = paused


func _select_train(id: String) -> void:
	if id == train.id:
		return
	tv.set_cab_view(false)
	train = world.trains[id]
	tv = train_views[id]
	audio = train_audio[id]
	cam.cab_transform = tv.cab_transform
	cam.follow_point = tv.overview_position
	cam.follow = true
	dispatcher.selected_train = id
	_set_cab_visuals(cam.mode == CameraRig.Mode.CAB)
	if cam.mode == CameraRig.Mode.CAB:
		train.automatic = false


func _pick(screen_pos: Vector2) -> void:
	var from: Vector3 = cam.project_ray_origin(screen_pos)
	var to: Vector3 = from + cam.project_ray_normal(screen_pos) * 6000.0
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	if hit.is_empty() or not hit.collider.has_meta("pick"):
		return
	var info: Dictionary = hit.collider.get_meta("pick")
	if info.kind == "signal":
		dispatcher.set_open(true)
		dispatcher.select_signal(info.id, true)
	elif info.kind == "switch":
		_report(world.throw_switch(info.id), "Switch %s thrown" % info.id)


func _report(result: Dictionary, ok_text: String) -> void:
	hud.toast(ok_text if result.ok else result.reason)
