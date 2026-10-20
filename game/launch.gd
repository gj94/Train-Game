extends Control
## Lightweight service browser. No railway or 3D scenery until a journey is chosen.
const Starts:=preload("res://persistence/service_starts.gd")
const Store:=preload("res://persistence/save_store.gd")
const Snapshot:=preload("res://sim/world_snapshot.gd")
const Clock:=preload("res://sim/world_clock.gd")
const Briefing:=preload("res://persistence/service_briefing.gd")
const Traffic:=preload("res://persistence/service_traffic.gd")
const Days:=preload("res://persistence/operating_days.gd")
const SORTS:=["Departure · earliest first","Average speed · fastest first","Average speed · slowest first","Service name · A–Z"]
const STOCK:={icf="WAP-7 + ICF",lhb="WAP-7 + LHB",vb8="Vande Bharat · 8 cars",vb16="Vande Bharat · 16 cars"}
const FILTERS:=["All departures","Morning","Afternoon","Evening","Night"]
var directory:=Starts.DIRECTORY
var timetable_id:="standard"
var timetable_picker: OptionButton
var timetable_description: Label
var store:=Store.new()
var services: Array=[]
var shown: Array=[]
var selected: Dictionary={}
var saves: Array=[]
var page:="services"
var period:=0
var sort_mode:=0
var sort_button: OptionButton
var roster: ItemList
var search: LineEdit
var filters: Array[Button]=[]
var detail_title: Label
var departure: Label
var description: Label
var calls_grid: GridContainer
var briefing: Label
var detail_scroll: ScrollContainer
var detail_tabs: HBoxContainer
var stops_tab: Button
var traffic_tab: Button
var traffic_summary: Label
var traffic_list: VBoxContainer
var traffic_data: Dictionary={}
var traffic_reason:="Traffic preview is unavailable for this timetable."
var traffic_rows: Array=[]
var detail_mode:=0
var status: Label
var count_label: Label
var start_button: Button
var continue_button: Button
var saved_button: Button
var busy_panel: PanelContainer
var busy_label: Label
var cancel_button: Button
var content: MarginContainer
var worker: Thread
var save_worker: Thread
var cancelled:=false
var quitting:=false
var starting:=false
var _axes:=Vector2.ZERO
var _scroll_axis:=0.0
var _direction:=Vector2i.ZERO
var _repeat:=0.0
var _focused:=true
var display:=preload("res://game/display_options.gd").new()

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	if _bypass():
		get_tree().change_scene_to_file.call_deferred("res://game/main.tscn");return
	if "--script" not in OS.get_cmdline_args():display.restore()
	Engine.max_fps=60;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	get_tree().auto_accept_quit=false
	Input.joy_connection_changed.connect(func(_device,_connected):_axes=Vector2.ZERO;_scroll_axis=0.0)
	timetable_id=Days.definition(str(get_tree().get_meta("timetable_id","standard"))).id
	if directory==Starts.DIRECTORY:directory=Days.definition(timetable_id).starts
	_build()
	_load_catalogue()
	continue_button.disabled=true;continue_button.text="Checking saves…";saved_button.disabled=true
	save_worker=Thread.new()
	if save_worker.start(_saved_entries)!=OK:
		save_worker=null;continue_button.text="Continue latest save";saved_button.disabled=false
	selected={id="K1"}
	refresh()
	roster.grab_focus()
	var restart: String=get_tree().get_meta("launch_service","")
	if not restart.is_empty():
		get_tree().remove_meta("launch_service")
		for row in services:
			if row.id==restart:_begin("service",row);break

func _set_status(message: String) -> void:
	status.text=message;status.visible=not message.is_empty()

func _load_catalogue() -> void:
	services=[];traffic_data={};_set_status("")
	traffic_reason="Traffic preview is unavailable for this timetable."
	var catalogue:=Starts.catalogue(directory)
	if catalogue.ok:
		services=catalogue.data.services
		var traffic:=Traffic.catalogue(services,directory)
		if traffic.ok:traffic_data=traffic.data
		else:traffic_reason=traffic.reason
	else:_set_status(catalogue.reason)

func select_timetable(index: int) -> void:
	if worker!=null or starting or index<0 or index>=Days.DAYS.size():return
	timetable_id=Days.DAYS[index].id;directory=Days.DAYS[index].starts
	get_tree().set_meta("timetable_id",timetable_id)
	for key in ["timeline_index","timeline_clock"]:
		if get_tree().has_meta(key):get_tree().remove_meta(key)
	timetable_picker.select(index);timetable_description.text=Days.DAYS[index].description
	_load_catalogue()
	selected={id="K1"};page="services";period=0;search.text="";refresh();roster.grab_focus()

func _bypass() -> bool:
	if get_tree().has_meta("resume_session"):return true
	for arg in OS.get_cmdline_user_args():
		if arg in ["--benchmark","--direct","--wap7","--lhb","--memu"] or arg.begins_with("--fleet=") or arg.begins_with("--route="):return true
	return false

func _label(parent: Node,text: String,size: int=18,colour: Color=Color("dce6e9")) -> Label:
	var label:=Label.new();label.text=text;label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",colour);parent.add_child(label)
	return label

func _button(parent: Node,text: String,action: Callable) -> Button:
	var button:=Button.new();button.text=text;button.custom_minimum_size.y=46
	button.add_theme_font_size_override("font_size",17);parent.add_child(button);button.pressed.connect(action)
	return button

func _box(colour: Color,border: Color=Color("29424c")) -> StyleBoxFlat:
	var box:=StyleBoxFlat.new();box.bg_color=colour;box.border_color=border
	box.set_border_width_all(1);box.set_corner_radius_all(8);box.set_content_margin_all(14)
	return box

func _build() -> void:
	var skin:=Theme.new();skin.default_font_size=18
	skin.set_stylebox("normal","Button",_box(Color("112d38")))
	skin.set_stylebox("hover","Button",_box(Color("24424c")))
	skin.set_stylebox("pressed","Button",_box(Color("275b50")))
	var focus:=_box(Color(0,0,0,0),Color("86e4be"));focus.set_border_width_all(3)
	skin.set_stylebox("focus","Button",focus);skin.set_stylebox("focus","ItemList",focus)
	skin.set_stylebox("panel","ItemList",_box(Color("0c202a")))
	skin.set_stylebox("selected","ItemList",_box(Color("245446")))
	skin.set_stylebox("selected_focus","ItemList",_box(Color("245446"),Color("86e4be")))
	theme=skin
	var bg:=ColorRect.new();bg.color=Color("07151d");add_child(bg);bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var margin:=MarginContainer.new();add_child(margin);margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	content=margin
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,24)
	var outer:=VBoxContainer.new();outer.add_theme_constant_override("separation",12);margin.add_child(outer)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",12);outer.add_child(top)
	var brand:=VBoxContainer.new();brand.size_flags_horizontal=SIZE_EXPAND_FILL;top.add_child(brand)
	_label(brand,"TRAIN GAME",13,Color("86e4be"));_label(brand,"KERALA COAST",28)
	_button(top,"Explore by time",func():get_tree().change_scene_to_file("res://game/launch_timeline.tscn"))
	continue_button=_button(top,"Continue latest save",_continue)
	saved_button=_button(top,"Saved journeys",_toggle_saves)
	_button(top,"Fullscreen",func():display.toggle())
	_button(top,"Quit",_quit)
	_label(outer,"Ernakulam Junction — Alappuzha — Thiruvananthapuram — Nagercoil",17,Color("a8bdc6"))
	var day_row:=HBoxContainer.new();day_row.add_theme_constant_override("separation",16);outer.add_child(day_row)
	_label(day_row,"Operating day",17,Color("a8bdc6"))
	timetable_picker=OptionButton.new();timetable_picker.custom_minimum_size=Vector2(300,42);day_row.add_child(timetable_picker)
	for day in Days.DAYS:timetable_picker.add_item(day.name)
	timetable_picker.select(Days.index_of(timetable_id));timetable_picker.item_selected.connect(select_timetable)
	timetable_description=_label(day_row,Days.definition(timetable_id).description,15,Color("a8bdc6"))
	timetable_description.size_flags_horizontal=SIZE_EXPAND_FILL;timetable_description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var filter_row:=HBoxContainer.new();filter_row.add_theme_constant_override("separation",8);outer.add_child(filter_row)
	for i in FILTERS.size():
		var index:=i
		var button:=_button(filter_row,FILTERS[i],func():set_period(index));button.toggle_mode=true;filters.append(button)
	search=LineEdit.new();search.placeholder_text="Search train, station or service ID";search.size_flags_horizontal=SIZE_EXPAND_FILL
	filter_row.add_child(search);search.text_changed.connect(func(_s):refresh())
	var results_row:=HBoxContainer.new();outer.add_child(results_row)
	count_label=_label(results_row,"",16,Color("a8bdc6"));count_label.size_flags_horizontal=SIZE_EXPAND_FILL
	_label(results_row,"Sort by",16,Color("a8bdc6"))
	sort_button=OptionButton.new();sort_button.custom_minimum_size=Vector2(320,42);results_row.add_child(sort_button)
	for text in SORTS:sort_button.add_item(text)
	sort_button.item_selected.connect(func(index):sort_mode=index;refresh())
	var columns:=HBoxContainer.new();columns.add_theme_constant_override("separation",24);columns.size_flags_vertical=SIZE_EXPAND_FILL;outer.add_child(columns)
	roster=ItemList.new();roster.size_flags_horizontal=SIZE_EXPAND_FILL;roster.size_flags_vertical=SIZE_EXPAND_FILL
	roster.add_theme_font_size_override("font_size",18);roster.add_theme_constant_override("v_separation",16)
	columns.add_child(roster);roster.item_selected.connect(_select);roster.item_activated.connect(func(_i):start_button.grab_focus())
	var panel:=PanelContainer.new();panel.custom_minimum_size.x=390;panel.size_flags_horizontal=SIZE_EXPAND_FILL;panel.size_flags_stretch_ratio=.75
	panel.add_theme_stylebox_override("panel",_box(Color("102631")));columns.add_child(panel)
	var details:=VBoxContainer.new();details.add_theme_constant_override("separation",8);panel.add_child(details)
	departure=_label(details,"",30)
	detail_title=_label(details,"Choose a service",21);detail_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail_tabs=HBoxContainer.new();detail_tabs.add_theme_constant_override("separation",8);details.add_child(detail_tabs)
	stops_tab=_button(detail_tabs,"Stops",func():set_detail_mode(0));stops_tab.toggle_mode=true;stops_tab.size_flags_horizontal=SIZE_EXPAND_FILL
	traffic_tab=_button(detail_tabs,"Traffic",func():set_detail_mode(1));traffic_tab.toggle_mode=true;traffic_tab.size_flags_horizontal=SIZE_EXPAND_FILL
	traffic_summary=_label(details,"",14,Color("a8bdc6"));traffic_summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;details.add_child(scroll)
	detail_scroll=scroll
	var body:=VBoxContainer.new();body.size_flags_horizontal=SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",20);scroll.add_child(body)
	description=_label(body,"",16);description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	calls_grid=GridContainer.new();calls_grid.columns=3;calls_grid.add_theme_constant_override("h_separation",18);calls_grid.add_theme_constant_override("v_separation",12);body.add_child(calls_grid)
	briefing=_label(body,"",16,Color("a8bdc6"));briefing.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	traffic_list=VBoxContainer.new();traffic_list.add_theme_constant_override("separation",12);body.add_child(traffic_list)
	start_button=_button(details,"Drive this service",start_selected);start_button.custom_minimum_size.y=52
	start_button.add_theme_stylebox_override("normal",_box(Color("265e4a"),Color("86e4be")))
	status=_label(outer,"",16,Color("efc382"));status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_label(outer,"D-pad / LS navigate · A select · B back · LB / RB filter · X sort · Y stops / traffic · RS scroll · F11 fullscreen",15,Color("a8bdc6"))
	_label(outer,preload("res://game/build_version.gd").current(),13,Color("7895a2"))
	busy_panel=PanelContainer.new();add_child(busy_panel);busy_panel.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	busy_panel.add_theme_stylebox_override("panel",_box(Color(.02,.06,.08,.98)))
	var center:=CenterContainer.new();busy_panel.add_child(center)
	var loading:=VBoxContainer.new();loading.add_theme_constant_override("separation",24);center.add_child(loading)
	_label(loading,"PREPARING YOUR JOURNEY",28,Color("86e4be"))
	busy_label=_label(loading,"",21)
	cancel_button=_button(loading,"Cancel / B",_cancel);busy_panel.hide()

static func in_period(clock: float,filter: int) -> bool:
	var hour:=fposmod(clock,86400)/3600
	match filter:
		1:return hour>=6 and hour<12
		2:return hour>=12 and hour<16
		3:return hour>=16 and hour<19
		4:return hour>=19 or hour<6
	return true

func set_period(value: int) -> void:
	if worker!=null or starting:return
	page="services";period=posmod(value,FILTERS.size());refresh();roster.grab_focus()

func refresh() -> void:
	if worker!=null or starting:return
	var previous: String=selected.get("id","")
	shown.clear();roster.clear()
	for i in filters.size():filters[i].set_pressed_no_signal(page=="services" and period==i)
	saved_button.text="Back to services" if page=="saves" else "Saved journeys"
	var needle:=search.text.strip_edges().to_lower()
	for row in (services if page=="services" else saves):
		var text: String=row.name+" "+row.id+" "+row.get("origin","")+" "+row.get("destination","")+" "+STOCK.get(row.get("stock",""),"")
		for call in row.get("calls",[]):text+=" "+call.name
		if not needle.is_empty() and not text.to_lower().contains(needle):continue
		if page=="services" and not in_period(row.departure,period):continue
		shown.append(row)
	if page=="services":shown=Briefing.ordered(shown,sort_mode)
	sort_button.disabled=page!="services";sort_button.select(sort_mode)
	for row in shown:
		var text: String=(Briefing.time_text(row.departure)+"  ·  "+row.id+"  ·  "+row.name) if page=="services" else row.name
		if page=="services" and sort_mode in [1,2]:text="%.1f km/h  ·  " % row.average_kmh+text
		var index:=roster.add_item(text);roster.set_item_tooltip(index,text)
	count_label.text=("%d / %d services · Start at the origin · Dynamic AI traffic" % [shown.size(),services.size()]) if page=="services" else "Saved journeys · Load paused · Previous backups are available"
	start_button.text="Drive this service" if page=="services" else "Load saved journey"
	start_button.disabled=shown.is_empty()
	if shown.is_empty():
		selected={};detail_title.text="No matching journeys";departure.text="";description.text="Try another departure filter or clear the search."
		description.show();calls_grid.hide();briefing.text="";detail_tabs.hide();traffic_summary.hide();traffic_list.hide();return
	var index:=0
	for i in shown.size():
		if shown[i].id==previous:index=i;break
	roster.select(index);_select(index);roster.ensure_current_is_visible()

func _select(index: int) -> void:
	if index<0 or index>=shown.size():return
	selected=shown[index];detail_title.text=selected.name
	detail_scroll.scroll_vertical=0
	for child in calls_grid.get_children():calls_grid.remove_child(child);child.queue_free()
	for child in traffic_list.get_children():traffic_list.remove_child(child);child.queue_free()
	traffic_rows=[];detail_tabs.visible=page=="services";traffic_summary.visible=page=="services"
	calls_grid.visible=page=="services";briefing.text=""
	if page=="saves":
		description.show();briefing.show();traffic_list.hide()
		departure.text=selected.get("clock","")
		description.text="Service "+selected.get("service","")+"\n\nSaved "+selected.get("saved_at","")+"\n\nThe complete railway and your viewpoint will be restored, paused."
		return
	departure.text=Briefing.time_text(selected.departure)+" departure"
	var duration:=roundi(float(selected.duration)/60)
	var daylight: float=preload("res://sim/daylight.gd").sample(selected.start_clock).daylight
	var light: String="Night" if daylight<.15 else ("Twilight" if daylight<.9 else "Daylight")
	description.text="%s → %s\n%s · %d vehicles\n%d stops · %dh %02dm booked · %.1f km\n%.1f km/h scheduled average, including stops\n%s · board at %s" % [selected.origin,selected.destination,STOCK.get(selected.stock,selected.stock),selected.cars,selected.stops,duration/60,duration%60,selected.distance_m/1000.0,selected.average_kmh,light,Briefing.time_text(selected.start_clock)]
	for heading in ["SCHEDULED STOPS","ARR","DEP"]:_label(calls_grid,heading,13,Color("86e4be"))
	for i in selected.calls.size():
		var call: Dictionary=selected.calls[i]
		var name_label:=_label(calls_grid,"%02d  %s" % [i+1,call.name],16)
		name_label.size_flags_horizontal=SIZE_EXPAND_FILL;name_label.custom_minimum_size.x=140;name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		_label(calls_grid,"—" if i==0 else Briefing.time_text(call.arrival),16)
		_label(calls_grid,"—" if i==selected.calls.size()-1 else Briefing.time_text(call.departure),16)
	briefing.text="Start paused in the pilot seat, with brakes applied. Earlier traffic and delays are preserved."
	if not selected.get("departure_advice","").is_empty():briefing.text+="\n\nDispatcher at departure\n"+selected.departure_advice
	briefing.text+="\n\nCrossings and overtakes are decided dynamically; the signals and dispatcher give current instructions as you drive."
	traffic_rows=Traffic.for_service(traffic_data,selected.id)
	stops_tab.text="Stops · %d" % selected.calls.size();traffic_tab.text="Traffic · %d" % traffic_rows.size() if not traffic_data.is_empty() else "Traffic"
	traffic_summary.text="AI baseline · "+Traffic.summary(traffic_rows) if not traffic_data.is_empty() else "Traffic preview unavailable"
	_build_traffic()
	set_detail_mode(detail_mode)

func set_detail_mode(mode: int) -> void:
	if page!="services" or selected.is_empty():return
	detail_mode=clampi(mode,0,1);detail_scroll.scroll_vertical=0
	stops_tab.set_pressed_no_signal(detail_mode==0);traffic_tab.set_pressed_no_signal(detail_mode==1)
	description.visible=detail_mode==0;calls_grid.visible=detail_mode==0;briefing.visible=detail_mode==0;traffic_list.visible=detail_mode==1

func _build_traffic() -> void:
	var note:=_label(traffic_list,"Approximate times; your driving can change encounters. Crossings include opposing passes on double track, which may need no wait.",14,Color("a8bdc6"))
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if traffic_data.is_empty() or traffic_rows.is_empty():
		note=_label(traffic_list,traffic_reason if traffic_data.is_empty() else "No crossings or completed overtakes during this service in the baseline run.",17)
		note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return
	var names:={}
	for row in services:names[row.id]=row.name
	for event in traffic_rows:
		var card:=PanelContainer.new();var style:=_box(Color("0c202a"));style.set_content_margin_all(10);card.add_theme_stylebox_override("panel",style);traffic_list.add_child(card)
		var lines:=VBoxContainer.new();lines.add_theme_constant_override("separation",4);card.add_child(lines)
		var heading:=HBoxContainer.new();lines.add_child(heading)
		_label(heading,Traffic.time_text(event.time),17,Color("86e4be"))
		var kind:=_label(heading,event.role,14,Color("efc382") if event.kind=="overtake" else Color("a8bdc6"));kind.size_flags_horizontal=SIZE_EXPAND_FILL;kind.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		note=_label(lines,event.other+" · "+names.get(event.other,event.other),16);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		note=_label(lines,event.location+(" · route km %.1f" % (event.chainage_m/1000.0) if event.station.is_empty() else ""),14,Color("a8bdc6"));note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

func _saved_entries() -> Array:
	var entries:=[]
	for slot in store.slots():
		for backup in [false,true]:
			if not (slot.backup if backup else slot.ok):continue
			var info: Dictionary=slot.backup_summary if backup else slot.summary
			entries.append({id=slot.id+("-backup" if backup else ""),slot=slot.id,backup=backup,name=(preload("res://persistence/save_store.gd").label(slot.id))+(" · backup" if backup else "")+" · "+str(info.get("title","Journey")),
				service=info.get("service",""),clock="Day %d · %s" % [info.get("day",1),info.get("clock","")],saved_at=info.get("saved_at","")})
	entries.sort_custom(func(a,b):return a.saved_at>b.saved_at)
	return entries

func _toggle_saves() -> void:
	if worker!=null or starting:return
	page="services" if page=="saves" else "saves";search.text="";selected={};refresh();roster.grab_focus()

func _continue() -> void:
	if not saves.is_empty():_begin("save",saves[0])

func start_selected() -> void:
	if selected.is_empty():return
	_begin("service" if page=="services" else "save",selected)

func _begin(kind: String,row: Dictionary) -> void:
	if worker!=null or starting:return
	cancelled=false;_set_status("");busy_panel.show();busy_label.text="Loading "+row.name+"…\nRestoring the railway; no day-long simulation needed."
	content.hide();cancel_button.grab_focus()
	worker=Thread.new()
	var error:=worker.start(_read_request.bind(kind,row.duplicate(true)))
	if error!=OK:worker=null;busy_panel.hide();content.show();_set_status("Could not start loading: "+error_string(error));roster.grab_focus()

func _read_request(kind: String,row: Dictionary) -> Dictionary:
	if kind=="service":
		var result:=Starts.load_start(row,directory)
		if result.ok:result.service=row.id;result.timetable_id=timetable_id
		return result
	var saved:=store.read_slot(row.slot,row.backup)
	if not saved.ok:return saved
	var result:=Snapshot.restore(saved.data.checkpoint)
	if result.ok:
		var issue:=preload("res://game/save_validation.gd").check(result.world,result.session)
		if not issue.is_empty():return Snapshot.error(issue)
	return result

func _process(delta: float) -> void:
	if save_worker!=null and not save_worker.is_alive():
		saves=save_worker.wait_to_finish();save_worker=null
		continue_button.text="Continue latest save";continue_button.disabled=saves.is_empty();saved_button.disabled=false
	if worker!=null:
		if worker.is_alive():return
		var result: Dictionary=worker.wait_to_finish();worker=null
		if quitting:get_tree().quit();return
		if cancelled:busy_panel.hide();content.show();roster.grab_focus();return
		if not result.ok:busy_panel.hide();content.show();_set_status(result.reason);roster.grab_focus();return
		starting=true;busy_label.text="Loading the train and nearby scenery…"
		if result.has("service"):
			Starts.select(result.world,result.service)
			Days.stage_start(get_tree(),result)
		else:get_tree().set_meta("resume_session",result)
		get_tree().change_scene_to_file.call_deferred("res://game/main.tscn")
		return
	if not _focused or starting or roster==null:return
	if sort_button.get_popup().visible or timetable_picker.get_popup().visible:_axes=Vector2.ZERO;_scroll_axis=0;return
	if absf(_scroll_axis)>.25:detail_scroll.scroll_vertical+=roundi(_scroll_axis*delta*650)
	var direction:=Vector2i(signi(roundi(_axes.x)),signi(roundi(_axes.y)))
	if direction==Vector2i.ZERO:_direction=direction;_repeat=0;return
	_repeat-=delta
	if direction!=_direction or _repeat<=0:
		_navigate(direction);_repeat=.35 if direction!=_direction else .13;_direction=direction

func _navigate(direction: Vector2i) -> void:
	var focus:=get_viewport().gui_get_focus_owner()
	if focus==null:roster.grab_focus();return
	if focus==roster and direction.y!=0 and not shown.is_empty():
		var indices:=roster.get_selected_items();var index: int=(indices[0] if not indices.is_empty() else 0)+direction.y
		if index<0:filters[period].grab_focus();return
		if index>=shown.size():start_button.grab_focus();return
		roster.select(index);_select(index);roster.ensure_current_is_visible();return
	if focus==roster and direction.x<0:filters[period].grab_focus();return
	if focus==roster and direction.x>0:start_button.grab_focus();return
	if focus==start_button and direction.x<0:roster.grab_focus();return
	var side:=SIDE_RIGHT if direction.x>0 else SIDE_LEFT if direction.x<0 else SIDE_BOTTOM if direction.y>0 else SIDE_TOP
	var next:=focus.find_valid_focus_neighbor(side)
	if next!=null:next.grab_focus()

func _input(event: InputEvent) -> void:
	if not _focused or roster==null:return
	if sort_button.get_popup().visible or timetable_picker.get_popup().visible:return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_F11 or (event.keycode==KEY_ENTER and event.alt_pressed):display.toggle();accept_event()
		elif event.keycode==KEY_ESCAPE:_back();accept_event()
	if event is InputEventJoypadMotion:
		if event.axis==JOY_AXIS_LEFT_X:_axes.x=event.axis_value
		if event.axis==JOY_AXIS_LEFT_Y:_axes.y=event.axis_value
		if event.axis==JOY_AXIS_RIGHT_Y:_scroll_axis=event.axis_value
		accept_event()
	if not event is InputEventJoypadButton or not event.pressed:return
	accept_event()
	if event.button_index==JOY_BUTTON_B:_back();return
	if worker!=null or starting:return
	match event.button_index:
		JOY_BUTTON_DPAD_UP:_navigate(Vector2i.UP)
		JOY_BUTTON_DPAD_DOWN:_navigate(Vector2i.DOWN)
		JOY_BUTTON_DPAD_LEFT:_navigate(Vector2i.LEFT)
		JOY_BUTTON_DPAD_RIGHT:_navigate(Vector2i.RIGHT)
		JOY_BUTTON_LEFT_SHOULDER:set_period(period-1)
		JOY_BUTTON_RIGHT_SHOULDER:set_period(period+1)
		JOY_BUTTON_X:
			if page=="services":sort_mode=posmod(sort_mode+1,SORTS.size());refresh()
		JOY_BUTTON_Y:set_detail_mode(1-detail_mode)
		JOY_BUTTON_A:
			var focus:=get_viewport().gui_get_focus_owner()
			if focus==roster:start_button.grab_focus()
			elif focus==sort_button:sort_button.show_popup()
			elif focus==timetable_picker:timetable_picker.show_popup()
			elif focus is Button and not focus.disabled:focus.pressed.emit()

func _back() -> void:
	if worker!=null:_cancel()
	elif page=="saves":_toggle_saves()
	else:roster.grab_focus()

func _cancel() -> void:
	if worker!=null:cancelled=true;busy_label.text="Finishing the current load before returning…"

func _quit() -> void:
	if worker!=null:quitting=true;_cancel()
	else:get_tree().quit()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:_quit()
	elif what==NOTIFICATION_APPLICATION_FOCUS_OUT:_focused=false;_axes=Vector2.ZERO;_scroll_axis=0.0
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN:_focused=true;_axes=Vector2.ZERO;_scroll_axis=0.0

func _exit_tree() -> void:
	if worker!=null:worker.wait_to_finish();worker=null
	if save_worker!=null:save_worker.wait_to_finish();save_worker=null
