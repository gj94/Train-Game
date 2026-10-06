extends CanvasLayer
## Compact driver information and modal menus. Simulation stays in main/sim.
signal action_requested(action: String)
const Clock := preload("res://sim/world_clock.gd")
const PortedStock := preload("res://sim/stock/ported_stock.gd")
const ControllerMenus := preload("res://game/controller_menus.gd")
const HELP := """[b]DRIVING[/b]
W / ↑ more power · S / ↓ less power / more brake · X coast
Space emergency brake (again at a stand to release)
C next signal's route desk · R change ends when stopped · H horn
Tab cab / exterior · A selected train AI / manual

[b]CAMERA & PASSENGERS[/b]
F follow train · 1 / 2 / 3 visit a station
Outside: right-drag orbit, left-drag pan, wheel zoom
Cab / passenger: right-drag look, wheel zoom
Passenger trains: V passenger / cab. In passenger view: 1 first / 2 middle / 3 last coach.
Alt+1 / Alt+2 / Alt+3 enter those views directly. PgUp/PgDn coach, ←/→ position,
Home aisle / seat. Original LHB rake: B fold / lower middle berths.

[b]DISPATCHING[/b]
D open / close dispatch · M timetable / map
Select an entrance and exit, then SET ROUTE. PUT TO RED cancels safely.
Select any service in the roster to follow it. Tab takes manual control.
AUTO DISPATCH requests booked routes. HOLD MRT queues trains at Maruthur.
AI needs routes and waits for its departure time and station dwell.

[b]DISPLAY & SESSION[/b]
Esc pause menu / back · F1 controls · F4 clean view / restore
F6 track labels · F8 event history · F11 fullscreen / window
T time ×1 / ×2 / ×4 · P train protection on / off
F2 WAP-7 light engine / MEMUs · F3 LHB rake / MEMUs
F9 new random traffic service / solo imported fleet
Changing scenario or restarting asks first. There is no save/load yet.

[b]SOUND & DIAGNOSTICS[/b]
[ / ] track sound quieter / louder (2 dB)
, / . clang quieter / louder · J rail-joint markers
Approved track-only sound keeps the horn and engine layers muted."""
var scenario_brief := ""
var controller_active := false
var controller_help := ""
var controller_options := {}
var _pad_hint: Label
var _button_scroll: ScrollContainer
var clean_view := false
var history_open := false
var modal := ""
var _info: RichTextLabel
var _mode: Label
var _toast: Label
var _log: RichTextLabel
var _toolbar: HBoxContainer
var _shade: ColorRect
var _heading: Label
var _body: RichTextLabel
var _buttons: VBoxContainer
var _toast_time := 0.0
var _critical_toast := false
var _log_lines: Array[String] = []

func _ready() -> void:
	layer = 5
	_info = _rich(Vector2(16, 16), Vector2(650, 96), 18)
	_info.add_theme_stylebox_override("normal", _panel_style())
	_mode = Label.new()
	add_child(_mode)
	_mode.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_mode.offset_left = -850
	_mode.offset_right = -16
	_mode.offset_top = 64
	_mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_mode.add_theme_font_size_override("font_size", 16)
	_mode.add_theme_constant_override("outline_size", 6)
	_mode.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toolbar = HBoxContainer.new()
	add_child(_toolbar)
	_toolbar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_toolbar.offset_left = -440
	_toolbar.offset_right = -16
	_toolbar.offset_top = 16
	_toolbar.add_theme_constant_override("separation", 8)
	_button(_toolbar, "DISPATCH  D", "dispatch")
	_button(_toolbar, "HELP  F1", "help")
	_button(_toolbar, "MENU  Esc", "pause")
	_toast = Label.new()
	add_child(_toast)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_left = -540
	_toast.offset_right = 540
	_toast.offset_top = 124
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.add_theme_font_size_override("font_size", 18)
	_toast.add_theme_color_override("font_color", Color("ffca72"))
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log = _rich(Vector2(16, 184), Vector2(640, 200), 16)
	_log.add_theme_stylebox_override("normal", _panel_style())
	_log.scroll_active = true
	_log.mouse_filter = Control.MOUSE_FILTER_STOP
	_log.text = "[b]EVENT HISTORY  ·  F8 to close[/b]\nNo events yet."
	_log.visible = false
	_build_modal()
	_pad_hint = Label.new()
	add_child(_pad_hint)
	_pad_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_pad_hint.offset_left = 20
	_pad_hint.offset_right = -20
	_pad_hint.offset_top = -34
	_pad_hint.offset_bottom = -6
	_pad_hint.clip_text = true
	_pad_hint.add_theme_font_size_override("font_size", 16)
	_pad_hint.add_theme_constant_override("outline_size", 5)
	_pad_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad_hint.visible = false

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.062, 0.086, 0.94)
	style.border_color = Color("36525d")
	style.set_border_width_all(1)
	style.set_content_margin_all(14)
	style.set_corner_radius_all(8)
	return style

func _rich(pos: Vector2, dimensions: Vector2, font: int) -> RichTextLabel:
	var rich := RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.position = pos
	rich.size = dimensions
	rich.fit_content = false
	rich.scroll_active = false
	rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rich.add_theme_font_size_override("normal_font_size", font)
	rich.add_theme_font_size_override("bold_font_size", font)
	add_child(rich)
	return rich

func _button(parent: Node, text: String, action: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.set_meta("action", action)
	button.custom_minimum_size.y = 40
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 16)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := _panel_style()
		style.bg_color = Color("213d49") if state != "normal" else Color("122b37")
		if state == "focus":
			style.border_color = Color("ffca72")
			style.set_border_width_all(3)
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(func(): action_requested.emit(action))
	parent.add_child(button)
	return button

func _build_modal() -> void:
	_shade = ColorRect.new()
	add_child(_shade)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.color = Color(0.005, 0.015, 0.025, 0.72)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	var dialog := PanelContainer.new()
	_shade.add_child(dialog)
	dialog.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	dialog.offset_left = -400
	dialog.offset_right = 400
	dialog.offset_top = -365
	dialog.offset_bottom = 365
	dialog.add_theme_stylebox_override("panel", _panel_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	dialog.add_child(column)
	_heading = Label.new()
	_heading.add_theme_font_size_override("font_size", 27)
	_heading.add_theme_color_override("font_color", Color("ffca72"))
	column.add_child(_heading)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_font_size_override("normal_font_size", 18)
	_body.add_theme_font_size_override("bold_font_size", 18)
	column.add_child(_body)
	_button_scroll = ScrollContainer.new()
	_button_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_button_scroll.follow_focus = true
	column.add_child(_button_scroll)
	_buttons = VBoxContainer.new()
	_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_buttons.add_theme_constant_override("separation", 8)
	_button_scroll.add_child(_buttons)
	_shade.visible = false

func show_modal(kind: String, labels_on: bool = false, description: String = "") -> void:
	modal = kind
	_shade.visible = kind != ""
	for button in _buttons.get_children():
		_buttons.remove_child(button)
		button.queue_free()
	_body.scroll_to_line(0)
	match kind:
		"pause":
			_heading.text = "PAUSED"
			_body.text = "Resume to continue the current service.\n[b]F4[/b] clears the screen; [b]D[/b] opens dispatch."
			_button(_buttons, "Resume  ·  Esc", "resume")
			_button(_buttons, "Scenario & controls  ·  F1", "help")
			_button(_buttons, "Train & view actions…", "controller_actions")
			_button(_buttons, "Controller settings & layout…", "controllers")
			_button(_buttons, "Passenger views…", "passengers")
			_button(_buttons, "Clean view  ·  F4", "clean")
			_button(_buttons, "Track labels: " + ("ON" if labels_on else "OFF") + "  ·  F6", "labels")
			_button(_buttons, "Fullscreen / window  ·  F11", "fullscreen")
			_button(_buttons, "WAP-7 light engine / MEMUs  ·  F2", "wap7")
			_button(_buttons, "LHB passenger rake / MEMUs  ·  F3", "lhb")
			_button(_buttons, "Traffic / solo fleet…  ·  F9", "fleet")
			_button(_buttons, "Restart current services…", "restart")
			_button(_buttons, "Quit to desktop…", "quit")
		"controllers", "controller_actions", "train_controls", "view_controls", "sound_controls", "points":
			ControllerMenus.build(self, kind)
		"passengers":
			_heading.text = "PASSENGER VIEWS"
			_body.text = "Ride inside the first, middle or last passenger coach.\nThe camera and sound follow that coach. Luggage and generator vans are skipped.\n\n[b]1 / 2 / 3[/b] switch views while riding; [b]PgUp/PgDn[/b] visit any coach."
			_button(_buttons, "First passenger coach  ·  Alt+1", "pax:0")
			_button(_buttons, "Middle passenger coach  ·  Alt+2", "pax:1")
			_button(_buttons, "Last passenger coach  ·  Alt+3", "pax:2")
			_button(_buttons, "Back", "fleet_back")
		"help":
			_heading.text = "SCENARIO & CONTROLS  /  PAUSED"
			_body.text = scenario_brief + "\n" + controller_help + "\n\n[b]KEYBOARD REFERENCE[/b]\n" + HELP
			_button(_buttons, "Back  ·  Esc / F1", "close_help")
		"fleet":
			_heading.text = "TRAFFIC & INDIAN RAIL FLEET"
			_body.text = "Start a random service among six trains, or choose a solo drive below.\nICF/LHB showcases contain all seven coach classes.\nVande Bharat uses the source's compact car lengths."
			_button(_buttons, "New random traffic service", "traffic")
			for choice in PortedStock.CHOICES:
				_button(_buttons, PortedStock.LABELS[choice], "fleet:" + choice)
			_button(_buttons, "Back  ·  Esc", "fleet_back")
		"confirm":
			_heading.text = "LEAVE THIS RUN?"
			_body.text = description + "\n\nCurrent progress will be lost. Save/load is not available yet."
			_button(_buttons, "Cancel  ·  Esc", "cancel")
			_button(_buttons, "Continue", "confirm")
	var choices := _buttons.get_children()
	for i in choices.size():
		choices[i].focus_next = choices[(i+1)%choices.size()].get_path()
		choices[i].focus_previous = choices[posmod(i-1,choices.size())].get_path()
		choices[i].focus_neighbor_bottom = choices[i].focus_next
		choices[i].focus_neighbor_top = choices[i].focus_previous
	_button_scroll.custom_minimum_size.y = clampf(_buttons.get_child_count()*48-8,0,420)
	if controller_active and kind != "": call_deferred("focus_first")
	elif kind == "":
		var focus := get_viewport().gui_get_focus_owner()
		if focus != null: focus.release_focus()
	_refresh_visibility()

func focus_first() -> void:
	if modal.is_empty(): return
	for button in _buttons.get_children():
		if not button.disabled and button.is_visible_in_tree():
			button.grab_focus()
			return

func set_controller_hint(text: String) -> void:
	_pad_hint.text = text
	_pad_hint.visible = controller_active and (not clean_view or modal != "")

func set_clean(value: bool) -> void:
	clean_view = value
	_refresh_visibility()

func toggle_history() -> void:
	history_open = not history_open
	_refresh_visibility()

func _refresh_visibility() -> void:
	if _pad_hint != null: _pad_hint.visible = controller_active and (not clean_view or modal != "")
	_info.visible = not clean_view and modal == ""
	_mode.visible = not clean_view and modal == ""
	_toolbar.visible = not clean_view and modal == ""
	_log.visible = history_open and not clean_view and modal == ""
	_toast.visible = _toast_time > 0 and (not clean_view or _critical_toast)

func toast(text: String, critical: bool = false) -> void:
	_toast.text = text
	_toast_time = 6.0 if critical else 4.0
	_critical_toast = critical
	_toast.modulate.a = 1.0
	_refresh_visibility()

func log_event(event: Dictionary) -> void:
	var stamp := Clock.format_time(event.get("clock", event.t))
	_log_lines.append("[color=#ffca72]%s[/color]  %s" % [stamp, event.text])
	if _log_lines.size() > 8:
		_log_lines.pop_front()
	_log.text = "[b]EVENT HISTORY  ·  F8 to close[/b]\n" + "\n".join(_log_lines)
	toast(event.text, true)

func _process(delta: float) -> void:
	if _toast_time > 0:
		_toast_time = maxf(0, _toast_time - delta)
		_toast.modulate.a = clampf(_toast_time, 0, 1)
		if _toast_time == 0:
			_toast.visible = false

func refresh(s: Dictionary) -> void:
	var kmh := roundi(s.speed * 3.6)
	var lim := roundi(s.limit * 3.6)
	var over: bool = s.speed > s.limit + 3.0 / 3.6
	var handle := "Coast"
	if s.emergency:
		handle = "[color=#ff7868]EMERGENCY BRAKE[/color]"
	elif s.controller > 0.001:
		handle = "Power %d%%" % roundi(s.controller * 100)
	elif s.controller < -0.001:
		handle = "Brake %d%%" % roundi(-s.controller * 100)
	var speed := "[b]%d[/b] km/h  ·  Limit %d" % [kmh, lim]
	if over:
		speed = "[color=#ff7868]" + speed + "  OVERSPEED[/color]"
	var signal_text := "No signal ahead"
	if not s.next_signal.is_empty():
		var aspects := ["[color=#ff7868]RED[/color]", "[color=#ffca72]YELLOW[/color]", "[color=#72e6be]GREEN[/color]"]
		signal_text = "%s  %s  ·  %d m" % [s.next_signal.id, aspects[s.next_aspect], roundi(s.next_signal.distance)]
	if s.buffer < 500.0:
		signal_text += "  ·  Buffer %d m" % roundi(s.buffer)
	_info.text = "%s   ·   %s\n%s   ·   %s / %s%s" % [speed, handle, signal_text, s.train_id, "AI" if s.automatic else "MANUAL", "  [color=#ffca72]PROTECTION OFF[/color]" if not s.protection else ""]
	var view := "CAB" if s.cab else "OVERVIEW"
	if not s.get("passenger", "").is_empty():
		view = s.passenger
	_mode.text = "%s  ·  D%d  %s  ·  ×%d" % [view, s.world_day, s.world_clock, s.time_scale]
	# Emergency feedback survives clean view; other diagnostics stay optional.
	if clean_view and s.emergency and modal == "":
		_info.text = "[color=#ff7868][b]EMERGENCY BRAKE[/b][/color]  ·  %d km/h\nSpace to release once stopped" % kmh
		_info.visible = true
	elif clean_view:
		_info.visible = false
