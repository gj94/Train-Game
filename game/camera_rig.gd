extends Camera3D
## One camera with overview, pilot, passenger and head-out viewpoints.
## OVERVIEW — orbit around a pivot (right-drag orbit, left-drag pan, wheel zoom),
##            optionally following the train.
## CAB      — driver's seat in the leading cab (right-drag to look around).

enum Mode { OVERVIEW, CAB, PASSENGER, HEAD_OUT }

var head_out_transform: Callable
var head_out_side := -1
var _blend_duration := BLEND_TIME
var _close_driving_blend := false
var _blend_reference := Transform3D()

const BLEND_TIME := 1.1

var mode := Mode.OVERVIEW
var pivot := Vector3.ZERO
var yaw := -0.65
var pitch := -0.40
var distance := 205.0
var cab_fov := 70.0
var cab_yaw_limit := 2.6
var follow := true

var cab_transform: Callable     # () -> Transform3D
var passenger_transform: Callable
var follow_point: Callable      # () -> Vector3

var _blend := 1.0
var _from := Transform3D()
var _from_fov := 60.0
var _look := Vector2.ZERO       # cab head-turn (yaw, pitch)
var _dragging := 0              # mouse button being dragged, 0 = none
var drag_moved := 0.0           # pixels moved during the current left-button press
var _follow_anchor := Vector3.ZERO
var _follow_anchor_valid := false


func _ready() -> void:
	far = 6000.0
	near = 0.1
	if follow_point.is_valid():
		pivot = follow_point.call()
	global_transform = _target()


func set_mode(m: Mode) -> void:
	if m == mode:
		return
	_from = global_transform
	_from_fov = fov
	_blend = 0.0
	# Moving between close driving viewpoints should feel immediate.
	_close_driving_blend = mode in [Mode.CAB, Mode.HEAD_OUT] and m in [Mode.CAB, Mode.HEAD_OUT]
	_blend_duration = .18 if _close_driving_blend else BLEND_TIME
	if _close_driving_blend and head_out_transform.is_valid(): _blend_reference = head_out_transform.call(head_out_side)
	mode = m
	_follow_anchor_valid = false
	_look = Vector2.ZERO
	if m == Mode.OVERVIEW:
		follow = true


func toggle_mode() -> void:
	set_mode(Mode.CAB if mode == Mode.OVERVIEW else Mode.OVERVIEW)


func shift_origin(delta: Vector3) -> void:
	global_position -= delta
	pivot -= delta
	_from.origin -= delta
	_blend_reference.origin -= delta
	_follow_anchor -= delta


func jump_to(p: Vector3) -> void:
	set_mode(Mode.OVERVIEW)
	follow = false
	_from = global_transform
	_blend = 0.0
	pivot = p


func set_head_out(side: int) -> void:
	if mode == Mode.HEAD_OUT and side != head_out_side:
		_from = global_transform
		_from_fov = fov
		_blend = 0.0
		_blend_duration = .18
		_close_driving_blend = true
		_blend_reference = head_out_transform.call(side) if head_out_transform.is_valid() else Transform3D()
		_look = Vector2.ZERO
	head_out_side = -1 if side < 0 else 1
	set_mode(Mode.HEAD_OUT)


func _target() -> Transform3D:
	if mode == Mode.HEAD_OUT and head_out_transform.is_valid():
		var t: Transform3D = head_out_transform.call(head_out_side)
		t.basis = t.basis * Basis.from_euler(Vector3(_look.y, _look.x, 0))
		return t
	if mode == Mode.PASSENGER and passenger_transform.is_valid():
		var t: Transform3D = passenger_transform.call()
		t.basis = t.basis * Basis.from_euler(Vector3(_look.y, _look.x, 0))
		return t
	if mode == Mode.CAB and cab_transform.is_valid():
		var t: Transform3D = cab_transform.call()
		t.basis = t.basis * Basis.from_euler(Vector3(_look.y, _look.x, 0))
		return t
	var offset := Basis.from_euler(Vector3(pitch, yaw, 0)) * Vector3(0, 0, distance)
	var pos := pivot + offset
	# Frame the railway in the open area above and left of the route desk.
	var right := Basis(Vector3.UP, yaw).x
	var target := pivot + right * distance * 0.12 - Vector3.UP * distance * 0.10
	# Close inspection frames the rail/wheels instead of looking below ground.
	target += Vector3.UP * .75 * (1.0 - smoothstep(12.0, 45.0, distance))
	return Transform3D(Basis.looking_at(target - pos, Vector3.UP), pos)


func _process(delta: float) -> void:
	if mode == Mode.HEAD_OUT and head_out_transform.is_valid():
		pivot = (head_out_transform.call(head_out_side) as Transform3D).origin
	if mode == Mode.PASSENGER and passenger_transform.is_valid():
		pivot = (passenger_transform.call() as Transform3D).origin
	if mode == Mode.CAB and cab_transform.is_valid():
		pivot = (cab_transform.call() as Transform3D).origin
	if mode == Mode.OVERVIEW and follow and follow_point.is_valid():
		var anchor: Vector3 = follow_point.call()
		if _follow_anchor_valid:
			pivot += anchor - _follow_anchor
		pivot = pivot.lerp(anchor, 1.0 - exp(-4.0 * delta))
		_follow_anchor = anchor
		_follow_anchor_valid = true
	else:
		_follow_anchor_valid = false
	var target := _target()
	var target_fov := cab_fov if mode != Mode.OVERVIEW else 55.0
	if _blend < 1.0:
		_blend = minf(1.0, _blend + delta / _blend_duration)
		var t := smoothstep(0.0, 1.0, _blend)
		var start := _from
		# Carry the blend start with the cab; a moving train must not leave its
		# camera behind during the quick lean-out transition, including curves.
		if _close_driving_blend and head_out_transform.is_valid():
			var anchor: Transform3D = head_out_transform.call(head_out_side)
			start = anchor * _blend_reference.affine_inverse() * _from
		global_transform = start.interpolate_with(target, t)
		fov = lerpf(_from_fov, target_fov, t)
	else:
		global_transform = target
		fov = target_fov


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_dragging = mb.button_index
			if mb.button_index == MOUSE_BUTTON_LEFT:
				drag_moved = 0.0
		elif not mb.pressed and mb.button_index == _dragging:
			_dragging = 0
		# Releasing look keeps the chosen direction. Recenter deliberately.
		if mb.pressed and mb.button_index == MOUSE_BUTTON_MIDDLE and mode != Mode.OVERVIEW:
			_look = Vector2.ZERO
		if mode != Mode.OVERVIEW and mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				cab_fov = maxf(38.0, cab_fov - 4.0)
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				cab_fov = minf(82.0, cab_fov + 4.0)
		if mode == Mode.OVERVIEW and mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				distance = maxf(3.0, distance * 0.88)
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				distance = minf(3000.0, distance / 0.88)
	elif event is InputEventMouseMotion and _dragging != 0:
		var rel := (event as InputEventMouseMotion).relative
		if _dragging == MOUSE_BUTTON_RIGHT:
			if mode == Mode.OVERVIEW:
				yaw -= rel.x * 0.005
				pitch = clampf(pitch - rel.y * 0.004, -1.5, -0.05)
			else:
				_look.x = clampf(_look.x - rel.x * 0.005, -cab_yaw_limit, cab_yaw_limit)
				_look.y = clampf(_look.y - rel.y * 0.004, -0.95, 0.85)
		elif mode == Mode.OVERVIEW:   # left or middle drag pans
			drag_moved += rel.length()
			if _dragging == MOUSE_BUTTON_MIDDLE or drag_moved > 6.0:
				follow = false
				var right := global_transform.basis.x
				var fwd := Vector3(-global_transform.basis.z.x, 0, -global_transform.basis.z.z).normalized()
				pivot -= (right * rel.x - fwd * rel.y) * distance * 0.0016
		else:
			drag_moved += rel.length()
