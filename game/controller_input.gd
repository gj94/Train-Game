extends Node
## One active standard gamepad. UI receives native actions; simulation stays untouched.
const Shape := preload("res://game/controller_math.gd")
const Camera := preload("res://game/controller_camera.gd")
const HELP := """[b]XBOX CONTROLLER · 360 / ONE / SERIES / ELITE[/b]
RT increase power / release brake · LT reduce power / apply brake.
Release the triggers to hold the current handle; LT wins if both are pressed.
A AI/manual · B emergency brake (again at a stand to release) · X coast.
Y cab/exterior · View/Back passenger/cab · Menu/Start pause.
Right stick look/orbit · LB/RB zoom out/in · Right stick click centre/follow.
Left stick pans exterior or moves left/right inside a passenger coach.
In pilot/head-out: D-pad left/right leans out that side (again returns); up pilot.
In other views: D-pad left/right previous/next coach · up first · down last coach.
Left stick click opens/closes dispatch.

[b]MENUS & DISPATCH[/b]
D-pad / left stick move focus · A select/open · B back/cancel.
LB/RB previous/next control; in a dropdown, previous/next page.
Right stick scrolls Help or the timetable (horizontal and vertical).
The route desk has signal/destination selectors, route buttons and service roster.
Menu → Train & view actions provides every remaining driving/camera/sound action.

Disconnecting or losing window focus pauses the simulation.
After connecting, resuming or closing a menu, release sticks, buttons and
triggers before driving again. Reconnection never resumes automatically.
Keyboard and mouse remain available."""
const KEYS := {
	"pilot":KEY_4, "head_left":KEY_Q, "head_right":KEY_E,
	"ai":KEY_A, "emergency":KEY_SPACE, "coast":KEY_X, "reverse":KEY_R,
	"horn":KEY_H, "view":KEY_TAB, "passenger":KEY_V, "follow":KEY_F,
	"seat":KEY_HOME, "berths":KEY_B, "route":KEY_C, "dispatch":KEY_D,
	"timetable":KEY_M, "station1":KEY_1, "station2":KEY_2, "station3":KEY_3,
	"protection":KEY_P, "time":KEY_T, "history":KEY_F8, "performance":KEY_F10,
	"track_down":KEY_BRACKETLEFT, "track_up":KEY_BRACKETRIGHT,
	"clang_down":KEY_COMMA, "clang_up":KEY_PERIOD, "joints":KEY_J,
}
var game
var active_device := -1
var controller_mode := false
var deadzone := .18
var sensitivity := 1.0
var invert_y := false
var vibration := .35
var settings_path := "user://controller.cfg"
var _axes := PackedFloat32Array([0,0,0,0,0,0])
var _buttons := {}
var _armed := false
var _focused := true
var _context := ""
var _direction := Vector2i.ZERO
var _repeat_time := 0.0

func _ready() -> void:
	_load_settings()
	Input.ignore_joypad_on_unfocused_application = true
	# This router owns pad repeat, focus and popup input; keep native keyboard bindings.
	for action in InputMap.get_actions():
		if not str(action).begins_with("ui_"): continue
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				InputMap.action_erase_event(action,event)
	Input.joy_connection_changed.connect(_connection_changed)
	for picker in [game.dispatcher._source,game.dispatcher._exit]:
		picker.get_popup().window_input.connect(_popup_input)
	var devices := Input.get_connected_joypads()
	if not devices.is_empty(): _adopt(devices[0])

func _exit_tree() -> void:
	_stop_vibration()

func _adopt(device: int) -> void:
	active_device = device
	_axes.fill(0)
	_buttons.clear()
	if device in Input.get_connected_joypads():
		for axis in 6: _axes[axis] = Input.get_joy_axis(device,axis)
		for button in 15:
			if Input.is_joy_button_pressed(device,button): _buttons[button] = true
	neutralize()

func _connection_changed(device: int, connected: bool) -> void:
	if connected and active_device < 0:
		_adopt(device)
		game.hud.toast("Controller connected · release controls · Menu/Start opens controls")
	elif not connected and device == active_device:
		_stop_vibration()
		active_device = -1
		_axes.fill(0)
		_buttons.clear()
		neutralize()
		game._set_paused(true)
		game.hud.show_modal("pause",game.labels_enabled)
		_set_mode(true)
		game.hud.toast("Controller disconnected · simulation paused · reconnect or use keyboard",true)

func neutralize() -> void:
	_armed = false
	_direction = Vector2i.ZERO
	_repeat_time = 0
	_stop_vibration()

func window_focus(value: bool) -> void:
	_focused = value
	if value and active_device >= 0: _adopt(active_device)
	else: neutralize()

func _neutral() -> bool:
	return Shape.stick(Vector2(_axes[0],_axes[1]),deadzone) == Vector2.ZERO and Shape.stick(Vector2(_axes[2],_axes[3]),deadzone) == Vector2.ZERO and Shape.handle(_axes[5],_axes[4]) == 0 and _buttons.is_empty()

func drive_input() -> float:
	if active_device < 0 or not _armed or not _focused or game.paused or _ui_open() or _context != "drive": return 0
	return Shape.handle(_axes[5],_axes[4])

func _set_mode(value: bool) -> void:
	if value == controller_mode: return
	controller_mode = value
	game.hud.controller_active = value
	game.hud._refresh_visibility()
	if value and _ui_open(): _ensure_focus()
	elif not value:
		var focus := get_viewport().gui_get_focus_owner()
		if focus != null: focus.release_focus()

func _popup_input(event: InputEvent) -> void:
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion): return
	var popup = _popup()
	if popup != null: popup.set_input_as_handled()
	elif _confirmation() != null: _confirmation().set_input_as_handled()
	_input(event)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_set_mode(false)
		return
	if event is InputEventMouseButton or (event is InputEventMouseMotion and event.relative.length() > 2):
		_set_mode(false)
		return
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion): return
	get_viewport().set_input_as_handled()
	if not _focused: return
	var intentional: bool = event.pressed if event is InputEventJoypadButton else absf(event.axis_value) > .25
	if active_device < 0 and intentional: _adopt(event.device)
	if event.device != active_device: return
	if intentional: _set_mode(true)
	if event is InputEventJoypadMotion:
		if event.axis >= 0 and event.axis < 6: _axes[event.axis] = clampf(event.axis_value,-1,1)
		return
	if event.pressed: _buttons[event.button_index] = true
	else: _buttons.erase(event.button_index)
	if not event.pressed: return
	if event.button_index == JOY_BUTTON_START:
		_close_popups()
		if game.hud.modal.is_empty(): game._ui_action("pause")
		else: _back()
		return
	if _ui_open():
		_ensure_focus()
		match event.button_index:
			JOY_BUTTON_A: _ui_pulse("ui_accept")
			JOY_BUTTON_B: _back()
			JOY_BUTTON_LEFT_STICK:
				if game.hud.modal.is_empty(): _back()
			JOY_BUTTON_LEFT_SHOULDER: _ui_pulse("ui_page_up" if _popup() != null else "ui_focus_prev")
			JOY_BUTTON_RIGHT_SHOULDER: _ui_pulse("ui_page_down" if _popup() != null else "ui_focus_next")
			JOY_BUTTON_BACK:
				if game.hud.modal.is_empty(): game.dispatcher.toggle_timetable()
		return
	if game.paused: return
	match event.button_index:
		JOY_BUTTON_A: shortcut("ai")
		JOY_BUTTON_B:
			shortcut("emergency")
			if game.train.emergency: _rumble()
		JOY_BUTTON_X: shortcut("coast")
		JOY_BUTTON_Y: shortcut("view")
		JOY_BUTTON_BACK: shortcut("passenger")
		JOY_BUTTON_LEFT_STICK: shortcut("dispatch")
		JOY_BUTTON_RIGHT_STICK:
			game.cam._look = Vector2.ZERO
			if game.cam.mode == 0: game.cam.follow = true
		JOY_BUTTON_DPAD_UP:
			if game.cam.mode in [1,3]: shortcut("pilot")
			else: game._passenger_preset(0)
		JOY_BUTTON_DPAD_DOWN: game._passenger_preset(2)
		JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT:
			if game.cam.mode in [1,3]:
				shortcut("head_left" if event.button_index == JOY_BUTTON_DPAD_LEFT else "head_right")
			elif game._has_passengers():
				if game.cam.mode != 2: game._enter_passenger()
				game.tv.change_passenger_coach(-1 if event.button_index == JOY_BUTTON_DPAD_LEFT else 1)
				game.cam._look = Vector2.ZERO

func shortcut(action: String) -> void:
	if not KEYS.has(action): return
	var event := InputEventKey.new()
	event.physical_keycode = KEYS[action]
	event.pressed = true
	# Reuse the keyboard command path without injecting a held keyboard state.
	game._unhandled_input(event)

func perform(action: String) -> void:
	game.hud.show_modal("")
	game._set_paused(false)
	if action.begins_with("station"): game.cam.set_mode(0)
	shortcut(action)

func _service_ui() -> bool:
	return game.get("service_editor") != null and game.service_editor.visible

func _pickers() -> Array:
	var result: Array = [game.dispatcher._source,game.dispatcher._exit]
	if _service_ui(): result.append_array(game.service_editor.pickers)
	return result

func _confirmation():
	return game.service_editor.confirm_play if _service_ui() and game.service_editor.confirm_play.visible else null

func _ui_open() -> bool:
	return not game.hud.modal.is_empty() or game.dispatcher._root.visible

func _popup():
	for picker in _pickers():
		if picker.get_popup().visible: return picker.get_popup()
	return null

func _close_popups() -> void:
	var popup = _popup()
	if popup != null: popup.hide()

func _ensure_focus() -> void:
	if not controller_mode or _popup() != null: return
	if _confirmation() != null:
		if _confirmation().gui_get_focus_owner() == null: _confirmation().get_cancel_button().grab_focus()
		return
	if _service_ui():
		var owner := get_viewport().gui_get_focus_owner()
		if owner == null or not game.service_editor.panel.is_ancestor_of(owner):
			game.service_editor.roster.grab_focus()
		return
	var focus := get_viewport().gui_get_focus_owner()
	var container: Control = game.hud._buttons if not game.hud.modal.is_empty() else game.dispatcher._root
	if focus == null or not focus.is_visible_in_tree() or not container.is_ancestor_of(focus):
		if not game.hud.modal.is_empty(): game.hud.focus_first()
		else: game.dispatcher._source.grab_focus()

func _ui_pulse(action: String) -> void:
	_ensure_focus()
	if _popup() != null:
		_popup_action(action)
		return
	var target: Viewport = _confirmation() if _confirmation() != null else get_viewport()
	for pressed in [true,false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		target.push_input(event)

func _popup_action(action: String) -> void:
	# Native popup Windows own their keyboard events, so use their selection API.
	var popup = _popup()
	if popup == null: return
	if action == "ui_cancel":
		popup.hide()
		return
	var picker: OptionButton
	for candidate in _pickers():
		if candidate.get_popup() == popup: picker=candidate; break
	if picker == null: return
	var index: int = popup.get_focused_item()
	if action == "ui_accept":
		if index < 0: index = picker.selected
		if index >= 0 and not picker.is_item_disabled(index):
			picker.select(index)
			popup.hide()
			picker.item_selected.emit(index)
		return
	var step := 0
	if action in ["ui_down","ui_right","ui_page_down"]: step = 8 if action == "ui_page_down" else 1
	elif action in ["ui_up","ui_left","ui_page_up"]: step = -8 if action == "ui_page_up" else -1
	if step != 0 and picker.item_count > 0:
		popup.set_focused_item(clampi((picker.selected if index < 0 else index)+step,0,picker.item_count-1))

func _back() -> void:
	if _confirmation() != null:
		_confirmation().hide()
		return
	if _popup() != null:
		_ui_pulse("ui_cancel")
		return
	if _service_ui():
		game._close_services()
		return
	match game.hud.modal:
		"confirm": game._cancel_action()
		"help": game._close_help()
		"pause": game._ui_action("resume")
		"":
			game.dispatcher.set_open(false)
			neutralize()
		_: game.hud.show_modal("pause",game.labels_enabled)

func _nav_vector() -> Vector2:
	var buttons := Vector2(int(_buttons.has(JOY_BUTTON_DPAD_RIGHT))-int(_buttons.has(JOY_BUTTON_DPAD_LEFT)),int(_buttons.has(JOY_BUTTON_DPAD_DOWN))-int(_buttons.has(JOY_BUTTON_DPAD_UP)))
	return buttons if buttons != Vector2.ZERO else Shape.stick(Vector2(_axes[0],_axes[1]),deadzone)

func _repeat(direction: Vector2i, delta: float, navigate: Callable) -> void:
	if direction == Vector2i.ZERO:
		_direction = direction
		_repeat_time = 0
		return
	if direction != _direction:
		_direction = direction
		_repeat_time = .35
		navigate.call(direction)
	else:
		_repeat_time -= delta
		if _repeat_time <= 0:
			_repeat_time = .12
			navigate.call(direction)

func _process(delta: float) -> void:
	if game == null: return
	var context: String = game.hud.modal if not game.hud.modal.is_empty() else ("desk" if game.dispatcher._root.visible else "drive")
	if context != _context:
		_context = context
		neutralize()
	if active_device < 0 or not _focused: return
	if not _armed and _neutral(): _armed = true
	var right := Shape.stick(Vector2(_axes[2],_axes[3]),deadzone)
	var left := Shape.stick(Vector2(_axes[0],_axes[1]),deadzone)
	if _ui_open():
		if controller_mode: _ensure_focus()
		_repeat(Shape.cardinal(_nav_vector()),delta,func(d):
			_ui_pulse("ui_right" if d.x > 0 else ("ui_left" if d.x < 0 else ("ui_down" if d.y > 0 else "ui_up"))))
		if _service_ui():
			_scroll_tree(game.service_editor.panel,right*650*delta)
		elif not game.hud.modal.is_empty():
			game.hud._body.get_v_scroll_bar().value += right.y*650*delta
		elif game.dispatcher.timetable_open:
			_scroll_tree(game.dispatcher._timetable._table,right*650*delta)
	elif not game.paused and _armed:
		var look := right*sensitivity
		if invert_y: look.y = -look.y
		var zoom := float(int(_buttons.has(JOY_BUTTON_RIGHT_SHOULDER))-int(_buttons.has(JOY_BUTTON_LEFT_SHOULDER)))
		Camera.apply(game.cam,look,left if game.cam.mode == 0 else Vector2.ZERO,zoom,delta)
		if game.cam.mode == 2:
			_repeat(Shape.cardinal(Vector2(left.x,0)),delta,func(d):
				game.tv.change_passenger_bay(d.x))
	game.hud.set_controller_hint(("D-pad / LS move · A select · B back · LB/RB next control · RS scroll" if _ui_open() else "RT/LT power/brake · A AI · B emergency · Y view · View/Back passenger · Menu/Start pause · LS click dispatch") if _armed or _ui_open() else "Release controller sticks, triggers and buttons to continue")

func _scroll_tree(node: Node, offset: Vector2) -> void:
	# Tree owns internal scrollbars; it exposes no public scrollbar getter.
	for child in node.get_children(true):
		if child is VScrollBar: child.value += offset.y
		elif child is HScrollBar: child.value += offset.x
		else: _scroll_tree(child,offset)

func _rumble() -> void:
	if vibration > 0 and active_device in Input.get_connected_joypads():
		Input.start_joy_vibration(active_device,vibration*.6,vibration,.15)

func _stop_vibration() -> void:
	if active_device in Input.get_connected_joypads(): Input.stop_joy_vibration(active_device)

func open_points() -> void:
	game._set_paused(true)
	game.hud.controller_options["points"] = game.world.graph.switches
	game.hud.show_modal("points")

func throw_point(id: String) -> void:
	game._report(game.world.throw_switch(id),"Switch %s thrown" % id)
	open_points()
	call_deferred("_focus_setting","padpoint:"+id)

func open_settings() -> void:
	game._set_paused(true)
	var name := Input.get_joy_name(active_device) if active_device >= 0 else "No controller connected"
	if name.is_empty(): name = "Standard gamepad"
	game.hud.controller_options = {name=name,deadzone=deadzone,sensitivity=sensitivity,invert=invert_y,vibration=vibration}
	game.hud.controller_help = HELP
	game.hud.show_modal("controllers")

func change_setting(name: String) -> void:
	match name:
		"deadzone": deadzone = .12 if deadzone >= .30 else snappedf(deadzone+.06,.01)
		"sensitivity": sensitivity = .5 if sensitivity >= 2.0 else sensitivity+.25
		"invert": invert_y = not invert_y
		"vibration": vibration = 0 if vibration >= .7 else (.35 if vibration == 0 else .7)
		"defaults":
			deadzone = .18; sensitivity = 1; invert_y = false; vibration = .35
	_save_settings()
	open_settings()
	call_deferred("_focus_setting","pad_setting:"+name)

func _focus_setting(action: String) -> void:
	if not controller_mode: return
	for button in game.hud._buttons.get_children():
		if button.get_meta("action","") == action: button.grab_focus()

func _number(config: ConfigFile, key: String, fallback: float, minimum: float, maximum: float) -> float:
	var value = config.get_value("controller",key,fallback)
	if (value is float or value is int) and is_finite(float(value)): return clampf(float(value),minimum,maximum)
	return fallback

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) != OK: return
	deadzone = _number(config,"deadzone",.18,.05,.45)
	sensitivity = _number(config,"sensitivity",1,.25,3)
	vibration = _number(config,"vibration",.35,0,1)
	invert_y = config.get_value("controller","invert_y",false) == true

func _save_settings() -> void:
	var config := ConfigFile.new()
	for key in ["deadzone","sensitivity","vibration","invert_y"]: config.set_value("controller",key,get(key))
	if config.save(settings_path) != OK: game.hud.toast("Controller settings could not be saved",true)
