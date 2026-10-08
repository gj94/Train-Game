extends CanvasLayer
## Paused service authoring; a draft and rehearsal never touch the running world.
signal closed
signal play_requested(pack: Dictionary, service_id: String)
const Pack := preload("res://sim/service_pack.gd")
const Trial := preload("res://sim/service_trial.gd")
const Stock := preload("res://sim/stock/ported_stock.gd")
const Clock := preload("res://sim/world_clock.gd")
var draft := {}
var layout := "southern_corridor"
var selected := 0
var stop_index := 0
var panel: Control
var pickers: Array[OptionButton] = []
var roster: ItemList
var stop_list: ItemList
var status: Label
var title_field: LineEdit
var clock_field: LineEdit
var world_day: SpinBox
var id_field: LineEdit
var name_field: LineEdit
var stock_field: OptionButton
var rake_field: OptionButton
var priority_field: SpinBox
var speed_field: SpinBox
var departure_field: LineEdit
var departure_day: SpinBox
var direction_field: OptionButton
var block_field: OptionButton
var stop_name: LineEdit
var offset_field: SpinBox
var dwell_field: SpinBox
var marker_field: LineEdit
var dialog: FileDialog
var confirm_play: ConfirmationDialog
var _loading := false
var _save_delay := -1.0
var _trial
var _tested_json := ""
var _pending_pack := {}
var _pending_service := ""
var save_path := "user://services-draft.json"
var _file_mode := ""
var _stock_choices := Stock.CHOICES

func _ready() -> void:
	layer = 12
	panel = PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 18; panel.offset_right = -18
	panel.offset_top = 18; panel.offset_bottom = -42
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0c202b")
	style.set_content_margin_all(16)
	style.set_border_width_all(1)
	style.border_color = Color("#476776")
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel",style)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation",10)
	panel.add_child(outer)
	var header := _row(outer)
	_label(header,"SERVICE DESIGNER",24).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(header,"Import…",func(): _choose_file("import"))
	_button(header,"Export…",func(): _choose_file("export"))
	_button(header,"Back / Esc",func(): closed.emit())
	_label(outer,"Design on this track layout. Select a service to drive; the others and dispatcher run automatically.",15)
	var settings := _row(outer)
	title_field = _line(settings,"Timetable name",func(v): draft.name=v; _changed())
	clock_field = _line(settings,"World start HH:MM",func(v): draft.world_start=v; _changed())
	world_day = _spin(settings,"Start day",1,365,1,func(v): draft.day=int(v); _changed())
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation",16)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 270
	columns.add_child(left)
	_label(left,"SERVICES · select one to edit / drive",15)
	roster = ItemList.new()
	roster.size_flags_vertical = Control.SIZE_EXPAND_FILL
	roster.custom_minimum_size.y = 90
	left.add_child(roster)
	roster.item_selected.connect(func(i): selected=i; stop_index=0; _load_service())
	var manage := _row(left)
	_button(manage,"Add",func(): _add_service(false))
	_button(manage,"Duplicate",func(): _add_service(true))
	_button(manage,"Remove",_remove_service)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	columns.add_child(scroll)
	var fields := VBoxContainer.new()
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields.add_theme_constant_override("separation",8)
	scroll.add_child(fields)
	var identity := _row(fields)
	id_field = _line(identity,"Service ID",func(v): _service().id=v; _changed())
	name_field = _line(identity,"Service name",func(v): _service().name=v; _changed())
	stock_field = _option(fields,"Rolling stock",func(i):
		_service().stock=_stock_choices[i]
		_service().rake=Stock.resolve_profile(_service().stock)
		_refresh_rakes()
		speed_field.value=minf(speed_field.value,_stock_speed())
		_changed())
	for choice in _stock_choices: stock_field.add_item(Stock.LABELS[choice])
	rake_field = _option(fields,"Rake · coaches exclude locomotive",func(i):
		_service().rake=rake_field.get_item_metadata(i)
		_changed())
	var dispatching:=_row(fields)
	priority_field=_spin(dispatching,"Dispatch priority · higher runs first",1,100,1,func(v):_service().priority=int(v);_changed())
	speed_field=_spin(dispatching,"Service speed cap · km/h",5,180,5,func(v):_service().speed_limit_kmh=v;_changed())
	var timing := _row(fields)
	departure_field = _line(timing,"Departure HH:MM[:SS]",func(v): _service().departure=v; _changed())
	departure_day = _spin(timing,"Day",1,365,1,func(v): _service().day=int(v); _changed())
	direction_field = _option(timing,"Running direction",func(i):
		for stop in _service().stops: stop.direction=1 if i==0 else -1
		_changed())
	direction_field.add_item("Eastbound (+1)")
	direction_field.add_item("Westbound (-1)")
	_label(fields,"STOPS · origin first, destination last · times are minutes after departure",15)
	stop_list = ItemList.new()
	stop_list.custom_minimum_size.y = 110
	fields.add_child(stop_list)
	stop_list.item_selected.connect(func(i): stop_index=i; _load_stop())
	var order := _row(fields)
	_button(order,"Add stop",_add_stop)
	_button(order,"Remove stop",_remove_stop)
	_button(order,"Move up",func(): _move_stop(-1))
	_button(order,"Move down",func(): _move_stop(1))
	var place := _row(fields)
	block_field = _option(place,"Platform / block",func(i):
		_stop().block=block_field.get_item_metadata(i)
		_stop().name=block_field.get_item_text(i)
		_stop().erase("position_m")
		_changed()
		_load_stop())
	stop_name = _line(place,"Stop name",func(v): _stop().name=v; _changed())
	var time_row := _row(fields)
	offset_field = _spin(time_row,"Arrival +min (origin = 0)",0,2880,.5,func(v): _stop().minutes_from_origin=v; _changed())
	dwell_field = _spin(time_row,"Dwell min",0,120,.5,func(v): _stop().dwell_minutes=v; _changed())
	marker_field = _line(fields,"Head marker, metres along block (blank = automatic)",func(v):
		if v.strip_edges().is_empty(): _stop().erase("position_m")
		else: _stop().position_m=float(v) if v.is_valid_float() else v
		_changed())
	var footer := _row(outer)
	_button(footer,"Validate",_validate)
	_button(footer,"Rehearse AI traffic",_test_traffic)
	_button(footer,"Play selected service…",_request_play).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status = _label(outer,"",15)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 48
	dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.json ; Train Game service timetable"])
	dialog.use_native_dialog = true
	add_child(dialog)
	dialog.file_selected.connect(func(path):
		if _file_mode == "import": import_file(path)
		else: export_file(path))
	confirm_play = ConfirmationDialog.new()
	confirm_play.title = "Start this timetable?"
	confirm_play.ok_button_text = "Start driving"
	add_child(confirm_play)
	confirm_play.confirmed.connect(func(): play_requested.emit(_pending_pack,_pending_service))
	hide()

func _row(parent: Node) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	parent.add_child(row)
	return row

func _label(parent: Node, text: String, font: int = 14) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",font)
	parent.add_child(label)
	return label

func _field(parent: Node, caption: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	_label(box,caption)
	return box

func _line(parent: Node, caption: String, change: Callable) -> LineEdit:
	var field := LineEdit.new()
	field.custom_minimum_size.y = 32
	_field(parent,caption).add_child(field)
	field.text_changed.connect(func(v): if not _loading: change.call(v))
	return field

func _spin(parent: Node, caption: String, low: float, high: float, step_size: float, change: Callable) -> SpinBox:
	var field := SpinBox.new()
	field.min_value=low; field.max_value=high; field.step=step_size
	_field(parent,caption).add_child(field)
	field.value_changed.connect(func(v): if not _loading: change.call(v))
	return field

func _option(parent: Node, caption: String, change: Callable) -> OptionButton:
	var field := OptionButton.new()
	field.custom_minimum_size.y = 32
	field.fit_to_longest_item = false
	_field(parent,caption).add_child(field)
	field.item_selected.connect(func(i): if not _loading: change.call(i))
	pickers.append(field)
	return field

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text=text
	button.custom_minimum_size.y=34
	parent.add_child(button)
	button.pressed.connect(action)
	return button

func open(world: RailWorld, active_pack: Dictionary = {}) -> void:
	layout = Pack.layout_id(world)
	if draft.is_empty() or draft.layout != layout:
		draft = active_pack.duplicate(true) if not active_pack.is_empty() else Pack.defaults(layout)
		if active_pack.is_empty() and FileAccess.file_exists(save_path):
			var saved := _read_file(save_path)
			if saved.ok: draft=saved.data
	block_field.clear()
	# Station roads first, then other graph blocks for special workings.
	var blocks: Array = []
	for station in world.stations:
		for block in station.get("platform_tracks",[]):
			if world.graph.edges.has(block) and block not in blocks: blocks.append(block)
	for block in world.graph.edges:
		if block not in blocks: blocks.append(block)
	for block in blocks:
		var label: String = block
		for station in world.stations:
			if block.to_upper().begins_with(station.code): label=station.name+(" (closed)" if not station.get("passenger_open",true) else "")+" · "+block; break
		block_field.add_item(label)
		block_field.set_item_metadata(block_field.item_count-1,block)
	selected = clampi(selected,0,draft.services.size()-1)
	stop_index=0
	_loading=true
	title_field.text=draft.name; clock_field.text=draft.world_start; world_day.value=draft.day
	_loading=false
	_refresh_roster()
	_load_service()
	_status("Drafts save locally when valid. Import/export shares definitions, not a running save. Rehearse to find traffic conflicts.")
	show()
	roster.grab_focus()

func _refresh_rakes() -> void:
	rake_field.clear()
	for profile in Stock.profiles(_service().stock):
		rake_field.add_item(Stock.RAKE_LABELS[profile])
		rake_field.set_item_metadata(rake_field.item_count-1,profile)
	rake_field.select(Stock.profiles(_service().stock).find(Stock.resolve_profile(_service().stock,_service().get("rake",""))))
	rake_field.disabled=rake_field.item_count==1

func _stock_speed() -> float:
	return 110.0 if _service().stock=="icf" else (140.0 if _service().stock=="lhb" else 180.0)

func _service() -> Dictionary:
	return draft.services[selected]

func _stop() -> Dictionary:
	return _service().stops[stop_index]

func _refresh_roster() -> void:
	roster.clear()
	for service in draft.services: roster.add_item(service.id+" · "+service.name)
	roster.select(selected)

func _refresh_stops() -> void:
	stop_list.clear()
	for i in _service().stops.size():
		var stop: Dictionary = _service().stops[i]
		var absolute := Clock.parse_time(_service().departure)
		var stamp := Clock.format_time(absolute+float(stop.minutes_from_origin)*60) if absolute>=0 else "?"
		stop_list.add_item("%d  %s  · %s  (+%.1f) · dwell %.1f" % [i+1,stop.block,stamp,stop.minutes_from_origin,stop.get("dwell_minutes",0)])
	stop_list.select(stop_index)

func _load_service() -> void:
	_loading=true
	var service := _service()
	id_field.text=service.id; name_field.text=service.name
	stock_field.select(_stock_choices.find(service.stock))
	_refresh_rakes()
	priority_field.value=service.get("priority",50)
	speed_field.value=service.get("speed_limit_kmh",_stock_speed())
	departure_field.text=service.departure
	departure_day.value=service.get("day",1)
	direction_field.select(0 if service.stops[0].direction==1 else 1)
	stop_index=clampi(stop_index,0,service.stops.size()-1)
	_loading=false
	_refresh_stops()
	_load_stop()

func _load_stop() -> void:
	_loading=true
	var stop := _stop()
	for i in block_field.item_count:
		if block_field.get_item_metadata(i)==stop.block: block_field.select(i); break
	stop_name.text=stop.get("name",stop.block)
	offset_field.value=stop.minutes_from_origin
	dwell_field.value=stop.get("dwell_minutes",0)
	marker_field.text=str(stop.position_m) if stop.has("position_m") else ""
	_loading=false

func _changed() -> void:
	_trial=null
	_tested_json=""
	_save_delay=.8
	_refresh_roster()
	_refresh_stops()
	_status("Draft changed. Validate or rehearse before playing.")

func _add_service(duplicate: bool) -> void:
	if draft.services.size() >= Pack.MAX_SERVICES:
		_status("Maximum %d services for this layout." % Pack.MAX_SERVICES,true); return
	var service: Dictionary = _service().duplicate(true) if duplicate else Pack.defaults(layout).services[0].duplicate(true)
	var used: Array = draft.services.map(func(s): return s.id)
	var index := 1
	while "S%d" % index in used: index+=1
	service.id="S%d" % index
	service.name="Service "+service.id
	service.departure=draft.world_start
	service.day=draft.day
	draft.services.append(service)
	selected=draft.services.size()-1; stop_index=0
	_changed()
	_load_service()
	_status("New service: choose a FREE origin platform and its booked stops. Every train is placed at world start.")

func _remove_service() -> void:
	if draft.services.size()==1:
		_status("Keep at least one service.",true); return
	draft.services.remove_at(selected)
	selected=mini(selected,draft.services.size()-1); stop_index=0
	_changed(); _load_service()

func _add_stop() -> void:
	if _service().stops.size()>=64: return
	var stop: Dictionary = _service().stops[-1].duplicate(true)
	stop.minutes_from_origin+=15
	stop.dwell_minutes=0
	_service().stops.append(stop)
	stop_index=_service().stops.size()-1
	_changed(); _load_stop()
	_status("Select the new destination platform. The previous destination is now an intermediate stop.")

func _remove_stop() -> void:
	if _service().stops.size()<=2:
		_status("A service needs an origin and destination.",true); return
	_service().stops.remove_at(stop_index)
	stop_index=mini(stop_index,_service().stops.size()-1)
	_changed(); _load_stop()

func _move_stop(step: int) -> void:
	var next := stop_index+step
	if next<0 or next>=_service().stops.size(): return
	var value: Dictionary = _service().stops.pop_at(stop_index)
	_service().stops.insert(next,value)
	stop_index=next
	_changed(); _load_stop()

func _status(message: String, error: bool = false) -> void:
	status.text=message
	status.modulate=Color("#ffb29e") if error else Color("#b8dddf")

func _validate() -> void:
	var result := Pack.build(draft,layout)
	_status("Valid stock, stops, forward routes and starting positions. Rehearse AI traffic to check the whole timetable." if result.ok else result.reason,not result.ok)
	if result.ok: _save_draft()

func _save_draft() -> void:
	if not Pack.build(draft,layout).ok: return
	var error := _write_file(save_path,draft)
	if error != OK: _status("Could not save local draft: "+error_string(error),true)

func _read_file(path: String) -> Dictionary:
	var file := FileAccess.open(path,FileAccess.READ)
	if file==null: return {ok=false,reason="Cannot open file: "+error_string(FileAccess.get_open_error())}
	if file.get_length()>Pack.MAX_BYTES: return {ok=false,reason="Service file exceeds 256 KiB"}
	return Pack.decode(file.get_as_text(),layout)

func _write_file(path: String, data: Dictionary) -> Error:
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data,"\t")+"\n")
	file.flush()
	return file.get_error()

func import_file(path: String) -> bool:
	var result := _read_file(path)
	if not result.ok:
		_status("Import rejected. "+result.reason,true)
		return false
	draft=result.data
	selected=0; stop_index=0; _trial=null; _tested_json=""
	_loading=true
	title_field.text=draft.name; clock_field.text=draft.world_start; world_day.value=draft.get("day",1)
	_loading=false
	_refresh_roster(); _load_service(); _save_draft()
	_status("Imported "+path+". Rehearse before playing.")
	return true

func export_file(path: String) -> bool:
	var result := Pack.build(draft,layout)
	if not result.ok:
		_status("Export needs a valid timetable: "+result.reason,true); return false
	if path.get_extension().to_lower()!="json": path+=".json"
	var error := _write_file(path,draft)
	_status("Exported "+path if error==OK else "Export failed: "+error_string(error),error!=OK)
	return error==OK

func _choose_file(mode: String) -> void:
	if mode=="export":
		var result := Pack.build(draft,layout)
		if not result.ok: _status(result.reason,true); return
	_file_mode=mode
	dialog.file_mode=FileDialog.FILE_MODE_OPEN_FILE if mode=="import" else FileDialog.FILE_MODE_SAVE_FILE
	dialog.title="Import services for this layout" if mode=="import" else "Export service timetable"
	dialog.current_file="" if mode=="import" else "train-services.json"
	dialog.popup_centered_ratio(.75)

func _test_traffic() -> void:
	if _trial!=null:
		_trial=null; _status("Rehearsal cancelled."); return
	var result := Pack.build(draft,layout)
	if not result.ok: _status(result.reason,true); return
	_trial=Trial.new(result.world)
	_status("Rehearsing all services with AI and auto dispatch… click Rehearse again to cancel.")

func _request_play() -> void:
	var result := Pack.build(draft,layout)
	if not result.ok: _status(result.reason,true); return
	_pending_pack=result.data
	_pending_service=_service().id
	_save_draft()
	confirm_play.dialog_text="Drive "+_service().id+" · "+_service().name+"\nOther services: AI. Dispatcher: automatic.\n\nThis starts at the timetable's world start and replaces the current run.\n"+("AI rehearsal passed." if _tested_json==JSON.stringify(draft) else "This draft has not passed an AI rehearsal; traffic may block.")
	confirm_play.popup_centered(Vector2i(640,230))

func dismiss() -> void:
	_trial=null
	_save_draft()
	hide()

func _process(delta: float) -> void:
	if not visible: return
	if _save_delay>=0:
		_save_delay-=delta
		if _save_delay<0: _save_draft()
	if _trial==null: return
	var until := Time.get_ticks_usec()+4000
	while Time.get_ticks_usec()<until and not _trial.done: _trial.step()
	if _trial.done:
		_status(_trial.report,not _trial.ok)
		if _trial.ok: _tested_json=JSON.stringify(draft)
		_trial=null
	else:
		_status("AI rehearsal · "+_trial.world.clock_text()+" · %d/%d arrived · click Rehearse to cancel" % [_trial.world.trains.values().filter(func(t): return t.service_complete).size(),draft.services.size()])
