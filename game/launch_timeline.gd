extends Control
## Browse a frozen baseline railway; preview has no authority-changing actions.
const Times:=preload("res://persistence/railway_times.gd")
const Briefing:=preload("res://persistence/service_briefing.gd")
const UI:=preload("res://game/dispatch_theme.gd")
var directory:=Times.DIRECTORY
var dispatcher_mode:="classic"
var states: Array=[]
var world: RailWorld
var requested:=0
var loaded_index:=-1
var loading_index:=-1
var worker: Thread
var closing:=false
var quitting:=false
var entering:=false
var debounce:=0.0
var slider: HSlider
var clock_label: Label
var status: Label
var station_picker: OptionButton
var roster: ItemList
var map
var map_host: VBoxContainer
var detail: Label
var footer: Label
var version_label: Label
var board_button: Button
var passenger_button: Button
var visit_button: Button
var services: Array=[]
var selected_id:="K1"
var station_index:=0
var _pan:=Vector2.ZERO
var _zoom:=0.0
var _triggers:=Vector2.ZERO
var _focused:=true
var shown_services: Array=[]
var nearby_only:=false
var all_button: Button
var nearby_button: Button
var roster_title: Label
var retry_button: Button
var picker_input:=preload("res://game/menu_picker_input.gd").new()
var _nav_direction:=Vector2i.ZERO
var _nav_repeat:=0.0
var _station_spots:={}
var display:=preload("res://game/display_options.gd").new()

func _ready() -> void:
	picker_input.use_explicit_controller_navigation()
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	Engine.max_fps=60;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;get_tree().auto_accept_quit=false
	Input.joy_connection_changed.connect(func(_device,_connected):_pan=Vector2.ZERO;_zoom=0;_triggers=Vector2.ZERO;picker_input.reset())
	dispatcher_mode=preload("res://persistence/operating_days.gd").definition(str(get_tree().get_meta("timetable_id","standard"))).dispatcher
	if directory==Times.DIRECTORY:
		directory=preload("res://persistence/operating_days.gd").definition(str(get_tree().get_meta("timetable_id","standard"))).times
	_build()
	picker_input.connect_pickers([station_picker])
	_load_catalogue()

func _load_catalogue() -> void:
	var catalogue:=Times.catalogue(directory)
	if not catalogue.ok:_load_error(catalogue.reason);slider.editable=false;return
	if catalogue.data.get("dispatcher","classic")!=dispatcher_mode:_load_error("This operating day needs matching dispatcher data. Update the game.");slider.editable=false;return
	slider.editable=true
	states=catalogue.data.states;slider.max_value=states.size()-1
	var remembered: int=get_tree().get_meta("timeline_index",0)
	if get_tree().has_meta("timeline_clock"):
		var clock: float=get_tree().get_meta("timeline_clock");get_tree().remove_meta("timeline_clock")
		for i in states.size():
			if absf(states[i].clock-clock)<.01:remembered=i;break
	choose(clampi(remembered,0,states.size()-1));slider.grab_focus()

func _build() -> void:
	theme=preload("res://game/menu_theme.gd").theme()
	var bg:=ColorRect.new();bg.color=Color("0b1119");add_child(bg);bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var margin:=MarginContainer.new();add_child(margin);margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,24)
	var body:=VBoxContainer.new();body.add_theme_constant_override("separation",16);margin.add_child(body)
	var header:=HBoxContainer.new();body.add_child(header)
	var brand:=UI.label(header,"EXPLORE · "+preload("res://persistence/operating_days.gd").definition(str(get_tree().get_meta("timetable_id","standard"))).name,24);brand.size_flags_horizontal=SIZE_EXPAND_FILL
	UI.button(header,"Back to departures",_back).size_flags_horizontal=SIZE_SHRINK_CENTER
	UI.button(header,"Fullscreen",func():display.toggle()).size_flags_horizontal=SIZE_SHRINK_CENTER
	UI.label(body,"Choose a time, inspect the dispatcher, then join a train or a station. Each start is a new journey from the AI-run baseline.",17,UI.MUTED)
	var time_bar:=HBoxContainer.new();time_bar.add_theme_constant_override("separation",12);body.add_child(time_bar)
	UI.button(time_bar,"−30m",func():choose(requested-6)).size_flags_horizontal=SIZE_SHRINK_CENTER
	UI.button(time_bar,"−5m",func():choose(requested-1)).size_flags_horizontal=SIZE_SHRINK_CENTER
	slider=HSlider.new();slider.size_flags_horizontal=SIZE_EXPAND_FILL;slider.step=1;slider.custom_minimum_size.x=200;time_bar.add_child(slider)
	slider.value_changed.connect(func(value):choose(int(value)))
	UI.button(time_bar,"+5m",func():choose(requested+1)).size_flags_horizontal=SIZE_SHRINK_CENTER
	UI.button(time_bar,"+30m",func():choose(requested+6)).size_flags_horizontal=SIZE_SHRINK_CENTER
	clock_label=UI.label(time_bar,"Loading timeline",24,UI.MINT)
	var tools_row:=HBoxContainer.new();tools_row.add_theme_constant_override("separation",10);body.add_child(tools_row)
	station_picker=OptionButton.new();UI.style_button(station_picker);station_picker.custom_minimum_size.x=320;station_picker.clip_text=true;tools_row.add_child(station_picker)
	station_picker.item_selected.connect(_station)
	UI.button(tools_row,"Station",func():if map!=null:map.focus_station(station_index))
	UI.button(tools_row,"Full route",func():if map!=null:map.focus_station(-1))
	UI.button(tools_row,"−",func():if map!=null:map.zoom_at(1.0/1.5))
	UI.button(tools_row,"+",func():if map!=null:map.zoom_at(1.5))
	var columns:=HBoxContainer.new();columns.size_flags_vertical=SIZE_EXPAND_FILL;columns.add_theme_constant_override("separation",18);body.add_child(columns)
	var list_column:=VBoxContainer.new();list_column.custom_minimum_size.x=340;columns.add_child(list_column)
	roster_title=UI.label(list_column,"ACTIVE PASSENGER SERVICES",14,UI.MINT)
	var service_filters:=HBoxContainer.new();service_filters.add_theme_constant_override("separation",8);list_column.add_child(service_filters)
	all_button=UI.button(service_filters,"All active",func():filter_services(false));all_button.toggle_mode=true;all_button.set_pressed_no_signal(true)
	nearby_button=UI.button(service_filters,"Near station · 15 km",func():filter_services(true));nearby_button.toggle_mode=true
	for button in [all_button,nearby_button]:button.add_theme_font_size_override("font_size",14);button.custom_minimum_size.y=32
	roster=ItemList.new();roster.size_flags_vertical=SIZE_EXPAND_FILL;roster.add_theme_font_size_override("font_size",17);roster.add_theme_constant_override("v_separation",12);list_column.add_child(roster)
	roster.item_selected.connect(func(index):_select_train(shown_services[index].id))
	roster.item_activated.connect(func(_index):board_button.grab_focus())
	map_host=VBoxContainer.new();map_host.clip_contents=true;map_host.size_flags_horizontal=SIZE_EXPAND_FILL;columns.add_child(map_host)
	UI.label(map_host,"DISPATCH PREVIEW · paused baseline · occupied sections, signals and routes",15,UI.MINT)
	detail=UI.label(body,"",17);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",18);body.add_child(actions)
	board_button=UI.button(actions,"Pilot seat · AI driving",_board);board_button.size_flags_horizontal=SIZE_EXPAND_FILL;board_button.custom_minimum_size.y=54
	var primary:=UI.panel("#265e4a");primary.border_color=UI.MINT;board_button.add_theme_stylebox_override("normal",primary)
	passenger_button=UI.button(actions,"Passenger seat",func():_board(true));passenger_button.size_flags_horizontal=SIZE_EXPAND_FILL
	visit_button=UI.button(actions,"Visit station platform",_visit);visit_button.size_flags_horizontal=SIZE_EXPAND_FILL
	var status_row:=HBoxContainer.new();body.add_child(status_row)
	status=UI.label(status_row,"",15,UI.AMBER);status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.size_flags_horizontal=SIZE_EXPAND_FILL
	retry_button=UI.button(status_row,"Retry preview",retry);retry_button.size_flags_horizontal=SIZE_SHRINK_END;retry_button.hide()
	footer=UI.label(body,"LB/RB ±5 min · A select · B back · LS navigate / pan map · LT/RT zoom · X locate · Y fit · F11 fullscreen",14,UI.MUTED)
	footer.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	version_label=UI.label(body,preload("res://game/build_version.gd").current(),12,UI.MUTED)
	board_button.disabled=true;passenger_button.disabled=true;visit_button.disabled=true;station_picker.disabled=true
	resized.connect(_fit.bind(margin,body));_fit(margin,body)

func _fit(margin: MarginContainer,body: VBoxContainer) -> void:
	var compact:=size.y<800
	body.add_theme_constant_override("separation",6 if compact else 16)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,(14 if side in ["top","bottom"] else 18) if compact else 24)
	board_button.custom_minimum_size.y=46 if compact else 54

func choose(index: int) -> void:
	if states.is_empty() or entering or closing:return
	requested=clampi(index,0,states.size()-1);slider.set_value_no_signal(requested)
	get_tree().set_meta("timeline_index",requested)
	clock_label.text=Briefing.time_text(states[requested].clock)
	board_button.disabled=true;passenger_button.disabled=true;visit_button.disabled=true;roster.mouse_filter=MOUSE_FILTER_IGNORE
	roster.clear();shown_services.clear();detail.text="Preparing the railway preview…";retry_button.hide();station_picker.disabled=true
	roster_title.text="LOADING SERVICES…";board_button.text="Loading services…";passenger_button.text="Passenger seat";visit_button.text="Station platform"
	if map!=null:map.hide()
	status.text="Loading the railway at "+clock_label.text+"…";debounce=.16
	if worker==null and loaded_index==requested:
		if world!=null:_show_world(world)
		else:loaded_index=-1

func _read(row: Dictionary) -> Dictionary:
	var result:=Times.load_state(row,directory)
	if result.ok:
		if result.world.dispatcher().predictive.enabled!=(dispatcher_mode=="predictive"):return {ok=false,reason="Prepared time uses a different dispatcher. Update the game."}
	return result

func _process(delta: float) -> void:
	if entering:return
	if picker_input.update(delta,[station_picker]):_pan=Vector2.ZERO;_zoom=0;_triggers=Vector2.ZERO
	if worker!=null and not worker.is_alive():
		var result: Dictionary=worker.wait_to_finish();worker=null
		if closing:_leave();return
		if loading_index==requested:
			if result.ok:loaded_index=requested;_show_world(result.world)
			else:_load_error(result.reason)
		elif loaded_index==requested and world!=null:_show_world(world)
	if closing and worker==null:_leave();return
	if worker==null and loaded_index!=requested and not states.is_empty():
		debounce-=delta
		if debounce<=0:
			loading_index=requested;worker=Thread.new()
			var error:=worker.start(_read.bind(states[requested].duplicate(true)))
			if error!=OK:worker=null;_load_error("Could not load timeline: "+error_string(error))
	if _focused and map!=null and map.visible and map.has_focus():
		if _pan.length()>.25:map.pan_pixels(-_pan*delta*650)
		if absf(_zoom)>.1:map.zoom_at(pow(2.0,_zoom*delta*1.5))
		_nav_direction=Vector2i.ZERO;_nav_repeat=0
	elif _focused:
		var direction:=Vector2i(0,signi(roundi(_pan.y))) if absf(_pan.y)>=absf(_pan.x) else Vector2i(signi(roundi(_pan.x)),0)
		if direction==Vector2i.ZERO:_nav_direction=direction;_nav_repeat=0
		else:
			_nav_repeat-=delta
			if direction!=_nav_direction or _nav_repeat<=0:
				_navigate(direction);_nav_repeat=.35 if direction!=_nav_direction else .13;_nav_direction=direction

func retry() -> void:
	if worker!=null or entering or closing:return
	loaded_index=-1
	if states.is_empty():_load_catalogue()
	else:choose(requested)

func _load_error(reason: String) -> void:
	loaded_index=requested;world=null;services.clear();shown_services.clear();roster.clear()
	board_button.disabled=true;passenger_button.disabled=true;visit_button.disabled=true
	roster.mouse_filter=MOUSE_FILTER_IGNORE;station_picker.disabled=true
	if map!=null:map.hide()
	status.text=reason;retry_button.show();roster_title.text="PREVIEW UNAVAILABLE";board_button.text="Preview unavailable"
	detail.text="The selected railway preview could not be opened. Retry, choose another time, or return to departures."

func _show_world(value: RailWorld) -> void:
	if map!=null:map_host.remove_child(map);map.queue_free();map=null
	world=value
	services=Times.available(world);services.sort_custom(func(a,b):return a.id.naturalnocasecmp_to(b.id)<0)
	_station_spots.clear();retry_button.hide();station_picker.disabled=false
	station_picker.clear()
	for station in world.stations:station_picker.add_item(station.code+" · "+station.name)
	station_index=clampi(station_index,0,world.stations.size()-1);station_picker.select(station_index)
	map=preload("res://game/dispatch_canvas.gd").new();map.clip_contents=true;map.world=world;map_host.add_child(map)
	map.train_selected.connect(_select_train);map.station_selected.connect(_station)
	map.signal_selected.connect(func(id):
		var signal_state: Dictionary=world.signals[id]
		status.text="Signal %s · %s · %s" % [id,["RED","YELLOW","GREEN"][world.aspect(id)],("Route to "+signal_state.destination) if not signal_state.destination.is_empty() else "No route set"])
	map.focus_station(station_index)
	_refresh_services()
	_update_visit()

func filter_services(nearby: bool) -> void:
	nearby_only=nearby
	all_button.set_pressed_no_signal(not nearby);nearby_button.set_pressed_no_signal(nearby)
	if world!=null and loaded_index==requested and worker==null:_refresh_services()

func _station_distance(train: Train) -> float:
	var edge: Dictionary=world.graph.edges[train.path[0].edge]
	var from: float=edge.get("chainage_start",world.graph.nodes[edge.a].pos.x)
	var to: float=edge.get("chainage_end",world.graph.nodes[edge.b].pos.x)
	var station: Dictionary=world.stations[station_index]
	return absf(lerpf(from,to,train.head_s/edge.length)-float(station.get("s",station.origin.x)))

func _refresh_services() -> void:
	roster.clear();roster.mouse_filter=MOUSE_FILTER_STOP
	shown_services=services.filter(func(t):return not nearby_only or _station_distance(t)<=15000)
	if nearby_only:shown_services.sort_custom(func(a,b):return _station_distance(a)<_station_distance(b))
	roster_title.text=("NEAR "+world.stations[station_index].code if nearby_only else "ACTIVE PASSENGER SERVICES")+" · %d" % shown_services.size()
	for train: Train in shown_services:
		var text: String=train.id+" · "+train.service_name
		if nearby_only:text="%s · %.1f km · %s" % [train.id,_station_distance(train)/1000,train.service_name]
		var index:=roster.add_item(text);roster.set_item_tooltip(index,text)
	var matches:=shown_services.filter(func(t):return t.id==selected_id)
	if not matches.is_empty():_select_train(selected_id,false)
	elif not shown_services.is_empty():_select_train(shown_services[0].id,false)
	else:
		selected_id="";board_button.disabled=true;passenger_button.disabled=true
		map.inspected_train="";map.queue_redraw()
		board_button.text="No nearby service" if nearby_only else "No active service";passenger_button.text="Passenger seat"
		detail.text="No active passenger services within 15 km along the route. Choose All active, another station or another time." if nearby_only else "No passenger services are active at this time. Visit a station to watch the railway."
	status.text="%d shown · %d active passenger services · %d total services · Select a train to inspect before boarding." % [shown_services.size(),services.size(),world.trains.size()]

func _station(index: int) -> void:
	if world==null or index<0 or index>=world.stations.size():return
	station_index=index;station_picker.select(index)
	if nearby_only:_refresh_services()
	if map!=null:map.focus_station(index)
	_update_visit()

func _update_visit() -> void:
	visit_button.disabled=world==null or worker!=null or loaded_index!=requested
	if world==null:return
	if not _station_spots.has(station_index):_station_spots[station_index]=Times.station_spot(world,station_index)
	var available: bool=not _station_spots[station_index].is_empty()
	visit_button.disabled=visit_button.disabled or not available
	visit_button.text="Visit "+world.stations[station_index].name+" platform" if available else "No accessible passenger platform"
	visit_button.tooltip_text="Start on the selected station's platform" if available else world.stations[station_index].name+" has no accessible passenger platform in this map."

func _select_train(id: String,focus: bool=true) -> void:
	if world==null or worker!=null or loaded_index!=requested or not services.any(func(t):return t.id==id):return
	selected_id=id
	if not shown_services.any(func(t):return t.id==id):filter_services(false)
	for i in shown_services.size():
		if shown_services[i].id==id:roster.select(i);roster.ensure_current_is_visible();break
	var train: Train=world.trains[id]
	var info:=preload("res://sim/service_progress.gd").snapshot(world,train)
	# Waiting advice describes a stopped train. A moving train may already be
	# inside its cleared destination road, where no further entry route is needed.
	var advice: String=info.get("waiting","") if train.speed<.15 else ""
	detail.text="%s · %s · %.0f km/h\nNext: %s · booked %s%s" % [id,train.service_name,train.speed*3.6,info.get("next_name",train.timetable.stops[-1].name),Briefing.time_text(info.get("scheduled_arrival",world.clock_seconds())),("\n"+advice) if not advice.is_empty() else ""]
	board_button.text=id+" · Pilot seat (AI)";board_button.disabled=worker!=null or loaded_index!=requested
	passenger_button.text=id+" · Passenger seat";passenger_button.disabled=board_button.disabled
	passenger_button.tooltip_text="Board a passenger carriage with AI driving. Starts paused; your seat is remembered for Hold R3."
	map.inspected_train=id
	if focus:map.focus_train(id)
	else:map.queue_redraw()

func _board(passenger: bool=false) -> void:
	if board_button.disabled or (passenger and passenger_button.disabled) or world==null:return
	_enter({service=selected_id,mode="ride",passenger_start=passenger})

func _visit() -> void:
	if visit_button.disabled or world==null:return
	var spot:=Times.station_spot(world,station_index)
	if spot.is_empty():status.text="This station has no accessible passenger platform in the current map.";return
	var nearest: Array=services.duplicate()
	var origin: Vector3=world.stations[station_index].origin
	nearest.sort_custom(func(a,b):return world.graph.position(a.path[0].edge,a.head_s).distance_squared_to(origin)<world.graph.position(b.path[0].edge,b.head_s).distance_squared_to(origin))
	var candidate: String=nearest[0].id if not nearest.is_empty() else str(world.trains.keys()[0])
	_enter({service=candidate,mode="station",station=station_index,spot=spot})

func _enter(choice: Dictionary) -> void:
	if worker!=null or loaded_index!=requested or closing:return
	entering=true;board_button.disabled=true;passenger_button.disabled=true;visit_button.disabled=true
	# Keep the exact AI controls, speeds and reservations in both entry modes.
	choice.world=world;choice.timeline=states[requested].id
	preload("res://persistence/operating_days.gd").stage_start(get_tree(),choice)
	get_tree().change_scene_to_file.call_deferred("res://game/main.tscn")

func _back() -> void:
	if entering:return
	closing=true;status.text="Finishing the current read…"

func _leave() -> void:
	if quitting:get_tree().quit()
	else:get_tree().change_scene_to_file.call_deferred("res://game/launch.tscn");entering=true

func _input(event: InputEvent) -> void:
	if not _focused or entering:return
	if picker_input.handle(event,[station_picker]):accept_event();return
	if picker_input.active([station_picker])!=null:return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:_back();accept_event()
		elif event.keycode==KEY_F11 or (event.keycode==KEY_ENTER and event.alt_pressed):display.toggle();accept_event()
	if event is InputEventJoypadMotion:
		if event.axis==JOY_AXIS_LEFT_X:_pan.x=event.axis_value
		if event.axis==JOY_AXIS_LEFT_Y:_pan.y=event.axis_value
		if event.axis==JOY_AXIS_TRIGGER_LEFT:_triggers.x=maxf(0,event.axis_value)
		if event.axis==JOY_AXIS_TRIGGER_RIGHT:_triggers.y=maxf(0,event.axis_value)
		_zoom=_triggers.y-_triggers.x
		accept_event()
	if not event is InputEventJoypadButton or not event.pressed:return
	match event.button_index:
		JOY_BUTTON_B:_back();accept_event()
		JOY_BUTTON_LEFT_SHOULDER:choose(requested-1);accept_event()
		JOY_BUTTON_RIGHT_SHOULDER:choose(requested+1);accept_event()
		JOY_BUTTON_Y:
			if map!=null:map.focus_station(-1)
			accept_event()
		JOY_BUTTON_X:
			if map!=null and not selected_id.is_empty():map.focus_train(selected_id)
			accept_event()
		JOY_BUTTON_A:
			var focus:=get_viewport().gui_get_focus_owner()
			if focus==station_picker:station_picker.show_popup();accept_event()
			elif focus==roster:
				if not board_button.disabled:board_button.grab_focus()
				accept_event()
			elif focus==map and map!=null:map.activate_focus();accept_event()
			elif focus is Button and not focus.disabled:focus.pressed.emit();accept_event()
		JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT,JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN:
			var directions:={JOY_BUTTON_DPAD_LEFT:Vector2i.LEFT,JOY_BUTTON_DPAD_RIGHT:Vector2i.RIGHT,JOY_BUTTON_DPAD_UP:Vector2i.UP,JOY_BUTTON_DPAD_DOWN:Vector2i.DOWN}
			_navigate(directions[event.button_index]);accept_event()

func _navigate(direction: Vector2i) -> void:
	var focus:=get_viewport().gui_get_focus_owner()
	if focus==null:slider.grab_focus();return
	if focus==slider and direction.x!=0:choose(requested+direction.x);return
	if focus==roster:
		if direction.x>0 and map!=null and map.visible:map.grab_focus();_pan=Vector2.ZERO;return
		if direction.y!=0:
			var indices:=roster.get_selected_items();var index: int=(indices[0] if not indices.is_empty() else 0)+direction.y
			if index<0:nearby_button.grab_focus();return
			if index>=shown_services.size():
				if not board_button.disabled:board_button.grab_focus()
				else:visit_button.grab_focus() if not visit_button.disabled else slider.grab_focus()
				return
			roster.select(index);_select_train(shown_services[index].id);roster.ensure_current_is_visible();return
	if map!=null and map.has_focus():
		if direction==Vector2i.UP:station_picker.grab_focus()
		elif direction==Vector2i.DOWN:
			if not board_button.disabled:board_button.grab_focus()
			elif not visit_button.disabled:visit_button.grab_focus()
			else:slider.grab_focus()
		elif direction==Vector2i.LEFT:roster.grab_focus()
		else:map.navigate_target(Vector2.RIGHT)
		return
	if focus==board_button and direction==Vector2i.RIGHT:passenger_button.grab_focus();return
	if focus==passenger_button and direction==Vector2i.LEFT:board_button.grab_focus();return
	var side:=SIDE_RIGHT if direction.x>0 else SIDE_LEFT if direction.x<0 else SIDE_BOTTOM if direction.y>0 else SIDE_TOP
	var next:=focus.find_valid_focus_neighbor(side)
	if next!=null:next.grab_focus()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:quitting=true;_back()
	elif what==NOTIFICATION_APPLICATION_FOCUS_OUT:_focused=false;_pan=Vector2.ZERO;_zoom=0;_triggers=Vector2.ZERO;picker_input.reset()
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN:_focused=true

func _exit_tree() -> void:
	if worker!=null:worker.wait_to_finish();worker=null
