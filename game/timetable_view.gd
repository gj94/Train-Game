extends VBoxContainer
## A read-only view of the selected service's planned and actual working.
const Clock := preload("res://sim/world_clock.gd")
var world: RailWorld
var _title: Label
var _table: Tree
var _items: Array[TreeItem] = []
var _current_schedule = null

func _ready() -> void:
	custom_minimum_size.y = 190
	add_theme_constant_override("separation", 5)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 15)
	_title.add_theme_color_override("font_color", Color("ffca72"))
	add_child(_title)
	_table = Tree.new()
	_table.columns = 8
	_table.hide_root = true
	_table.column_titles_visible = true
	_table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_table.custom_minimum_size.y = 152
	_table.focus_mode = Control.FOCUS_NONE
	_table.mouse_filter = Control.MOUSE_FILTER_STOP
	_table.add_theme_font_size_override("font_size", 15)
	_table.add_theme_font_size_override("title_button_font_size", 14)
	_table.add_theme_color_override("font_color", Color("d5e2e5"))
	var background := StyleBoxFlat.new()
	background.bg_color = Color("0d222c")
	background.set_corner_radius_all(5)
	_table.add_theme_stylebox_override("panel", background)
	var titles := ["Stop", "Block", "From origin", "Arrival", "Departure", "Dwell", "Actual", "Status"]
	var widths := [145, 140, 95, 115, 115, 80, 230, 155]
	for i in titles.size():
		_table.set_column_title(i, titles[i])
		_table.set_column_custom_minimum_width(i, widths[i])
		_table.set_column_expand(i, true)
	add_child(_table)

func refresh(train_id: String) -> void:
	if world == null or _table == null:
		return
	var train: Train = world.trains[train_id]
	var tt = train.timetable
	if tt != _current_schedule:
		_table.clear()
		_items.clear()
		_current_schedule = tt
		if tt != null:
			var root := _table.create_item()
			for stop in tt.stops:
				var item := _table.create_item(root)
				item.set_text(0, stop.name)
				item.set_text(1, stop.block)
				item.set_text(2, "+%s min" % _minutes(stop.minutes_from_origin))
				item.set_text(5, "%s min" % _minutes(stop.dwell_minutes))
				_items.append(item)
	if tt == null:
		_title.text = train_id + " · Unscheduled movement"
		return
	_title.text = "%s  /  %s  ·  Origin %s  ·  Offsets use the scheduled departure" % [train_id, train.service_name, Clock.stamp(tt.departure)]
	for i in tt.stops.size():
		var item: TreeItem = _items[i]
		item.set_text(3, "—" if i == 0 else _stamp(tt.planned_arrival(i), tt.departure))
		item.set_text(4, "—" if i == tt.stops.size() - 1 else _stamp(tt.planned_departure(i), tt.departure))
		var actual: Array[String] = []
		if tt.actual_arrivals[i] >= 0:
			actual.append("A " + _stamp(tt.actual_arrivals[i], tt.departure))
		if tt.actual_departures[i] >= 0:
			actual.append("D " + _stamp(tt.actual_departures[i], tt.departure))
		item.set_text(6, " / ".join(actual) if not actual.is_empty() else "—")
		item.set_text(7, tt.row_status(i, world.clock_seconds()))
		for column in 8:
			item.set_custom_color(column, Color("ffca72") if i == tt.index else Color("d5e2e5"))
			item.set_tooltip_text(column, "%s / %s\nDue %s\n%s" % [tt.stops[i].name, tt.stops[i].block, Clock.stamp(tt.planned_arrival(i)), item.get_text(7)])

func _stamp(seconds: float, origin: float) -> String:
	var extra_days := Clock.day(seconds) - Clock.day(origin)
	return Clock.format_time(seconds) + (" +%dd" % extra_days if extra_days != 0 else "")

func _minutes(value: float) -> String:
	return str(int(value)) if value == floorf(value) else String.num(value, 2)
