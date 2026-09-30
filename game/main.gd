extends Node3D
## Southern corridor: rendering and controls consume the independent sim.

const FirstLine := preload("res://sim/layouts/first_line.gd")
const Corridor := preload("res://sim/layouts/southern_corridor.gd")
const DispatchPlan := preload("res://sim/dispatch_plan.gd")
const WorldView := preload("res://game/world_view.gd")
const TrainView := preload("res://game/train_view.gd")
const Wap7View := preload("res://game/wap7_train_view.gd")
const LhbView := preload("res://game/lhb_train_view.gd")
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
var wap7_drive := false
var lhb_drive := false
var _dispatch_tick := 0.0


func _ready() -> void:
	wap7_drive = get_tree().get_meta("wap7_drive", "--wap7" in OS.get_cmdline_user_args())
	lhb_drive = get_tree().get_meta("lhb_drive", "--lhb" in OS.get_cmdline_user_args())
	var layout = FirstLine if get_tree().get_meta("small_test_layout", false) else Corridor
	world = layout.build_lhb() if lhb_drive else (layout.build_wap7() if wap7_drive else layout.build_dispatch())
	train = world.trains.T1
	wv = WorldView.new()
	wv.build(world, self)
	for t in world.trains.values():
		var view: RefCounted
		match t.stock_kind:
			"lhb": view = LhbView.new()
			"wap7": view = Wap7View.new()
			_: view = TrainView.new()
		view.build(t, world.graph, self, wv)
		train_views[t.id] = view
	tv = train_views[train.id]
	cam = CameraRig.new()
	cam.cab_transform = tv.cab_transform
	cam.follow_point = tv.overview_position
	if lhb_drive:
		cam.passenger_transform = tv.passenger_transform
	if wap7_drive or lhb_drive:
		cam.distance = 420.0 if lhb_drive else 34.0
		cam.cab_fov = 76.0
		cam.cab_yaw_limit = PI
	add_child(cam)
	cam.make_current()
	for t in world.trains.values():
		var axles: Array = Wap7View.sound_axles() if t.stock_kind == "wap7" else AxleJoint.rake_axles(
			train_views[t.id].cars.size(), TrainView.CAR_LENGTH + TrainView.CAR_GAP,
			TrainView.CAR_LENGTH, TrainView.BOGIE_INSET, TrainView.AXLE_SPACING)
		if t.stock_kind == "lhb":
			axles = LhbView.sound_axles()
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
	dispatcher.scenario_requested.connect(_switch_scenario)
	dispatcher.lhb_requested.connect(_switch_lhb)
	dispatcher.result_message.connect(_report)
	if lhb_drive:
		_enter_cab()
		hud.toast("WAP-7 + LHB · W power / S brake · V passenger · Tab exterior · F1 controls")
	elif wap7_drive:
		_enter_cab()
		hud.toast("WAP-7 30306 · W power / S brake · Tab exterior · C onward routes · F2 MEMU services")
	else:
		hud.toast("Set routes from the dispatch board. F2 drives WAP-7; F3 adds LHB coaches.")


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
		_dispatch_tick += delta
		if dispatcher.auto_dispatch and _dispatch_tick >= .5:
			_dispatch_tick = 0
			DispatchPlan.update(world, dispatcher.hold_arrivals)
		world.step(delta)


func _process(delta: float) -> void:
	for view in train_views.values():
		view.update()
	if lhb_drive and cam.mode == CameraRig.Mode.PASSENGER:
		audio.interior_listener = tv.passenger_audio_position()
	wv.update()
	wv.update_joints(delta)
	for e in world.events:
		if e.seq > _last_event:
			_last_event = e.seq
			hud.log_event(e)
	var ns := world.next_signal(train)
	hud.refresh({
		train_id = train.id,
		stock_kind = train.stock_kind,
		cab_end = train.cab_end,
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
		passenger = tv.passenger_name() if lhb_drive and cam.mode == CameraRig.Mode.PASSENGER else "",
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
				if cam.mode != CameraRig.Mode.OVERVIEW:
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
				if lhb_drive:
					cam.distance = maxf(cam.distance, 420.0)
				cam.set_mode(CameraRig.Mode.OVERVIEW)
				_set_cab_visuals(false)
			KEY_P:
				world.protection = not world.protection
				hud.toast("Train protection " + ("on" if world.protection else "off"))
			KEY_T:
				time_scale = 1 if time_scale >= 4 else time_scale * 2
			KEY_F1:
				hud.toggle_help()
			KEY_F2:
				_switch_scenario()
			KEY_F3:
				_switch_lhb()
			KEY_V:
				if lhb_drive:
					if cam.mode == CameraRig.Mode.PASSENGER:
						_enter_cab()
					else:
						_enter_passenger()
			KEY_PAGEUP, KEY_PAGEDOWN:
				if lhb_drive and cam.mode == CameraRig.Mode.PASSENGER:
					tv.change_passenger_coach(1 if event.physical_keycode == KEY_PAGEDOWN else -1)
					cam._look = Vector2.ZERO
			KEY_LEFT, KEY_RIGHT:
				if lhb_drive and cam.mode == CameraRig.Mode.PASSENGER:
					tv.change_passenger_bay(1 if event.physical_keycode == KEY_RIGHT else -1)
			KEY_HOME:
				if lhb_drive and cam.mode == CameraRig.Mode.PASSENGER:
					tv.passenger_seat = not tv.passenger_seat
					cam._look = Vector2.ZERO
			KEY_B:
				if lhb_drive:
					tv.toggle_berths()
					hud.toast("3A middle berths " + ("lowered for sleeping" if tv.berths_deployed else "folded for seating"))
			KEY_1, KEY_2, KEY_3:
				var idx: int = event.physical_keycode - KEY_1
				if idx < world.stations.size():
					cam.distance = 155.0
					cam.yaw = 0.25 if world.stations[idx].building.z > 0 else PI + 0.25
					cam.jump_to(world.stations[idx].building)
					_set_cab_visuals(false)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if cam.drag_moved < 6.0 and cam.mode == CameraRig.Mode.OVERVIEW:
			_pick(event.position)


func _set_cab_visuals(cab: bool) -> void:
	tv.set_cab_view(cab)
	audio.interior_listener = TrainAudio.DRIVER
	if lhb_drive:
		tv.set_passenger_view(false)
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


func _enter_passenger() -> void:
	# Looking around as a passenger preserves the current driver's controls.
	_set_cab_visuals(false)
	tv.set_passenger_view(true)
	cam.set_mode(CameraRig.Mode.PASSENGER)
	wv.set_labels_visible(false)
	audio.set_interior(true)
	dispatcher.set_open(false)
	hud.toast("PgUp/PgDn coach · ←/→ bay · Home aisle/seat · B middle berths · right-drag look")


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


func _switch_scenario() -> void:
	get_tree().set_meta("wap7_drive", not wap7_drive)
	get_tree().set_meta("lhb_drive", false)
	get_tree().call_deferred("reload_current_scene")


func _switch_lhb() -> void:
	get_tree().set_meta("lhb_drive", not lhb_drive)
	get_tree().set_meta("wap7_drive", false)
	get_tree().call_deferred("reload_current_scene")
