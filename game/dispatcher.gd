extends CanvasLayer
## Route desk and service roster; all safety decisions remain in the sim.

signal train_selected(id: String)
signal drive_requested
signal pause_requested
signal restart_requested
signal scenario_requested
signal lhb_requested
signal result_message(result: Dictionary, success: String)
const Map := preload("res://game/dispatch_map.gd")
const TimetableView := preload("res://game/timetable_view.gd")
var world: RailWorld
var selected_train := "T1"
var source := "CPM-S1"
var _root: Control
var _map: Control
var _source: OptionButton
var _exit: OptionButton
var _reason: Label
var _set: Button
var _cancel: Button
var _roster := {}
var _clock: Label
var _objective: Label
var _restart: Button
var _timer := 0.0
var _timetable: Control
var _table_button: Button
var _board_heading: Label
var _legend: Label
var _scenario_button: Button
var _lhb_button: Button
var timetable_open := false
var auto_dispatch := false
var hold_arrivals := false
var _auto_button: Button
var _hold_button: Button

func setup(w: RailWorld) -> void:
	world = w
	source = "CPM-E1" if world.signals.has("CPM-E1") else "CPM-S1"
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -356
	panel.offset_right = -16
	panel.offset_top = 184
	panel.offset_bottom = -16
	panel.add_theme_stylebox_override("panel", _panel_style())
	_root.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	_label(column, "SOUTHERN LINE  /  CONTROL", 15, Color("ffca72"))
	_clock = _label(column, "", 20)
	_label(column, "ROUTE DESK", 13, Color("95aeb7"))
	_source = OptionButton.new()
	for sid in world.signals:
		_source.add_item(sid)
	_style_button(_source)
	column.add_child(_source)
	_source.item_selected.connect(func(i): select_signal(_source.get_item_text(i), true))
	_exit = OptionButton.new()
	_style_button(_exit)
	column.add_child(_exit)
	_exit.item_selected.connect(func(_i): _refresh())
	var row := HBoxContainer.new()
	column.add_child(row)
	_set = _button(row, "SET ROUTE", func(): _set_route())
	_cancel = _button(row, "PUT TO RED", func():
		var result := world.set_signal(source, false)
		result_message.emit(result, "Signal at red; occupied / approach locks retained until safe")
		_refresh())
	_reason = _label(column, "", 14, Color("95aeb7"))
	_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reason.custom_minimum_size = Vector2(290, 36)
	_label(column, "SERVICES  /  SELECT TO FOLLOW", 13, Color("95aeb7"))
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.custom_minimum_size.y = 85
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var roster := VBoxContainer.new()
	roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(roster)
	for t in world.trains.values():
		var b := _button(roster, "", func(): train_selected.emit(t.id))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 45
		_roster[t.id] = b
	var controls := HBoxContainer.new()
	column.add_child(controls)
	_button(controls, "TAKE CAB  [Tab]", func(): drive_requested.emit())
	_button(controls, "AI / MANUAL  [A]", func(): toggle_driver())
	var scenarios := HBoxContainer.new()
	column.add_child(scenarios)
	var bottom := PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 16
	bottom.offset_right = -372
	bottom.offset_top = -480
	bottom.offset_bottom = -16
	bottom.add_theme_stylebox_override("panel", _panel_style())
	_root.add_child(bottom)
	var map_col := VBoxContainer.new()
	map_col.add_theme_constant_override("separation", 6)
	bottom.add_child(map_col)
	var title := HBoxContainer.new()
	map_col.add_child(title)
	_board_heading = _label(title, "DISPATCH BOARD", 17, Color("ffca72"))
	_board_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_legend = _label(title, "RED occupied    MINT reserved", 12, Color("adbec4"))
	_scenario_button = _button(scenarios, "MEMU [F2]" if world.trains.T1.stock_kind == "wap7" else "WAP-7 [F2]", func(): scenario_requested.emit())
	_scenario_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_scenario_button.tooltip_text = "Switch scenario and restart at Chennapuram"
	_lhb_button = _button(scenarios, "MEMU [F3]" if world.trains.T1.stock_kind == "lhb" else "LHB [F3]", func(): lhb_requested.emit())
	_lhb_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_lhb_button.tooltip_text = "Drive WAP-7 with 20 LHB coaches (500.562 m); V enters a passenger coach"
	_table_button = _button(title, "TIMETABLE [M]", toggle_timetable)
	_table_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_button(title, "CLOSE [D]", func(): set_open(false)).size_flags_horizontal = Control.SIZE_SHRINK_END
	_restart = _button(title, "RESTART SERVICES", func(): restart_requested.emit())
	_restart.size_flags_horizontal = Control.SIZE_SHRINK_END
	_restart.visible = false
	var scopes := HFlowContainer.new()
	map_col.add_child(scopes)
	_button(scopes, "WHOLE LINE", func(): _map.focus_station(-1))
	for index in world.stations.size():
		_button(scopes, world.stations[index].code + " YARD", func(): _map.focus_station(index))
	_auto_button = _button(scopes,"AUTO DISPATCH: OFF",func():
		auto_dispatch = not auto_dispatch
		_refresh())
	_auto_button.tooltip_text = "Requests safe routes to booked platforms. In the traffic scenario this includes your manually driven service. Switch off to dispatch routes yourself."
	_hold_button = _button(scopes,"HOLD MRT: OFF",func():
		hold_arrivals = not hold_arrivals
		_refresh())
	_hold_button.tooltip_text = "With auto dispatch, hold Maruthur departures to test all four platforms and queue following trains. Does not cancel routes already set."
	_map = Map.new()
	_map.world = world
	map_col.add_child(_map)
	_map.signal_selected.connect(func(id): select_signal(id))
	_map.destination_selected.connect(_select_destination)
	_map.train_selected.connect(func(id): train_selected.emit(id))
	_timetable = TimetableView.new()
	_timetable.world = world
	map_col.add_child(_timetable)
	_timetable.visible = false
	_objective = _label(map_col, "", 12, Color("d5e2e5"))
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	select_signal(source, true)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.062, 0.086, 0.96)
	style.border_color = Color("294553")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(16)
	return style

func _label(parent: Node, text: String, font_size: int, color: Color = Color("e2ecee")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _style_button(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color("e2ecee"))
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("213d49") if state in ["hover", "pressed"] else Color("122b37")
		style.border_color = Color("52dcc4") if state == "focus" else Color("36525d")
		style.set_border_width_all(1)
		style.set_corner_radius_all(5)
		style.set_content_margin_all(9)
		button.add_theme_stylebox_override(state, style)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	_style_button(button)
	parent.add_child(button)
	button.pressed.connect(action)
	return button

func select_signal(id: String, force: bool = false) -> void:
	if not force and id != source and world.signals[source].route.is_empty() and _map.destination != id:
		for option in world.route_options(source):
			if option.destination == id:
				_select_destination(id)
				return
	source = id
	for i in _source.item_count:
		if _source.get_item_text(i) == id:
			_source.select(i)
	_exit.clear()
	for option in world.route_options(source):
		_exit.add_item("TO  " + option.destination.replace("BUFFER:", "Platform / "))
		_exit.set_item_metadata(_exit.item_count - 1, option.destination)
	_refresh()

func _select_destination(id: String) -> void:
	for i in _exit.item_count:
		if _exit.get_item_metadata(i) == id:
			_exit.select(i)
			_refresh()
			return

func _set_route() -> void:
	if _exit.selected < 0:
		return
	var destination: String = _exit.get_item_metadata(_exit.selected)
	result_message.emit(world.set_route(source, destination), "Route set: %s → %s" % [source, destination])
	_refresh()

func toggle_driver() -> void:
	var t: Train = world.trains[selected_train]
	t.automatic = not t.automatic
	if not t.automatic:
		t.controller = 0.0
	_refresh()

func set_open(value: bool) -> void:
	_root.visible = value
	if not value:
		var focus := get_viewport().gui_get_focus_owner()
		if focus != null and _root.is_ancestor_of(focus): focus.release_focus()
		_source.get_popup().hide()
		_exit.get_popup().hide()

func toggle() -> void:
	set_open(not _root.visible)

func toggle_timetable() -> void:
	timetable_open = not timetable_open
	_root.visible = true
	_map.visible = not timetable_open
	_timetable.visible = timetable_open
	_legend.visible = not timetable_open
	_board_heading.text = "SERVICE TIMETABLE" if timetable_open else "DISPATCH BOARD"
	_table_button.text = "TRACK MAP [M]" if timetable_open else "TIMETABLE [M]"
	_refresh()

func _process(delta: float) -> void:
	_timer += delta
	if _timer > 0.15 and world != null:
		_timer = 0.0
		_refresh()

func _refresh() -> void:
	var target: String = _exit.get_item_metadata(_exit.selected) if _exit.selected >= 0 else ""
	var reason := world.route_reason(source, target)
	_set.disabled = reason != ""
	_cancel.disabled = world.signals[source].route.is_empty()
	if source in world.automatic_signals:
		_set.disabled = true
		_cancel.disabled = true
	var sig: Dictionary = world.signals[source]
	if not sig.route.is_empty():
		_reason.text = "%s → %s\n%s" % [source, sig.destination.replace("BUFFER:", ""), "Train " + sig.owner + " / tail release" if sig.owner != "" else ("Approach lock held" if sig.cancel_pending else "Route locked • signal " + ["RED", "YELLOW", "GREEN"][world.aspect(source)])]
	else:
		_reason.text = "Ready • points will align and lock" if reason == "" else reason
	if source in world.automatic_signals:
		_reason.text = "Automatic block signal • occupancy controls re-clearing; select a station home or starter for manual routing."
	_auto_button.text = "AUTO DISPATCH: " + ("ON" if auto_dispatch else "OFF")
	_hold_button.text = "HOLD MRT: " + ("ON" if hold_arrivals else "OFF")
	_clock.text = "%s  ·  D%d  ·  %d/%d" % [world.clock_text(), world.clock_day(), world.trains.values().filter(func(t): return t.service_complete).size(), world.trains.size()]
	for id in _roster:
		var t: Train = world.trains[id]
		_roster[id].text = "%s%s   %s   %d km/h\n%s · %s" % ["● " if id == selected_train else "", id, "AI" if t.automatic else "MANUAL", roundi(t.speed * 3.6), t.destination, t.status if t.automatic else "You have control"]
		_roster[id].clip_text = true
		_roster[id].tooltip_text = t.service_name + "\n" + t.status
	_map.selected = source
	_map.destination = target
	_map.queue_redraw()
	_timetable.refresh(selected_train)
	_objective.text = "SIX-TRAIN CORRIDOR · 21.64 km · 4 platform roads per station · Auto dispatch follows booked platforms; HOLD MRT queues arrivals. M timetable · D hide"
	if world.trains.T1.stock_kind == "wap7":
		_objective.text = "WAP-7 LIGHT ENGINE · Initial route to Maruthur P1. C opens onward routes; R changes cabs at a stand. F2 returns to the six MEMUs."
	elif world.trains.T1.stock_kind == "lhb":
		_objective.text = "SOUTHERN COAST AC SPECIAL · WAP-7 + 20 LHB · 500.562 m · C onward routes · V passenger · PgUp/PgDn coach · Home seat · B berths"
	if timetable_open:
		_objective.text = "AI waits for departure time, completes each block stop and dwell, then waits for a dispatcher route. Arrival / departure times use a 24-hour clock."
	_restart.visible = world.trains.values().all(func(t): return t.service_complete)
	if _restart.visible:
		_objective.text = "ARRIVED  •  Change ends with R, set the return routes and drive Cab 2, or restart the scenario." if world.trains.T1.stock_kind == "wap7" else "SERVICES COMPLETE  •  All services arrived. Restart the timetable, or select a train and change ends at a stand."
		if world.trains.T1.stock_kind == "lhb":
			_objective.text = "ARRIVED AT KADALUR  •  All 20 coaches are in the platform. Explore with V, or RESTART SERVICES. A locomotive run-round is required for a return working."
