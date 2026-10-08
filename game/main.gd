extends Node3D
## Southern corridor: rendering and controls consume the independent sim.

const FirstLine := preload("res://sim/layouts/first_line.gd")
const Corridor := preload("res://sim/layouts/southern_corridor.gd")
const DispatchPlan := preload("res://sim/dispatch_plan.gd")
const WorldView := preload("res://game/world_view.gd")
const TrainMotion := preload("res://game/train_motion.gd")
const PortedView := preload("res://game/ported_train_view.gd")
const PortedStock := preload("res://sim/stock/ported_stock.gd")
const PortedFleet := preload("res://sim/layouts/ported_fleet.gd")
const Traffic := preload("res://sim/layouts/traffic_service.gd")
const CameraRig := preload("res://game/camera_rig.gd")
const Hud := preload("res://game/hud.gd")
const ScenarioBrief := preload("res://game/scenario_brief.gd")
const ControllerInput := preload("res://game/controller_input.gd")
const TrainAudio := preload("res://game/platform_audio.gd")
const Dispatcher := preload("res://game/dispatch_desk.gd")

const ServicePack := preload("res://sim/service_pack.gd")
const ServiceEditor := preload("res://game/service_editor.gd")
const Kerala := preload("res://sim/layouts/kerala_coast.gd")
var geographic_drive := false
var geographic_listener
var _geographic_loading := false
var service_editor
var authored_pack := {}
var _service_error := ""

const HANDLE_RATE := 0.8   # handle travel per second while W/S held

var world: RailWorld
var train: Train
var wv
var tv
var cam
var hud
var audio
var dispatcher
var controller
var walker
var _drive_keys_armed := true
var performance_overlay
var train_views := {}
var train_motions := {}
var train_audio := {}
var traffic_presentation
var _journey_snapshot := {}
var _journey_refresh := 0.0
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
var _paused_before_progress := false
var _pending_action := ""
var _interior_view := false


func _ready() -> void:
	# Custom railway interpolation needs a clock without physics-jitter correction.
	Engine.physics_jitter_fix = 0.0
	AudioServer.playback_speed_scale=1.0
	var default_route:="kerala_coast"
	if get_tree().get_meta("small_test_layout",false) or not str(get_tree().get_meta("imported_fleet","")).is_empty() or Array(OS.get_cmdline_user_args()).any(func(a):return a.begins_with("--fleet=") or a in ["--wap7","--lhb","--memu"]):default_route="southern_corridor"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--route="):default_route=argument.trim_prefix("--route=")
	geographic_drive = get_tree().get_meta("route",default_route)=="kerala_coast"
	if geographic_drive: get_tree().set_meta("route","kerala_coast")
	imported_fleet = get_tree().get_meta("imported_fleet", "")
	if not get_tree().has_meta("imported_fleet"):
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--fleet=") and arg.trim_prefix("--fleet=") in PortedStock.CHOICES:
				imported_fleet = arg.trim_prefix("--fleet=")
			elif arg == "--wap7": imported_fleet = "icf"
			elif arg == "--lhb": imported_fleet = "lhb"
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
	var authored = get_tree().get_meta("service_pack", {})
	if not authored.is_empty():
		var expected_layout := "kerala_coast" if geographic_drive else ("first_line" if get_tree().get_meta("small_test_layout",false) else "southern_corridor")
		var result := ServicePack.build(authored, expected_layout)
		if result.ok:
			authored_pack = result.data
			world = result.world
			traffic_drive = true
			imported_fleet = ""
			wap7_drive = false
			lhb_drive = false
		else:
			_service_error = result.reason
			get_tree().remove_meta("service_pack")
	if not authored_pack.is_empty():
		pass
	elif geographic_drive:
		world = Kerala.build_traffic()
		traffic_drive = true
		imported_fleet = ""
		wap7_drive = false
		lhb_drive = false
	elif traffic_drive:
		world = Traffic.build()
	elif not imported_fleet.is_empty():
		world = PortedFleet.build(imported_fleet)
	else:
		world = layout.build_lhb() if lhb_drive else (layout.build_wap7() if wap7_drive else layout.build_dispatch())
	for service in world.trains.values():
		if not service.stock_kind.begins_with("ported:"):
			PortedStock.configure(service,"lhb")
			world.place_train(service,service.path[0].edge,service.head_s,service.path[0].dir)
	train = world.trains.values()[0]
	if not authored_pack.is_empty():
		var chosen: String = get_tree().get_meta("player_service",train.id)
		train = world.trains.get(chosen,train)
	elif traffic_drive:
		var seed_value: int = get_tree().get_meta("traffic_seed", 0 if geographic_drive else randi())
		get_tree().set_meta("traffic_seed", seed_value)
		get_tree().set_meta("traffic_drive", true)
		train = world.trains[world.trains.keys()[posmod(seed_value,world.trains.size())]] if geographic_drive else world.trains[Traffic.selected_service(seed_value)]
	wv = preload("res://game/geographic_world.gd").new() if geographic_drive else WorldView.new()
	if geographic_drive: wv.selected_train = train.id
	wv.build(world, self)
	traffic_presentation=preload("res://game/traffic_presentation.gd").new()
	traffic_presentation.game=self
	for t in world.trains.values():
		var motion := TrainMotion.new(t, world.graph)
		if geographic_drive: motion.coordinate_origin = wv.coordinate_origin
		train_motions[t.id] = motion
		if not geographic_drive or t.id==train.id: traffic_presentation.ensure_view(t.id)
	tv = train_views[train.id]
	cam = CameraRig.new()
	cam.cab_transform = tv.cab_transform
	cam.head_out_transform = tv.head_out_transform
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
	if geographic_drive:
		geographic_listener = preload("res://game/geographic_audio_listener.gd").new()
		add_child(geographic_listener)
		geographic_listener.source_camera = cam
		geographic_listener.coordinate_origin = wv.coordinate_origin
		geographic_listener.sync(cam,wv.coordinate_origin)
		cam.far = 12000.0
	for id in train_views: traffic_presentation.ensure_audio(id)
	audio = train_audio[train.id]
	# Rail-joint markers: yellow bars that flash red whenever an axle hits them (J toggles).
	wv.build_joints(TrainAudio.JOINT_SPACING, TrainAudio.JOINT_OFFSET)
	wv.set_joints_visible(false)

	hud = Hud.new()
	add_child(hud)
	hud.action_requested.connect(_ui_action)
	dispatcher = Dispatcher.new()
	add_child(dispatcher)
	dispatcher.selected_train = train.id
	dispatcher.auto_dispatch = traffic_drive
	dispatcher.setup(world)
	dispatcher.services_requested.connect(_open_services)
	dispatcher.train_selected.connect(_select_train)
	dispatcher.view_train_requested.connect(_view_train_only)
	dispatcher.service_deleted.connect(_on_service_deleted)
	dispatcher.open_changed.connect(func(value): hud.set_desk_open(value))
	world.dispatcher().manual_service=train.id if traffic_drive else ""
	dispatcher.station_view_requested.connect(_visit_station)
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
	walker=preload("res://game/train_walk.gd").new()
	walker.game=self
	add_child(walker)
	cam.walking_transform=walker.camera_transform
	controller = ControllerInput.new()
	controller.game = self
	add_child(controller)
	performance_overlay=preload("res://game/performance_overlay.gd").new()
	performance_overlay.game=self
	add_child(performance_overlay)
	if not _service_error.is_empty(): hud.toast("Service file could not start: "+_service_error,true)


func _physics_process(delta: float) -> void:
	if paused or (geographic_drive and wv.loading):
		return
	var dir := 0.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir += 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir -= 1.0
	if not _drive_keys_armed:
		if not Input.is_physical_key_pressed(KEY_W) and not Input.is_physical_key_pressed(KEY_S) and not Input.is_physical_key_pressed(KEY_UP) and not Input.is_physical_key_pressed(KEY_DOWN): _drive_keys_armed=true
		dir=0.0
	if walker!=null and walker.active: dir=0.0
	var pad_target: float=controller.drive_handle(train.controller,HANDLE_RATE*delta) if controller!=null else train.controller
	if dispatcher._root.visible or (walker!=null and walker.active): pad_target=train.controller
	var pad_intent: float=controller.drive_input() if controller!=null else 0.0
	if dispatcher._root.visible or (walker!=null and walker.active): dir=0.0;pad_intent=0.0
	if dir!=0.0 or pad_intent!=0.0:
		var key_target:=clampf(train.controller+dir*HANDLE_RATE*delta,-1,1)
		train.automatic=false
		# The strongest brake request wins across keyboard and controller.
		train.controller=minf(key_target,pad_target) if dir<0 or pad_target<train.controller else maxf(key_target,pad_target)
	for motion in train_motions.values(): motion.begin_tick()
	var remaining:=delta*time_scale
	while remaining>.000001:
		var slice:=minf(remaining,.05)
		remaining-=slice
		world.step(slice) # The simulation owns dispatch timing, even with the desk closed.
	for motion in train_motions.values(): motion.end_tick()


func _geographic_frame() -> void:
	var absolute: Vector3 = cam.global_position+wv.coordinate_origin
	if cam.global_position.length_squared()>1500.0*1500.0:
		var origin := Vector3(floorf(absolute.x/1024)*1024,0,floorf(absolute.z/1024)*1024)
		var shift: Vector3 = origin-wv.coordinate_origin
		wv.rebase(origin)
		cam.shift_origin(shift)
		for motion in train_motions.values(): motion.coordinate_origin=origin
	geographic_listener.coordinate_origin=wv.coordinate_origin
	if wv.loading!=_geographic_loading:
		_geographic_loading=wv.loading
		for sound in train_audio.values(): sound.set_paused(paused or _geographic_loading)


func _render_trains(fraction: float,ride_delta: float=0.0) -> void:
	for id in train_views:
		train_motions[id].sample(fraction)
		if geographic_drive and cam!=null:
			var nearby: bool=id==train.id or traffic_presentation.distance_to(id)<2200.0
			for car in train_views[id].cars: car.visible=nearby
			if train_audio.has(id):
				var quiet: bool=paused or wv.loading or not nearby
				if train_audio[id]._paused!=quiet: train_audio[id].set_paused(quiet)
			if not nearby: continue
		var view=train_views[id]
		if "ride" in view and view.ride!=null and train_audio.has(id):
			view.ride.update(ride_delta,train_audio[id].layout)
		view.update()


func _process(delta: float) -> void:
	if geographic_drive: _geographic_frame()
	traffic_presentation.update(delta)
	_render_trains(1.0 if paused else Engine.get_physics_interpolation_fraction(),0.0 if paused or _geographic_loading else delta*time_scale)
	if walker!=null: walker.update(delta)
	cam.set_meta("passenger_interior",walker!=null and walker.passenger_interior())
	for sound in train_audio.values(): sound.listener_owner = audio
	if walker!=null and walker.active and not walker.platform.outside:
		audio.interior_listener=walker.audio_position()
	elif _has_passengers() and cam.mode == CameraRig.Mode.PASSENGER:
		audio.interior_listener = tv.passenger_audio_position()
	elif train.stock_kind.begins_with("ported:") and cam.mode == CameraRig.Mode.CAB:
		audio.interior_listener = tv.interior_audio_position()
	wv.update()
	wv.update_joints(delta)
	for e in world.events:
		if e.seq > _last_event:
			_last_event = e.seq
			hud.log_event(e)
	_journey_refresh-=delta
	if _journey_refresh<=0:
		_journey_snapshot=preload("res://sim/service_progress.gd").snapshot(world,train)
		_journey_refresh=.25
	var ns := world.next_signal(train)
	hud.refresh({
		journey=_journey_snapshot,
		dispatch_expectation=preload("res://sim/priority_dispatch.gd").hold_reason(world,train,true),
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
		on_foot = walker!=null and walker.active,
		time_scale = time_scale,
		automatic = train.automatic,
		paused = paused,
		world_clock = world.clock_text(),
		world_day = world.clock_day(),
	})


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if service_editor != null and service_editor.visible:
			if event.physical_keycode in [KEY_ESCAPE,KEY_F5] and not service_editor.confirm_play.visible:
				_close_services()
			return
		if dispatcher._root.visible and hud.modal.is_empty():
			if event.physical_keycode==KEY_ESCAPE:
				if dispatcher._confirm.visible:dispatcher.cancel_handover()
				else:dispatcher.set_open(false)
				return
			if event.physical_keycode not in [KEY_D,KEY_M,KEY_F1,KEY_F5,KEY_F10,KEY_F11,KEY_F12,KEY_T]:return
		# Modal input never reaches train controls; the clock and held-key input pause too.
		match event.physical_keycode:
			KEY_ESCAPE:
				if hud.modal == "progress": _close_progress()
				elif hud.modal == "help": _close_help()
				elif hud.modal == "confirm": _cancel_action()
				elif hud.modal != "" and hud.modal != "pause": hud.show_modal("pause", labels_enabled)
				else: _toggle_pause()
				return
			KEY_F1:
				if hud.modal != "confirm": _toggle_help()
				return
			KEY_F12:
				if hud.modal != "confirm": _toggle_progress()
				return
			KEY_F10:
				performance_overlay.toggle()
				return
			KEY_F11:
				_toggle_fullscreen()
				return
		if hud.modal == "pause":
			match event.physical_keycode:
				KEY_F2: _request_action("wap7")
				KEY_F3: _request_action("lhb")
				KEY_F9: _ui_action("fleet")
				KEY_F7: _request_action("route:southern_corridor" if geographic_drive else "route:kerala_coast")
				KEY_F5: _open_services()
				KEY_F4: _ui_action("clean")
				KEY_F6: _ui_action("labels")
			return
		if hud.modal != "":
			return
		if walker!=null and walker.active and not event.has_meta("controller_command") and event.physical_keycode in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_C,KEY_SPACE,KEY_L]:
			if event.physical_keycode==KEY_C: walker.toggle_crouch()
			if event.physical_keycode==KEY_L: walker.toggle_lamp()
			get_viewport().set_input_as_handled()
			return
		match event.physical_keycode:
			KEY_F5: _open_services()
			KEY_4: _pilot_camera()
			KEY_Q: _head_out_camera(-1)
			KEY_E:
				if event.shift_pressed: _head_out_camera(1)
				else: walker.toggle_seat()
			KEY_9: dispatcher.toggle()
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
				_set_time_scale(1 if event.shift_pressed or time_scale>=32 else time_scale*2)
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
			KEY_F7: _ui_action("routes")
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
				elif cam.mode == CameraRig.Mode.CAB and train.stock_kind.begins_with("ported:"):
					var position_name: String = tv.cycle_cab_position()
					if not position_name.is_empty():
						cam._look = Vector2.ZERO
						hud.toast(position_name + " · Home next position")
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
					var destination: Vector3=world.stations[idx].building
					if geographic_drive: destination-=wv.coordinate_origin
					cam.jump_to(destination)
					_set_cab_visuals(false)
	elif walker!=null and walker.active and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		if not paused and hud.modal.is_empty() and not dispatcher._root.visible: walker.interact()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if cam.drag_moved < 6.0 and cam.mode == CameraRig.Mode.OVERVIEW:
			_pick(event.position)


func _set_cab_visuals(cab: bool) -> void:
	if cam.mode!=CameraRig.Mode.OVERVIEW:
		traffic_presentation.followed_service=""
		cam.follow_point=tv.overview_position
	if walker!=null and cam.mode!=CameraRig.Mode.WALKING: walker.stop()
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


func _pilot_camera() -> void:
	traffic_presentation.followed_service=""
	cam.follow_point=tv.overview_position
	# View changes are not a command to reset the power/brake handle or AI.
	if train.stock_kind.begins_with("ported:"): tv.cab_position = 0
	if cam.mode == CameraRig.Mode.OVERVIEW: _desk_before_cab = dispatcher._root.visible
	cam.set_mode(CameraRig.Mode.CAB)
	cam._look = Vector2.ZERO
	_set_cab_visuals(true)


func _head_out_camera(side: int, toggle: bool=true) -> void:
	if toggle and cam.mode == CameraRig.Mode.HEAD_OUT and cam.head_out_side == side:
		_pilot_camera()
		return
	if cam.mode == CameraRig.Mode.OVERVIEW: _desk_before_cab = dispatcher._root.visible
	cam.set_head_out(side)
	_set_cab_visuals(false)
	dispatcher.set_open(false)
	wv.set_labels_visible(false)


func _enter_cab() -> void:
	if cam.mode == CameraRig.Mode.OVERVIEW:
		_desk_before_cab = dispatcher._root.visible
	train.automatic = false
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
	tv.passenger_seat_index = -1
	tv.passenger_seat = false
	cam._look = Vector2.ZERO
	_enter_passenger()
	audio.reset_positions()



func _enter_passenger() -> void:
	if walker!=null: walker.stop()
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
	if controller != null: controller.neutralize()
	if walker!=null: walker.neutralize()
	cam.set_process_unhandled_input(not value)
	cam._dragging = 0
	for sound in train_audio.values():
		sound.set_paused(paused or (geographic_drive and wv.loading))


func _set_time_scale(value: int) -> void:
	if value not in [1,2,4,8,16,32]:return
	time_scale=value
	AudioServer.playback_speed_scale=float(value)
	for sound in train_audio.values():
		sound.simulation_rate=float(value)
		sound.reset_positions()
	hud.toast("Normal time" if value==1 else "Fast forward ×%d · Shift+T returns to normal time" % value)

func _ui_action(action: String) -> void:
	if action=="skip_missed_stop":
		if train.timetable!=null and train.timetable.skip_missed_stop():
			DispatchPlan.update(world,false,train.id)
			_close_progress()
			_toggle_progress()
		return
	if action=="progress":
		_toggle_progress()
		return
	if action=="close_progress":
		_close_progress()
		return
	if action.begins_with("time:"):
		_set_time_scale(int(action.trim_prefix("time:")))
		return
	if action.begins_with("padcmd:"):
		controller.perform(action.trim_prefix("padcmd:"))
		return
	if action.begins_with("pad_setting:"):
		controller.change_setting(action.trim_prefix("pad_setting:"))
		return
	if action.begins_with("padpoint:"):
		controller.throw_point(action.trim_prefix("padpoint:"))
		return
	if action.begins_with("fleet:"):
		_request_action(action)
		return
	if action.begins_with("pax:"):
		_set_paused(false)
		hud.show_modal("")
		_passenger_preset(int(action.get_slice(":",1)))
		return
	match action:
		"routes": _request_action("route:southern_corridor" if geographic_drive else "route:kerala_coast")
		"services": _open_services()
		"controllers": controller.open_settings()
		"points": controller.open_points()
		"controller_actions", "train_controls", "view_controls", "sound_controls":
			_set_paused(true)
			hud.show_modal(action)
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


func _open_services() -> void:
	_set_paused(true)
	dispatcher.set_open(false)
	hud.show_modal("")
	hud.modal = "services"
	hud._refresh_visibility()
	if service_editor == null:
		service_editor = ServiceEditor.new()
		add_child(service_editor)
		service_editor.closed.connect(_close_services)
		service_editor.play_requested.connect(_play_services)
		service_editor.confirm_play.window_input.connect(controller._popup_input)
		for picker in service_editor.pickers:
			picker.get_popup().window_input.connect(controller._popup_input)
	service_editor.open(world,authored_pack)


func _close_services() -> void:
	service_editor.dismiss()
	hud.show_modal("pause",labels_enabled)
	controller.neutralize()


func _play_services(pack: Dictionary, id: String) -> void:
	var result := ServicePack.build(pack,ServicePack.layout_id(world))
	if not result.ok or not result.world.trains.has(id):
		service_editor._status(result.get("reason","Select a service"),true)
		return
	get_tree().set_meta("service_pack",result.data)
	get_tree().set_meta("player_service",id)
	get_tree().set_meta("traffic_drive",true)
	get_tree().set_meta("imported_fleet","")
	get_tree().set_meta("wap7_drive",false)
	get_tree().set_meta("lhb_drive",false)
	get_tree().call_deferred("reload_current_scene")


func _toggle_progress() -> void:
	if hud.modal=="progress":
		_close_progress()
		return
	_paused_before_progress=paused
	_set_paused(true)
	var p:=preload("res://sim/service_progress.gd").snapshot(world,train)
	hud.can_skip_stop=p.get("missed",false) and train.timetable.index<train.timetable.stops.size()-1
	var text: String="[b]"+train.service_name+"[/b]\n\n"
	if not p.scheduled:
		text+="This solo drive has no booked stops. F5 opens the service designer."
	else:
		text+="[b]Stops completed: %d / %d[/b]\n[b]Stops left: %d[/b]\nOrigin included in the total.\n\n" % [p.completed,p.total,p.remaining]
		if p.skipped>0:text+="Skipped calls: %d (not counted as completed)\n" % p.skipped
		if p.complete:text+="[b]Journey complete[/b]"
		else:
			if not p.current.is_empty():text+="Currently at: "+p.current+"\n"
			text+="[b]Next stop: "+p.next_name+"[/b]\n"
			if p.missed:text+="This call was not recorded. Stop with the full train at the platform, or use the skip button to continue without credit for this call.\n"
			elif is_finite(p.distance_m):
				text+="Distance: %.1f km\n" % (p.distance_m/1000)
				text+=("Estimated time: about %d in-game min\n" if p.waiting.is_empty() else "After clearance: about %d in-game min travel/dwell\n") % maxi(1,ceili(p.estimated_seconds/60))
			text+="Booked arrival: "+preload("res://sim/world_clock.gd").format_time(p.scheduled_arrival)+"\n"
			if not p.waiting.is_empty():text+="\n"+p.waiting+"\n"
			text+="\nEstimate uses the route distance and service speed. Driving and signal waits can change it."
	hud.show_modal("progress",labels_enabled,text)

func _close_progress() -> void:
	_set_paused(_paused_before_progress)
	hud.show_modal("pause" if paused else "",labels_enabled)

func _toggle_help() -> void:
	if hud.modal == "help":
		_close_help()
		return
	_paused_before_help = paused
	_set_paused(true)
	hud.controller_help = ControllerInput.HELP if controller==null or controller.tsw_layout else ControllerInput.LEGACY_HELP
	hud.scenario_brief = ScenarioBrief.describe(world, train, traffic_drive, dispatcher.auto_dispatch, dispatcher.hold_arrivals)
	hud.show_modal("help")


func _close_help() -> void:
	_set_paused(_paused_before_help)
	hud.show_modal("pause" if paused else "", labels_enabled)


func _request_action(action: String) -> void:
	_pending_action = action
	_set_paused(true)
	var descriptions := {"restart": "Restart the current services from the beginning.",
		"wap7": "Start the detailed WAP-7 with mixed ICF coaches.",
		"lhb": "Start the detailed WAP-7 with mixed LHB coaches.",
		"traffic": "Start six mixed passenger services and assign you a random train.",
		"quit": "Quit Train Game and return to the desktop."}
	var description: String = descriptions.get(action, "")
	if action.begins_with("route:"):
		description="Start the 277 km Kerala Coast via Alappuzha and TVC with 32 scheduled passenger services and dynamic priority dispatch." if action.ends_with("kerala_coast") else "Return to the fictional Southern corridor."
	if action.begins_with("fleet:"):
		description = "Start " + PortedStock.LABELS[action.trim_prefix("fleet:")] + "."
	hud.show_modal("confirm", labels_enabled, description)


func _cancel_action() -> void:
	_pending_action = ""
	hud.show_modal("pause", labels_enabled)


func _confirm_action() -> void:
	var action := _pending_action
	_pending_action = ""
	if action != "restart" and get_tree().has_meta("service_pack"): get_tree().remove_meta("service_pack")
	if action.begins_with("route:"):
		get_tree().set_meta("route",action.trim_prefix("route:"))
		get_tree().set_meta("traffic_drive",true)
		get_tree().set_meta("imported_fleet","")
		get_tree().set_meta("traffic_seed",0 if action.ends_with("kerala_coast") else randi())
		get_tree().call_deferred("reload_current_scene")
		return
	if action in ["wap7","lhb"] or action.begins_with("fleet:"):
		get_tree().set_meta("route","southern_corridor")
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
	if controller != null:
		if what == NOTIFICATION_APPLICATION_FOCUS_OUT: controller.window_focus(false)
		elif what == NOTIFICATION_APPLICATION_FOCUS_IN: controller.window_focus(true)
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_request_action("quit")
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and not paused:
		# Alt-tab cannot leave a manually driven train accelerating unattended.
		_set_paused(true)
		hud.show_modal("pause", labels_enabled)


func _visit_station(index: int) -> void:
	if index<0 or index>=world.stations.size(): return
	traffic_presentation.followed_service=""
	cam.follow_point=tv.overview_position
	var destination: Vector3=world.stations[index].origin
	if geographic_drive: destination-=wv.coordinate_origin
	cam.distance=175
	cam.pitch=-.55
	cam.jump_to(destination)
	# Geographic transfers snap the camera instead of travelling through 200 km.
	if geographic_drive: cam._blend=1.0
	_set_cab_visuals(false)
	dispatcher.set_open(false)


func _on_service_deleted(id: String) -> void:
	if id==train.id:return
	if traffic_presentation.followed_service==id:
		traffic_presentation.followed_service=""
		cam.follow_point=tv.overview_position;cam.follow=true
		cam.pivot=tv.overview_position();cam._blend=1.0
		cam._follow_anchor_valid=false
	traffic_presentation.release(id)
	train_motions.erase(id)
	_journey_refresh=0

func _view_train_only(id: String) -> void:
	if not world.trains.has(id): return
	traffic_presentation.ensure_view(id)
	traffic_presentation.ensure_audio(id)
	traffic_presentation.followed_service=id
	cam.set_mode(CameraRig.Mode.OVERVIEW)
	_set_cab_visuals(false)
	cam.follow_point=train_views[id].overview_position
	cam.follow=true
	cam.distance=maxf(80,world.trains[id].length*.85)
	cam.pivot=train_views[id].overview_position()
	cam._blend=1.0
	hud.toast("Viewing "+id+" · still driving "+train.id+" · 4 returns to your pilot seat")

func _select_train(id: String) -> void:
	if id == train.id or not world.trains.has(id):
		return
	traffic_presentation.ensure_view(id)
	traffic_presentation.ensure_audio(id)
	traffic_presentation.followed_service=""
	_journey_refresh=0
	if walker!=null: walker.stop()
	tv.set_cab_view(false)
	if _has_passengers(): tv.set_passenger_view(false)
	if traffic_drive and not train.service_complete: train.automatic = true
	train = world.trains[id]
	tv = train_views[id]
	audio = train_audio[id]
	cam.cab_transform = tv.cab_transform
	cam.head_out_transform = tv.head_out_transform
	cam.follow_point = tv.overview_position
	cam.follow = true
	cam.passenger_transform = tv.passenger_transform if _has_passengers() else Callable()
	if train.stock_kind.begins_with("ported:"):
		cam.distance = maxf(38.0, train.length * .85)
		cam.cab_fov = 76.0
		cam.cab_yaw_limit = PI
	dispatcher.selected_train = id
	world.dispatcher().manual_service=id if traffic_drive else ""
	_set_cab_visuals(cam.mode == CameraRig.Mode.CAB)
	if cam.mode in [CameraRig.Mode.CAB, CameraRig.Mode.HEAD_OUT]:
		train.automatic = false
		if cam.mode == CameraRig.Mode.HEAD_OUT: dispatcher.set_open(false)
	elif cam.mode == CameraRig.Mode.PASSENGER:
		if _has_passengers(): _enter_passenger()
		else: _enter_cab()
	if geographic_drive:
		cam._blend=1.0
		cam.pivot=tv.overview_position()
		cam._follow_anchor_valid=false
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
	get_tree().set_meta("imported_fleet", "icf")
	get_tree().set_meta("wap7_drive", false)
	get_tree().set_meta("lhb_drive", false)
	get_tree().call_deferred("reload_current_scene")


func _switch_lhb() -> void:
	get_tree().set_meta("traffic_drive", false)
	get_tree().set_meta("imported_fleet", "lhb")
	get_tree().set_meta("lhb_drive", false)
	get_tree().set_meta("wap7_drive", false)
	get_tree().call_deferred("reload_current_scene")


func _has_passengers() -> bool:
	return train != null and train.stock_kind in ["lhb", "ported:icf", "ported:lhb", "ported:vb8", "ported:vb16"]
