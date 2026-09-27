extends Node3D
## Phase 1 game: builds the first layout, runs the sim, handles input.

const FirstLine := preload("res://sim/layouts/first_line.gd")
const WorldView := preload("res://game/world_view.gd")
const TrainView := preload("res://game/train_view.gd")
const CameraRig := preload("res://game/camera_rig.gd")
const Hud := preload("res://game/hud.gd")
const TrainAudio := preload("res://game/train_audio.gd")
const AxleJoint := preload("res://game/axle_joint.gd")

const HANDLE_RATE := 0.8   # handle travel per second while W/S held

var world: RailWorld
var train: Train
var wv
var tv
var cam
var hud
var audio
var time_scale := 1
var _last_event := 0


func _ready() -> void:
	world = FirstLine.build()
	train = world.trains.T1
	wv = WorldView.new()
	wv.build(world, self)
	tv = TrainView.new()
	tv.build(train, world.graph, self, wv)
	cam = CameraRig.new()
	cam.cab_transform = tv.cab_transform
	cam.follow_point = tv.head_position
	add_child(cam)
	cam.make_current()
	audio = TrainAudio.new()
	add_child(audio)
	# Axles of the 8-car MEMU as modelled by TrainView (21.3 m bodies, 0.6 m gaps, bogies 3 m in).
	var axles := AxleJoint.rake_axles(tv.cars.size(), TrainView.CAR_LENGTH + TrainView.CAR_GAP,
		TrainView.CAR_LENGTH, TrainView.BOGIE_INSET, 2.5)
	audio.setup(train, world, cam, axles)
	hud = Hud.new()
	add_child(hud)
	hud.toast("Welcome to Chennapuram. Press C to ask for the starter signal, then W to power up.")


func _physics_process(delta: float) -> void:
	var dir := 0.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir += 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir -= 1.0
	if dir != 0.0:
		train.controller = clampf(train.controller + dir * HANDLE_RATE * delta, -1.0, 1.0)
	for i in time_scale:
		world.step(delta)


func _process(_delta: float) -> void:
	tv.update()
	wv.update()
	for e in world.events:
		if e.seq > _last_event:
			_last_event = e.seq
			hud.log_event(e)
	var ns := world.next_signal(train)
	hud.refresh({
		train_id = train.id,
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
	})


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_TAB:
				cam.toggle_mode()
				_set_cab_visuals(cam.mode == CameraRig.Mode.CAB)
			KEY_X:
				train.controller = 0.0
			KEY_H:
				audio.horn()
			KEY_SPACE:
				if train.emergency:
					_report(world.release_emergency(train.id), "Emergency brake released")
				else:
					train.emergency = true
			KEY_C:
				_report(world.request_signal_ahead(train.id), "Signal cleared")
			KEY_R:
				_report(world.reverse_train(train.id), "Changed ends — you are now driving from the other cab")
			KEY_F:
				cam.follow = true
				cam.set_mode(CameraRig.Mode.OVERVIEW)
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
	audio.set_interior(cab)


func _pick(screen_pos: Vector2) -> void:
	var from: Vector3 = cam.project_ray_origin(screen_pos)
	var to: Vector3 = from + cam.project_ray_normal(screen_pos) * 6000.0
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	if hit.is_empty() or not hit.collider.has_meta("pick"):
		return
	var info: Dictionary = hit.collider.get_meta("pick")
	if info.kind == "signal":
		var cleared: bool = world.signals[info.id].cleared
		_report(world.set_signal(info.id, not cleared), "Signal %s %s" % [info.id, "put back to red" if cleared else "cleared"])
	elif info.kind == "switch":
		_report(world.throw_switch(info.id), "Switch %s thrown" % info.id)


func _report(result: Dictionary, ok_text: String) -> void:
	hud.toast(ok_text if result.ok else result.reason)
