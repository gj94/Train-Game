extends CanvasLayer
## Inspecting/viewing never changes the player assignment. Handover is explicit.
signal station_view_requested(index: int)
signal services_requested
signal train_selected(id: String)
signal view_train_requested(id: String)
signal service_deleted(id: String)
signal drive_requested
signal pause_requested
signal restart_requested
signal scenario_requested
signal lhb_requested
signal result_message(result: Dictionary, success: String)
signal open_changed(value: bool)
const UI := preload("res://game/dispatch_theme.gd")
const Map := preload("res://game/dispatch_canvas.gd")
const TimetableView := preload("res://game/timetable_view.gd")
const Clock := preload("res://sim/world_clock.gd")
var world: RailWorld
var engine
var selected_train := ""
var inspected_train := ""
var source := ""
var auto_dispatch := false:
	set(value):
		auto_dispatch=value
		if engine!=null and engine.enabled!=value:engine.set_enabled(value)
var hold_arrivals := false:
	set(value):
		hold_arrivals=value
		if engine!=null:engine.hold_maruthur=value
var timetable_open := false
var _root: Control
var _map
var _source: OptionButton
var _exit: OptionButton
var _reason: Label
var _set: Button
var _cancel: Button
var _roster := {}
var _clock: Label
var _objective: Label
var _restart: Button
var _timetable
var _table_button: Button
var _auto_button: Button
var _hold_button: Button
var _station_picker: OptionButton
var _platform: OptionButton
var _search: LineEdit
var _train_card: VBoxContainer
var _route_card: VBoxContainer
var _inspect_title: Label
var _inspect_stats: Label
var _inspect_reason: Label
var _inspect_call: Label
var _priority: Label
var _hold_service: Button
var _release_signal: Button
var _take: Button
var _view: Button
var _alert_label: Label
var _journal: RichTextLabel
var _alerts: ItemList
var _zoom: Label
var _status: Label
var _your_train: Label
var _confirm: PanelContainer
var _confirm_blocker: ColorRect
var _confirm_text: Label
var _confirm_yes: Button
var _confirm_no: Button
var _confirm_id := ""
var _confirm_delete := false
var _confirm_title: Label
var _delete_service: Button
var _timer := 0.0
var _last_revision := -1
var _filter_waiting := false
var _tabs: TabContainer
var _inspector: ScrollContainer
var _last_platform_key := ""

func setup(w: RailWorld) -> void:
	layer=4
	world=w;engine=w.dispatcher();engine.enabled=auto_dispatch
	if not world.trains.has(selected_train):selected_train=str(world.trains.keys()[0])
	inspected_train=selected_train
	source=str(world.signals.keys()[0])
	_root=Control.new();add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg:=ColorRect.new();bg.color=Color("#08111a");_root.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin:=MarginContainer.new();_root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,16)
	var page:=VBoxContainer.new();page.add_theme_constant_override("separation",12);margin.add_child(page)
	var header:=HBoxContainer.new();header.add_theme_constant_override("separation",20);page.add_child(header)
	var brand:=VBoxContainer.new();header.add_child(brand)
	UI.label(brand,"RAIL CONTROL",24)
	UI.label(brand,"KERALA COAST  /  OPERATIONS" if world.scenery.get("geographic",false) else "SOUTHERN LINE  /  OPERATIONS",12,UI.MINT)
	var spacer:=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(spacer)
	_clock=UI.label(header,"",22)
	_auto_button=UI.button(header,"AUTO DISPATCH",func():auto_dispatch=not auto_dispatch;_refresh())
	UI.button(header,"Pause / resume",func():pause_requested.emit())
	UI.button(header,"Close  D",func():set_open(false))
	var summary:=HBoxContainer.new();summary.add_theme_constant_override("separation",24);page.add_child(summary)
	_your_train=UI.label(summary,"",14,UI.AMBER)
	_status=UI.label(summary,"",14,UI.MUTED);_status.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	UI.label(summary,"LIVE  ·  simulation continues while the desk is open",12,UI.MUTED)
	var body:=HBoxContainer.new();body.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",12);page.add_child(body)
	_build_roster(body)
	var center:=VBoxContainer.new();center.size_flags_horizontal=Control.SIZE_EXPAND_FILL;center.add_theme_constant_override("separation",8);body.add_child(center)
	_build_center(center)
	_build_inspector(body)
	_objective=UI.label(page,"Wheel zoom · Drag pan · Click inspect · Home fit  |  Xbox: LS pan · LT/RT zoom · D-pad targets · A inspect · LB/RB areas · X locate · Y fit",12,UI.MUTED)
	_build_confirmation()
	engine.run_cycle(false)
	select_signal(source,true)
	inspect_train(inspected_train,false)
	_refresh()

func _build_roster(parent: Node) -> void:
	var v:=UI.section(parent,"SERVICE EXPLORER")
	v.get_parent().custom_minimum_size.x=250
	_search=LineEdit.new();v.add_child(_search);_search.placeholder_text="Find service or station…"
	_search.custom_minimum_size.y=38
	_search.text_changed.connect(func(_s):_filter_roster();_populate_stations())
	var filters:=HBoxContainer.new();v.add_child(filters)
	UI.button(filters,"All services",func():_filter_waiting=false;_filter_roster())
	UI.button(filters,"Waiting",func():_filter_waiting=true;_filter_roster())
	var scroll:=ScrollContainer.new();scroll.follow_focus=true;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;v.add_child(scroll)
	var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",7);scroll.add_child(list)
	for t: Train in world.trains.values():
		var button:=UI.button(list,"",func():inspect_train(t.id))
		button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.custom_minimum_size.y=74;button.clip_text=true
		_roster[t.id]=button
	UI.button(v,"Your service",func():inspect_train(selected_train);_map.focus_train(selected_train))
	UI.button(v,"Design / import services  F5",func():services_requested.emit())
	_restart=UI.button(v,"Restart services",func():restart_requested.emit());_restart.visible=false
	_hold_button=UI.button(v,"Hold MRT exercise: off",func():hold_arrivals=not hold_arrivals;_refresh())
	_hold_button.visible=not world.scenery.get("geographic",false)

func _build_center(parent: Node) -> void:
	var tools:=HBoxContainer.new();tools.add_theme_constant_override("separation",6);parent.add_child(tools)
	_station_picker=OptionButton.new();UI.style_button(_station_picker);tools.add_child(_station_picker)
	_station_picker.custom_minimum_size.x=170;_station_picker.clip_text=true
	_populate_stations()
	_station_picker.item_selected.connect(func(i):
		var index: int=_station_picker.get_item_metadata(i)
		_map.focus_station(index))
	UI.button(tools,"−",func():_map.zoom_at(1.0/1.5)).size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	UI.button(tools,"+",func():_map.zoom_at(1.5)).size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	UI.button(tools,"Fit",func():_map.focus_station(-1)).size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	UI.button(tools,"Locate",func():_map.focus_train(inspected_train)).size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	UI.button(tools,"Follow",func():_map.focus_train(inspected_train);_map.follow_train=true).size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	_zoom=UI.label(tools,"",12,UI.MUTED)
	var views:=HBoxContainer.new();parent.add_child(views)
	UI.button(views,"Track diagram",func():show_timetable(false))
	_table_button=UI.button(views,"Service timetable  M",func():show_timetable(not timetable_open))
	UI.button(views,"Visit yard",func():
		if _map.focus_index>=0:station_view_requested.emit(_map.focus_index))
	_map=Map.new();_map.world=world;_map.inspected_train=inspected_train;parent.add_child(_map)
	_map.signal_selected.connect(func(id):select_signal(id))
	_map.destination_selected.connect(_select_destination)
	_map.train_selected.connect(inspect_train)
	_map.station_selected.connect(func(index):_map.focus_station(index))
	_map.view_changed.connect(func():_zoom.text="%.1f km" % (_map.span/1000))
	_timetable=TimetableView.new();_timetable.world=world;_timetable.size_flags_vertical=Control.SIZE_EXPAND_FILL;parent.add_child(_timetable);_timetable.visible=false
	_timetable._table.focus_mode=Control.FOCUS_ALL
	_tabs=TabContainer.new();_tabs.custom_minimum_size.y=156;parent.add_child(_tabs)
	var alert_box:=VBoxContainer.new();alert_box.name="Attention";_tabs.add_child(alert_box)
	_alert_label=UI.label(alert_box,"",12,UI.MUTED)
	_alerts=ItemList.new();_alerts.size_flags_vertical=Control.SIZE_EXPAND_FILL;alert_box.add_child(_alerts)
	_alerts.item_activated.connect(func(i):
		var ids: Array=_alerts.get_item_metadata(i)
		if not ids.is_empty():inspect_train(ids[0]);_map.focus_train(ids[0]))
	_journal=RichTextLabel.new();_journal.name="Decision log";_journal.bbcode_enabled=false;_journal.scroll_following=true;_journal.selection_enabled=true;_journal.focus_mode=Control.FOCUS_ALL;_tabs.add_child(_journal)

func _build_inspector(parent: Node) -> void:
	var panel:=UI.section(parent,"INSPECTOR  /  SELECT, THEN ACT")
	panel.get_parent().custom_minimum_size.x=326
	var selectors:=HBoxContainer.new();panel.add_child(selectors)
	UI.button(selectors,"Service",func():_show_route(false))
	UI.button(selectors,"Route",func():_show_route(true))
	_inspector=ScrollContainer.new();_inspector.follow_focus=true;_inspector.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;_inspector.size_flags_vertical=Control.SIZE_EXPAND_FILL;panel.add_child(_inspector)
	var content:=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_inspector.add_child(content)
	_train_card=VBoxContainer.new();_train_card.add_theme_constant_override("separation",12);content.add_child(_train_card)
	_inspect_title=UI.wrap(_train_card,"",21)
	_inspect_stats=UI.wrap(_train_card,"",13,UI.MUTED)
	_inspect_reason=UI.wrap(_train_card,"",14,UI.AMBER)
	_inspect_call=UI.wrap(_train_card,"",13)
	var views:=HBoxContainer.new();_train_card.add_child(views)
	_view=UI.button(views,"View train",func():view_train_requested.emit(inspected_train);set_open(false))
	UI.button(views,"Timetable",func():show_timetable(true))
	_take=UI.button(_train_card,"Take control…",_prompt_handover)
	UI.wrap(_train_card,"Viewing leaves your assigned service and driving controls unchanged.",12,UI.MUTED)
	UI.label(_train_card,"TRAFFIC MANAGEMENT",12,UI.MUTED)
	_hold_service=UI.button(_train_card,"Hold service",func():
		engine.set_service_hold(inspected_train,not engine.operator_holds.has(inspected_train));_refresh())
	var priority_row:=HBoxContainer.new();_train_card.add_child(priority_row)
	UI.button(priority_row,"−",func():_change_priority(-10))
	_priority=UI.label(priority_row,"",14);_priority.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_priority.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	UI.button(priority_row,"+",func():_change_priority(10))
	UI.label(_train_card,"NEXT CALL / REQUESTED ROAD",12,UI.MUTED)
	_platform=OptionButton.new();UI.style_button(_platform);_train_card.add_child(_platform)
	UI.button(_train_card,"Request this platform",func():
		if _platform.selected>=0:
			var result: Dictionary=engine.assign_platform(inspected_train,_platform.get_item_metadata(_platform.selected))
			result_message.emit(result,"Platform preference recorded");_refresh())
	_delete_service=UI.button(_train_card,"Delete service…",_prompt_delete)
	_delete_service.tooltip_text="Remove this train for the current run and let dispatch reassess. Restart restores the scenario."
	UI.button(_train_card,"Inspect next signal",func():
		var ns:=world.next_signal(world.trains[inspected_train])
		if not ns.is_empty():select_signal(ns.id,true);_map.focus_signal(ns.id))
	_route_card=VBoxContainer.new();_route_card.add_theme_constant_override("separation",12);content.add_child(_route_card)
	UI.label(_route_card,"ROUTE CONTROL",20)
	UI.wrap(_route_card,"Choose an entrance and an exit. Preview is white; authority becomes mint only after the interlocking accepts it.",13,UI.MUTED)
	_source=OptionButton.new();UI.style_button(_source);_route_card.add_child(_source)
	for sid in world.signals:
		if sid not in world.automatic_signals:_source.add_item(sid)
	_source.item_selected.connect(func(i):select_signal(_source.get_item_text(i),true))
	_exit=OptionButton.new();UI.style_button(_exit);_route_card.add_child(_exit)
	_exit.item_selected.connect(func(_i):_refresh())
	_reason=UI.wrap(_route_card,"",14,UI.AMBER)
	_set=UI.button(_route_card,"Set route",_set_route)
	_cancel=UI.button(_route_card,"Put to red & hold",func():result_message.emit(engine.put_to_red(source),"Signal held at red; safety locks retained");_refresh())
	_release_signal=UI.button(_route_card,"Release signal hold",func():engine.release_signal(source);_refresh())
	UI.wrap(_route_card,"Putting a signal to red inhibits automatic re-clearing. Approach and occupied route locks remain until safe release.",12,UI.MUTED)
	UI.button(_route_card,"Centre this signal",func():_map.focus_signal(source))
	_show_route(false)

func _build_confirmation() -> void:
	_confirm_blocker=ColorRect.new();_confirm_blocker.color=Color(0,0,0,.65);_root.add_child(_confirm_blocker)
	_confirm_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_confirm_blocker.visible=false
	var center:=CenterContainer.new();_root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_confirm=PanelContainer.new();center.add_child(_confirm)
	_confirm.custom_minimum_size=Vector2(500,220)
	_confirm.add_theme_stylebox_override("panel",UI.panel("#203346",22))
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",18);_confirm.add_child(column)
	_confirm_title=UI.label(column,"HAND OVER YOUR SERVICE?",22,UI.AMBER)
	_confirm_text=UI.wrap(column,"",15)
	var row:=HBoxContainer.new();column.add_child(row)
	_confirm_no=UI.button(row,"Keep current service",cancel_handover)
	_confirm_yes=UI.button(row,"Take control",confirm_handover)
	for button in [_confirm_no,_confirm_yes]:
		var other: Button=_confirm_yes if button==_confirm_no else _confirm_no
		button.focus_next=button.get_path_to(other);button.focus_previous=button.get_path_to(other)
		for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:button.set_focus_neighbor(side,button.get_path_to(other))
	_confirm.visible=false

func _prompt_handover() -> void:
	if inspected_train==selected_train:drive_requested.emit();return
	_confirm_id=inspected_train
	_confirm_delete=false;_confirm_title.text="HAND OVER YOUR SERVICE?"
	_confirm_no.text="Keep current service";_confirm_yes.text="Take control"
	_confirm_text.text="AI will take over %s. You will drive %s. Viewing this train does not require a handover." % [selected_train,_confirm_id]
	_confirm_blocker.show();_confirm.show();_confirm_no.grab_focus()

func cancel_handover() -> void:
	_confirm_blocker.hide();_confirm.hide();_confirm_id=""
	if _confirm_delete:_delete_service.grab_focus()
	else:_take.grab_focus()
	_confirm_delete=false

func confirm_handover() -> void:
	if _confirm_delete:
		_confirm_deletion()
		return
	var id:=_confirm_id
	_confirm_blocker.hide();_confirm.hide();_confirm_id=""
	if not world.trains.has(id):return
	train_selected.emit(id);selected_train=id;drive_requested.emit()

func _prompt_delete() -> void:
	if inspected_train==selected_train or not world.trains.has(inspected_train):return
	_confirm_id=inspected_train;_confirm_delete=true
	_confirm_title.text="DELETE THIS SERVICE?"
	_confirm_text.text="Remove %s — %s from this run? Its train, occupancy and reservations will be removed; dispatch will reassess. Restart restores the scenario. Your service %s stays under your control." % [_confirm_id,world.trains[_confirm_id].service_name,selected_train]
	_confirm_no.text="Keep service";_confirm_yes.text="Delete service"
	_confirm_blocker.show();_confirm.show();_confirm_no.grab_focus()

func _confirm_deletion() -> void:
	var id:=_confirm_id
	_confirm_blocker.hide();_confirm.hide();_confirm_id="";_confirm_delete=false
	var result: Dictionary=engine.delete_service(id,selected_train)
	if result.ok:
		if _roster.has(id):
			_roster[id].queue_free();_roster.erase(id)
		service_deleted.emit(id)
		inspect_train(selected_train)
		_map._hits.clear();_map.last_footprints.erase(id);_map._focus_key=""
		_map.focus_train(selected_train);_roster[selected_train].grab_focus()
	else:_delete_service.grab_focus()
	result_message.emit(result,"Service "+id+" deleted; traffic reassessed")
	_refresh()

func inspect_train(id: String,center: bool=false) -> void:
	if not world.trains.has(id):return
	inspected_train=id;_map.inspected_train=id
	_show_route(false)
	if center:_map.focus_train(id)
	_last_platform_key="";_refresh()

func _show_route(value: bool) -> void:
	if _route_card!=null:_route_card.visible=value
	if _train_card!=null:_train_card.visible=not value

func select_signal(id: String,force: bool=false) -> void:
	if not world.signals.has(id):return
	if not force and source!=id:
		for option in world.route_options(source):
			if option.destination==id:_select_destination(id);_show_route(true);return
	source=id
	var found:=false
	for i in _source.item_count:
		if _source.get_item_text(i)==id:_source.select(i);found=true
	if not found:_source.add_item(id);_source.select(_source.item_count-1)
	_exit.clear()
	for option in world.route_options(source):
		_exit.add_item("To "+option.destination);_exit.set_item_metadata(_exit.item_count-1,option.destination)
	_show_route(true);_refresh()

func _select_destination(id: String) -> void:
	for i in _exit.item_count:
		if _exit.get_item_metadata(i)==id:_exit.select(i);_refresh();return

func _set_route() -> void:
	if _exit.selected<0:return
	var dest: String=_exit.get_item_metadata(_exit.selected)
	result_message.emit(engine.request_route(source,dest),"Route set: "+source+" → "+dest)
	_refresh()

func _change_priority(delta: int) -> void:
	engine.set_priority(inspected_train,clampi(world.trains[inspected_train].dispatch_priority+delta,0,100));_refresh()

func toggle_driver() -> void:
	var t: Train=world.trains[selected_train]
	t.automatic=not t.automatic
	if not t.automatic:t.controller=0
	_refresh()

func set_open(value: bool) -> void:
	_root.visible=value
	if value:
		engine.run_cycle(false);_refresh()
	else:
		_confirm_blocker.hide();_confirm.hide()
		for picker in pickers():picker.get_popup().hide()
		var focused:=get_viewport().gui_get_focus_owner()
		if focused!=null and _root.is_ancestor_of(focused):focused.release_focus()
	open_changed.emit(value)

func toggle() -> void:
	set_open(not _root.visible)

func toggle_timetable() -> void:
	show_timetable(not timetable_open)

func show_timetable(value: bool) -> void:
	timetable_open=value
	set_open(true);_map.visible=not value;_timetable.visible=value
	if value:_timetable.refresh(inspected_train)

func pickers() -> Array:
	return [_source,_exit,_station_picker,_platform]

func focus_first() -> void:
	if _confirm.visible:_confirm_no.grab_focus()
	else:_map.grab_focus()

func focus_zone(step: int) -> void:
	var zones: Array=[_map,_roster.get(inspected_train),_view if _train_card.visible else _source,_station_picker,_alerts]
	var owner:=get_viewport().gui_get_focus_owner()
	var current:=zones.find(owner)
	zones[posmod(current+step,zones.size())].grab_focus()

func pad_navigation(left: Vector2,right: Vector2,zoom: float,delta: float) -> void:
	if _confirm.visible:return
	if _map.visible:
		if left.length()>.02:_map.pan_pixels(-left*620*delta)
		if absf(zoom)>.05:_map.zoom_at(pow(2,zoom*delta*2))
	if right.length()>.02:_inspector.scroll_vertical+=roundi(right.y*550*delta)

func _populate_stations() -> void:
	if _station_picker==null:return
	var query:=_search.text.to_lower() if _search!=null else ""
	_station_picker.clear();_station_picker.add_item("Whole route");_station_picker.set_item_metadata(0,-1)
	for i in world.stations.size():
		var st: Dictionary=world.stations[i]
		if not query.is_empty() and not (st.code+" "+st.name).to_lower().contains(query):continue
		_station_picker.add_item(st.code+" · "+st.name);_station_picker.set_item_metadata(_station_picker.item_count-1,i)

func _filter_roster() -> void:
	var query:=_search.text.to_lower()
	for id in _roster:
		var t: Train=world.trains[id];var state: Dictionary=engine.states.get(id,{})
		_roster[id].visible=(query.is_empty() or (id+" "+t.service_name+" "+t.destination).to_lower().contains(query)) and (not _filter_waiting or state.get("status","") in ["held","blocked","waiting","attention"])

func _refresh() -> void:
	if engine==null or _map==null or _inspect_title==null:return
	_clock.text="%s  ·  D%d" % [world.clock_text(),world.clock_day()]
	_auto_button.text="AUTO DISPATCH  "+("ON" if auto_dispatch else "OFF")
	_your_train.text="YOUR SERVICE  "+selected_train+"  ·  "+("AI driving" if world.trains[selected_train].automatic else "Manual driving")
	var complete: int=world.trains.values().filter(func(t):return t.service_complete).size()
	var held: int=engine.states.values().filter(func(s):return s.status in ["waiting","held","blocked"]).size()
	_status.text="%d services   /   %d waiting   /   %d arrived" % [world.trains.size(),held,complete]
	for id in _roster:
		var t: Train=world.trains[id];var state: Dictionary=engine.states.get(id,{})
		_roster[id].text="%s  %s   %d km/h\n%s\n%s" % [id,"●" if id==inspected_train else "",roundi(t.speed*3.6),t.service_name,state.get("status","observing").to_upper()]
		_roster[id].tooltip_text=t.service_name+"\n"+state.get("reason","")
	var t: Train=world.trains[inspected_train]
	var state: Dictionary=engine.states.get(inspected_train,{})
	_inspect_title.text=inspected_train+"  /  "+t.service_name
	_inspect_stats.text="%d km/h   ·   %.1f m   ·   %s\n%s" % [roundi(t.speed*3.6),t.length,"AI driver" if t.automatic else "Manual driver",t.path[0].edge]
	_inspect_reason.text=state.get("reason","Waiting for dispatch assessment")
	var planned: String=state.get("planned_crossing","")
	if not planned.is_empty() and not _inspect_reason.text.contains(planned):_inspect_reason.text+="\n"+planned
	var call: Dictionary=state.get("call",{})
	_inspect_call.text="No remaining scheduled calls"
	if not call.is_empty():
		_inspect_call.text="NEXT  "+call.name+"\n"+call.block+" · booked "+Clock.format_time(call.booked)
		if is_finite(call.arrival):_inspect_call.text+="\nEstimated "+Clock.format_time(call.arrival)+" · traffic waits may extend this"
	_hold_service.text="Release operator hold" if engine.operator_holds.has(inspected_train) else "Hold at next controlled signal"
	_priority.text="Priority  %d" % t.dispatch_priority
	_take.text="Return to your cab" if inspected_train==selected_train else "Take control…"
	_delete_service.disabled=inspected_train==selected_train
	var key: String=str(call.get("block",""))+":"+inspected_train
	if key!=_last_platform_key:
		_last_platform_key=key;_platform.clear()
		var st: Dictionary=preload("res://sim/priority_dispatch.gd").station(world,call.get("block",""))
		for road in st.get("platform_tracks",[]):
			_platform.add_item(road);_platform.set_item_metadata(_platform.item_count-1,road)
			if road==call.get("block",""):_platform.select(_platform.item_count-1)
	var target: String=_exit.get_item_metadata(_exit.selected) if _exit.selected>=0 else ""
	var reason: String=engine.route_preview(source,target).reason
	var sig: Dictionary=world.signals[source]
	_set.disabled=not reason.is_empty() or source in world.automatic_signals
	_cancel.disabled=source in world.automatic_signals
	_release_signal.disabled=not engine.inhibited_signals.has(source)
	_reason.text="Ready · points align and lock together" if reason.is_empty() else reason
	if not sig.route.is_empty():_reason.text=source+" → "+sig.destination+"\n"+("Tail clearance: "+sig.owner if not sig.owner.is_empty() else ("Approach lock retained" if sig.cancel_pending else "Route locked · "+["RED","YELLOW","GREEN"][world.aspect(source)]))
	if source in world.automatic_signals:_reason.text="Automatic block signal · controlled by occupancy"
	_map.selected=source;_map.destination=target;_map.queue_redraw()
	if timetable_open:_timetable.refresh(inspected_train)
	if engine.revision!=_last_revision:
		_last_revision=engine.revision
		_alert_label.text="No unresolved alerts" if engine.alerts.is_empty() else "%d item(s) need attention · activate to inspect" % engine.alerts.size()
		_alerts.clear()
		for alert in engine.alerts:
			_alerts.add_item(alert.text);_alerts.set_item_metadata(_alerts.item_count-1,alert.services)
		var lines:=PackedStringArray()
		for entry in engine.journal.slice(maxi(0,engine.journal.size()-60)):
			lines.append("%s  %s  %s" % [Clock.format_time(entry.time),entry.train,entry.text])
		_journal.text="\n".join(lines)
	_filter_roster()
	_restart.visible=complete==world.trains.size()
	_hold_button.text="Hold MRT exercise: "+("on" if hold_arrivals else "off")

func _process(delta: float) -> void:
	if _root==null or not _root.visible:return
	_timer+=delta
	if _timer>=.25:_timer=0;_refresh()
