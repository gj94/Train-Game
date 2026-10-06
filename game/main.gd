extends Node3D
## Southern corridor: rendering and controls consume the independent sim.

const FirstLine := preload("res://sim/layouts/first_line.gd")
const Corridor := preload("res://sim/layouts/southern_corridor.gd")
const DispatchPlan := preload("res://sim/dispatch_plan.gd")
const WorldView := preload("res://game/world_view.gd")
const TrainView := preload("res://game/train_view.gd")
const TrainMotion := preload("res://game/train_motion.gd")
const Wap7View := preload("res://game/wap7_train_view.gd")
const LhbView := preload("res://game/lhb_train_view.gd")
const PortedView := preload("res://game/ported_train_view.gd")
const PortedStock := preload("res://sim/stock/ported_stock.gd")
const PortedFleet := preload("res://sim/layouts/ported_fleet.gd")
const Traffic := preload("res://sim/layouts/traffic_service.gd")
const CameraRig := preload("res://game/camera_rig.gd")
const Hud := preload("res://game/hud.gd")
const ScenarioBrief := preload("res://game/scenario_brief.gd")
const TrainAudio := preload("res://game/platform_audio.gd")
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
var train_motions := {}
var train_audio := {}
var paused := false
var time_scale := 1
var _last_event := 0
var wap7_drive := false
var lhb_drive := false
var imported_fleet := ""
var traffic_drive := false
var _dispatch_tick := 0.0
var labels_enabled := false
var _desk_before_cab := false
var _desk_before_clean := false
var _paused_before_help := false
var _pending_action := ""
var _interior_view := false


func _ready() -> void:
	# Custom railway interpolation needs a clock without physics-jitter correction.
	Engine.physics_jitter_fix = 0.0
	imported_fleet = get_tree().get_meta("imported_fleet", "")
	if not get_tree().has_meta("imported_fleet"):
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--fleet=") and arg.trim_prefix("--fleet=") in PortedStock.CHOICES:
				imported_fleet = arg.trim_prefix("--fleet=")
	wap7_drive = get_tree().get_meta("wap7_drive", "--wap7" in OS.get_cmdline_user_args())
	lhb_drive = get_tree().get_meta("lhb_drive", "--lhb" in OS.get_cmdline_user_args())
	var has_saved_scenario := get_tree().has_meta("imported_fleet") or get_tree().has_meta("wap7_drive") or get_tree().has_meta("lhb_drive")
	# Fresh launches assign one of six services; explicit scenarios still win.
	traffic_drive = get_tree().get_meta("traffic_drive", not has_saved_scenario and "--memu" not in OS.get_cmdline_user_args() and not get_tree().get_meta("small_test_layout", false))
	if not imported_fleet.is_empty() or wap7_drive or lhb_drive:
		traffic_drive = false
	if not imported_fleet.is_empty():
		wap7_drive = false
		lhb_drive = false
	var layout = FirstLine if get_tree().get_meta("small_test_layout", false) else Corridor
	if traffic_drive:
		world = Traffic.build()
	elif not imported_fleet.is_empty():
		world = PortedFleet.build(imported_fleet)
	else:
		world = layout.build_lhb() if lhb_drive else (layout.build_wap7() if wap7_drive else layout.build_dispatch())
	train = world.trains.T1
	if traffic_drive:
		var seed_value: int = get_tree().get_meta("traffic_seed", randi())
		get_tree().set_meta("traffic_seed", seed_value)
		get_tree().set_meta("traffic_drive", true)
		train = world.trains[Traffic.selected_service(seed_value)]
	wv = WorldView.new()
	wv.build(world, self)
	for t in world.trains.values():
		var view: RefCounted
		match t.stock_kind:
			"lhb": view = LhbView.new()
			"wap7": view = Wap7View.new()
			_: view = TrainView.new()
		if t.stock_kind.begins_with("ported:"):
			view = PortedView.new()
		var motion := TrainMotion.new(t, world.graph)
		train_motions[t.id] = motion
		view.motion = motion
		view.build(t, world.graph, self, wv)
		train_views[t.id] = view
	tv = train_views[train.id]
	cam = CameraRig.new()
	cam.cab_transform = tv.cab_transform
	cam.follow_point = tv.overview_position
	if _has_passengers():
		cam.passenger_transform = tv.passenger_transform
	if wap7_drive or lhb_drive:
		cam.distance = 420.0 if lhb_drive else 34.0
		cam.cab_fov = 76.0
		cam.cab_yaw_limit = PI
	if train.stock_kind.begins_with("ported:"):
		cam.distance = maxf(38.0, train.length * .85)
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
		elif t.stock_kind.begins_with("ported:"):
			axles = train_views[t.id].sound_axles()
		var sound := TrainAudio.new()
		add_child(sound)
		sound.motion = train_motions[t.id]
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
	hud.action_requested.connect(_ui_action)
	dispatcher = Dispatcher.new()
	add_child(dispatcher)
	dispatcher.selected_train = train.id
	dispatcher.auto_dispatch = traffic_drive
	dispatcher.setup(world)
	dispatcher.train_selected.connect(_select_train)
	dispatcher.drive_requested.connect(_enter_cab)
	dispatcher.pause_requested.connect(_toggle_pause)
	dispatcher.restart_requested.connect(func(): _request_action("restart"))
	dispatcher.scenario_requested.connect(func(): _request_action("wap7"))
	dispatcher.lhb_requested.connect(func(): _request_action("lhb"))
	dispatcher.result_message.connect(_report)
	dispatcher.set_open(false)
	wv.set_labels_visible(false)
	# Window close follows the same in-game confirmation as Quit.
	get_tree().auto_accept_quit = false
	if traffic_drive:
		_enter_cab()
		train.controller = -1.0
		DispatchPlan.update(world, false, train.id)
		hud.toast("YOUR SERVICE: " + train.id + " · " + train.service_name + " · F1 scenario briefing · A AI driver")
	elif not imported_fleet.is_empty():
		_enter_cab()
		hud.toast(PortedStock.LABELS[imported_fleet] + " · F9 fleet · Tab exterior · V passengers · F1 controls")
	elif lhb_drive:
		_enter_cab()
		hud.toast("WAP-7 + LHB · W power / S brake · V passenger · Tab exterior · F1 controls")
	elif wap7_drive:
		_enter_cab()
		hud.toast("WAP-7 30306 · W power / S brake · Tab exterior · C onward routes · F2 MEMU services")
	else:
		hud.toast("D opens dispatch · AUTO DISPATCH runs services · Tab takes the cab · F1 controls")


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
	for motion in train_motions.values(): motion.begin_tick()
	for i in time_scale:
		_dispatch_tick += delta
		if dispatcher.auto_dispatch and _dispatch_tick >= .5:
			_dispatch_tick = 0
			DispatchPlan.update(world, dispatcher.hold_arrivals, train.id if traffic_drive else "")
		world.step(delta)
	for motion in train_motions.values(): motion.end_tick()


func _render_trains(fraction: float) -> void:
	for id in train_views:
		train_motions[id].sample(fraction)
		train_views[id].update()


func _process(delta: float) -> void:
	_render_trains(1.0 if paused else Engine.get_physics_interpolation_fraction())
	for sound in train_audio.values(): sound.listener_owner = audio
	if _has_passengers() and cam.mode == CameraRig.Mode.PASSENGER:
		audio.interior_listener = tv.passenger_audio_position()
	elif train.stock_kind.begins_with("ported:") and cam.mode == CameraRig.Mode.CAB:
		audio.interior_listener = tv.interior_audio_position()
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
		passenger = tv.passenger_name() if _has_passengers() and cam.mode == CameraRig.Mode.PASSENGER else "",
		time_scale = time_scale,
		automatic = train.automatic,
		paused = paused,
		world_clock = world.clock_text(),
		world_day = world.clock_day(),
	})


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Modal input never reaches train controls; the clock and held-key input pause too.
		match event.physical_keycode:
			KEY_ESCAPE:
				if hud.modal == "help": _close_help()
				elif hud.modal == "confirm": _cancel_action()
				elif hud.modal == "fleet": hud.show_modal("pause", labels_enabled)
				else: _toggle_pause()
				return
			KEY_F1:
				if hud.modal != "confirm": _toggle_help()
				return
			KEY_F11:
				_toggle_fullscreen()
				return
		if hud.modal == "pause":
			match event.physical_keycode:
				KEY_F2: _request_action("wap7")
				KEY_F3: _request_action("lhb")
				KEY_F9: _ui_action("fleet")
				KEY_F4: _ui_action("clean")
				KEY_F6: _ui_action("labels")
			return
		if hud.modal != "":
			return
		match event.physical_keycode:
			KEY_TAB:
				if cam.mode != CameraRig.Mode.OVERVIEW:
					cam.set_mode(CameraRig.Mode.OVERVIEW)
					_set_cab_visuals(false)
				else:
					_enter_cab()
			KEY_D:
				_restore_ui()
				dispatcher.toggle()
			KEY_M:
				_restore_ui()
				dispatcher.toggle_timetable()
			KEY_A:
				dispatcher.toggle_driver()
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
				_restore_ui()
				var next := world.next_signal(train)
				if not next.is_empty():
					dispatcher.set_open(true)
					dispatcher.select_signal(next.id, true)
			KEY_R:
				var res := world.reverse_train(train.id)
				if res.ok:
					audio.reset_positions()
					if train.stock_kind.begins_with("ported:"):
						audio.set_axles(tv.sound_axles())
						tv.update()
						tv.set_cab_view(cam.mode == CameraRig.Mode.CAB)
					train.destination = "Kadalur" if train.path[0].dir > 0 else "Chennapuram"
				_report(res, "Changed ends — you are now driving from the other cab")
			KEY_J:
				wv.set_joints_visible(not wv.joints_visible())
				hud.toast("Rail-joint markers " + ("on" if wv.joints_visible() else "off"))
			KEY_F:
				cam.follow = true
				if lhb_drive:
					cam.distance = maxf(cam.distance, 420.0)
				elif train.stock_kind.begins_with("ported:"):
					cam.distance = maxf(cam.distance, train.length * .85)
				cam.set_mode(CameraRig.Mode.OVERVIEW)
				_set_cab_visuals(false)
			KEY_P:
				world.protection = not world.protection
				hud.toast("Train protection " + ("on" if world.protection else "off"))
			KEY_T:
				time_scale = 1 if time_scale >= 4 else time_scale * 2
			KEY_F2:
				_request_action("wap7")
			KEY_F3:
				_request_action("lhb")
			KEY_F4:
				_toggle_clean()
			KEY_F6:
				_toggle_labels()
			KEY_F8:
				_restore_ui()
				hud.toggle_history()
			KEY_F9:
				_ui_action("fleet")
			KEY_V:
				if _has_passengers():
					if cam.mode == CameraRig.Mode.PASSENGER:
						_enter_cab()
					else:
						_enter_passenger()
			KEY_PAGEUP, KEY_PAGEDOWN:
				if _has_passengers() and cam.mode == CameraRig.Mode.PASSENGER:
					tv.change_passenger_coach(1 if event.physical_keycode == KEY_PAGEDOWN else -1)
					cam._look = Vector2.ZERO
			KEY_LEFT, KEY_RIGHT:
				if _has_passengers() and cam.mode == CameraRig.Mode.PASSENGER:
					tv.change_passenger_bay(1 if event.physical_keycode == KEY_RIGHT else -1)
			KEY_HOME:
				if _has_passengers() and cam.mode == CameraRig.Mode.PASSENGER:
					tv.passenger_seat = not tv.passenger_seat
					cam._look = Vector2.ZERO
			KEY_B:
				if lhb_drive:
					tv.toggle_berths()
					hud.toast("3A middle berths " + ("lowered for sleeping" if tv.berths_deployed else "folded for seating"))
			KEY_1, KEY_2, KEY_3:
				var idx: int = event.physical_keycode - KEY_1
				if _has_passengers() and (cam.mode == CameraRig.Mode.PASSENGER or event.alt_pressed):
					_passenger_preset(idx)
				elif idx < world.stations.size():
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
	if _has_passengers():
		tv.set_passenger_view(false)
	wv.set_labels_visible(labels_enabled and not cab and not hud.clean_view)
	for sound in train_audio.values():
		if sound != audio:
			sound.set_interior(false)
	audio.set_interior(cab)
	if cab:
		dispatcher.set_open(false)
	elif _interior_view and cam.mode == CameraRig.Mode.OVERVIEW and not hud.clean_view:
		dispatcher.set_open(_desk_before_cab)
	_interior_view = cab


func _enter_cab() -> void:
	if cam.mode == CameraRig.Mode.OVERVIEW:
		_desk_before_cab = dispatcher._root.visible
	train.automatic = false
	train.controller = 0.0
	cam.set_mode(CameraRig.Mode.CAB)
	_set_cab_visuals(true)


func _passenger_preset(index: int) -> void:
	if not _has_passengers():
		hud.toast("Choose a passenger formation with F9 first")
		return
	var eligible: Array = tv.passenger_coaches()
	if eligible.is_empty(): return
	var selected: int = eligible[0 if index==0 else (eligible.size()-1 if index==2 else (eligible.size()-1)/2)]
	tv.passenger_coach = selected
	tv.passenger_bay = 9 if lhb_drive else 0
	tv.passenger_seat = false
	cam._look = Vector2.ZERO
	_enter_passenger()
	audio.reset_positions()
	hud.toast(["FIRST", "MIDDLE", "LAST"][index] + " PASSENGER COACH · " + tv.passenger_name() + " · 1 / 2 / 3 change view")


func _enter_passenger() -> void:
	# Looking around as a passenger preserves the current driver's controls.
	if cam.mode == CameraRig.Mode.OVERVIEW:
		_desk_before_cab = dispatcher._root.visible
	_set_cab_visuals(false)
	tv.set_passenger_view(true)
	cam.set_mode(CameraRig.Mode.PASSENGER)
	_interior_view = true
	wv.set_labels_visible(false)
	audio.set_interior(true)
	dispatcher.set_open(false)
	hud.toast("1 first · 2 middle · 3 last coach · PgUp/PgDn coach · ←/→ position · Home aisle/seat" + (" · B middle berths" if lhb_drive else ""))


func _toggle_pause() -> void:
	_set_paused(not paused)
	hud.show_modal("pause" if paused else "", labels_enabled)


func _set_paused(value: bool) -> void:
	paused = value
	cam.set_process_unhandled_input(not value)
	cam._dragging = 0
	for sound in train_audio.values():
		sound.set_paused(paused)


func _ui_action(action: String) -> void:
	if action.begins_with("fleet:"):
		_request_action(action)
		return
	if action.begins_with("pax:"):
		_set_paused(false)
		hud.show_modal("")
		_passenger_preset(int(action.get_slice(":",1)))
		return
	match action:
		"passengers":
			_set_paused(true)
			hud.show_modal("passengers")
		"fleet":
			_set_paused(true)
			hud.show_modal("fleet")
		"fleet_back": hud.show_modal("pause", labels_enabled)
		"dispatch":
			_restore_ui()
			dispatcher.toggle()
		"pause", "resume": _toggle_pause()
		"help": _toggle_help()
		"close_help": _close_help()
		"clean":
			_toggle_clean()
			if paused: _toggle_pause()
		"labels":
			_toggle_labels()
			hud.show_modal("pause", labels_enabled)
		"fullscreen": _toggle_fullscreen()
		"restart", "wap7", "lhb", "traffic", "quit": _request_action(action)
		"cancel": _cancel_action()
		"confirm": _confirm_action()


func _toggle_help() -> void:
	if hud.modal == "help":
		_close_help()
		return
	_paused_before_help = paused
	_set_paused(true)
	hud.scenario_brief = ScenarioBrief.describe(world, train, traffic_drive, dispatcher.auto_dispatch, dispatcher.hold_arrivals)
	hud.show_modal("help")


func _close_help() -> void:
	_set_paused(_paused_before_help)
	hud.show_modal("pause" if paused else "", labels_enabled)


func _request_action(action: String) -> void:
	_pending_action = action
	_set_paused(true)
	var descriptions := {"restart": "Restart the current services from the beginning.",
		"wap7": "Start the MEMU services." if wap7_drive else "Start the WAP-7 light engine.",
		"lhb": "Start the MEMU services." if lhb_drive else "Start the WAP-7 with 20 LHB coaches.",
		"traffic": "Start six mixed passenger services and assign you a random train.",
		"quit": "Quit Train Game and return to the desktop."}
	var description: String = descriptions.get(action, "")
	if action.begins_with("fleet:"):
		description = "Start " + PortedStock.LABELS[action.trim_prefix("fleet:")] + "."
	hud.show_modal("confirm", labels_enabled, description)


func _cancel_action() -> void:
	_pending_action = ""
	hud.show_modal("pause", labels_enabled)


func _confirm_action() -> void:
	var action := _pending_action
	_pending_action = ""
	if action.begins_with("fleet:"):
		get_tree().set_meta("traffic_drive", false)
		get_tree().set_meta("imported_fleet", action.trim_prefix("fleet:"))
		get_tree().set_meta("wap7_drive", false)
		get_tree().set_meta("lhb_drive", false)
		get_tree().call_deferred("reload_current_scene")
		return
	match action:
		"traffic":
			get_tree().set_meta("traffic_drive", true)
			get_tree().set_meta("traffic_seed", randi())
			get_tree().set_meta("imported_fleet", "")
			get_tree().set_meta("wap7_drive", false)
			get_tree().set_meta("lhb_drive", false)
			get_tree().call_deferred("reload_current_scene")
		"restart": get_tree().reload_current_scene()
		"wap7": _switch_scenario()
		"lhb": _switch_lhb()
		"quit": get_tree().quit()


func _toggle_labels() -> void:
	labels_enabled = not labels_enabled
	wv.set_labels_visible(labels_enabled and cam.mode == CameraRig.Mode.OVERVIEW and not hud.clean_view)
	hud.toast("Track labels " + ("on" if labels_enabled else "off"))


func _toggle_clean() -> void:
	if not hud.clean_view:
		_desk_before_clean = dispatcher._root.visible
		dispatcher.set_open(false)
		hud.set_clean(true)
	else:
		hud.set_clean(false)
		dispatcher.set_open(_desk_before_clean and cam.mode == CameraRig.Mode.OVERVIEW)
	wv.set_labels_visible(labels_enabled and cam.mode == CameraRig.Mode.OVERVIEW and not hud.clean_view)


func _restore_ui() -> void:
	if hud.clean_view:
		hud.set_clean(false)
		wv.set_labels_visible(labels_enabled and cam.mode == CameraRig.Mode.OVERVIEW)


func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)


func _notification(what: int) -> void:
	if hud == null:
		return
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_request_action("quit")
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and not paused:
		# Alt-tab cannot leave a manually driven train accelerating unattended.
		_set_paused(true)
		hud.show_modal("pause", labels_enabled)


func _select_train(id: String) -> void:
	if id == train.id:
		return
	tv.set_cab_view(false)
	if _has_passengers(): tv.set_passenger_view(false)
	if traffic_drive and not train.service_complete: train.automatic = true
	train = world.trains[id]
	tv = train_views[id]
	audio = train_audio[id]
	cam.cab_transform = tv.cab_transform
	cam.follow_point = tv.overview_position
	cam.follow = true
	cam.passenger_transform = tv.passenger_transform if _has_passengers() else Callable()
	if train.stock_kind.begins_with("ported:"):
		cam.distance = maxf(38.0, train.length * .85)
		cam.cab_fov = 76.0
		cam.cab_yaw_limit = PI
	dispatcher.selected_train = id
	_set_cab_visuals(cam.mode == CameraRig.Mode.CAB)
	if cam.mode == CameraRig.Mode.CAB:
		train.automatic = false
	elif cam.mode == CameraRig.Mode.PASSENGER:
		if _has_passengers(): _enter_passenger()
		else: _enter_cab()
	for sound in train_audio.values():
		sound.listener_owner = audio
		sound.reset_positions()


func _pick(screen_pos: Vector2) -> void:
	var from: Vector3 = cam.project_ray_origin(screen_pos)
	var to: Vector3 = from + cam.project_ray_normal(screen_pos) * 6000.0
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	if hit.is_empty() or not hit.collider.has_meta("pick"):
		return
	var info: Dictionary = hit.collider.get_meta("pick")
	if info.kind == "signal":
		_restore_ui()
		dispatcher.set_open(true)
		dispatcher.select_signal(info.id, true)
	elif info.kind == "switch":
		_report(world.throw_switch(info.id), "Switch %s thrown" % info.id)


func _report(result: Dictionary, ok_text: String) -> void:
	hud.toast(ok_text if result.ok else result.reason)


func _switch_scenario() -> void:
	get_tree().set_meta("traffic_drive", false)
	get_tree().set_meta("imported_fleet", "")
	get_tree().set_meta("wap7_drive", not wap7_drive)
	get_tree().set_meta("lhb_drive", false)
	get_tree().call_deferred("reload_current_scene")


func _switch_lhb() -> void:
	get_tree().set_meta("traffic_drive", false)
	get_tree().set_meta("imported_fleet", "")
	get_tree().set_meta("lhb_drive", not lhb_drive)
	get_tree().set_meta("wap7_drive", false)
	get_tree().call_deferred("reload_current_scene")


func _has_passengers() -> bool:
	return train != null and train.stock_kind in ["lhb", "ported:icf", "ported:lhb", "ported:vb8", "ported:vb16"]
