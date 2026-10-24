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
var _load_return_home:=false
var _load_return_focus: Control
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
var picker_input:=preload("res://game/menu_picker_input.gd").new()
var display:=preload("res://game/display_options.gd").new()
var home
var browser_preferences:="user://journey_browser.cfg"
var library:=preload("res://game/journey_library.gd").new()
var stock_picker: OptionButton
var favourites_button: Button
var through_button: Button
var favourite_button: Button
var ride_button: Button
var page_title: Label
var browser_footer: Label
var filter_row: HBoxContainer

func _ready() -> void:
	picker_input.use_explicit_controller_navigation()
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	if _bypass():
		get_tree().change_scene_to_file.call_deferred("res://game/main.tscn");return
	if "--script" not in OS.get_cmdline_args():display.restore()
	Engine.max_fps=60;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	get_tree().auto_accept_quit=false
	Input.joy_connection_changed.connect(func(_device,_connected):_axes=Vector2.ZERO;_scroll_axis=0.0;picker_input.reset())
	if not _isolated_browser():library.restore(browser_preferences)
	timetable_id=Days.definition(str(get_tree().get_meta("timetable_id",library.timetable))).id
	if directory==Starts.DIRECTORY:directory=Days.definition(timetable_id).starts
	_build()
	picker_input.connect_pickers([sort_button,timetable_picker,stock_picker])
	_load_catalogue()
	continue_button.disabled=true;continue_button.text="Checking saves…";saved_button.disabled=true
	save_worker=Thread.new()
	if save_worker.start(_saved_entries)!=OK:
		save_worker=null;continue_button.text="Continue latest save";saved_button.disabled=false
	_restore_browser()
	refresh()
	home=preload("res://game/launch_home.gd").new();add_child(home)
	home.chosen.connect(_home_action);home.update_saves([],true)
	content.hide();home.open()
	var restart: String=get_tree().get_meta("launch_service","")
	if not restart.is_empty():
		get_tree().remove_meta("launch_service")
		var passenger: bool=get_tree().get_meta("launch_passenger",false)==true
		if get_tree().has_meta("launch_passenger"):get_tree().remove_meta("launch_passenger")
		for row in services:
			if row.id==restart:
				var choice: Dictionary=row.duplicate(true);choice.passenger_start=passenger
				_begin("service",choice);break

func _set_status(message: String) -> void:
	status.text=message;status.visible=not message.is_empty()

func _load_catalogue() -> void:
	services=[];traffic_data={};_set_status("")
	traffic_reason="Traffic preview is unavailable for this timetable."
	var catalogue:=Starts.catalogue(directory)
	if catalogue.ok:
		if catalogue.data.get("dispatcher","classic")!=Days.definition(timetable_id).dispatcher:
			_set_status("This operating day needs matching dispatcher data. Update the game.");return
		services=catalogue.data.services
		var traffic:=Traffic.catalogue(services,directory)
		if traffic.ok:traffic_data=traffic.data
		else:traffic_reason=traffic.reason
	else:_set_status(catalogue.reason)

func select_timetable(index: int) -> void:
	if worker!=null or starting or index<0 or index>=Days.DAYS.size():return
	_save_browser()
	timetable_id=Days.DAYS[index].id;directory=Days.DAYS[index].starts
	get_tree().set_meta("timetable_id",timetable_id)
	for key in ["timeline_index","timeline_clock"]:
		if get_tree().has_meta(key):get_tree().remove_meta(key)
	timetable_picker.select(index);timetable_description.text=Days.DAYS[index].description;timetable_picker.tooltip_text=Days.DAYS[index].description
	_load_catalogue()
	selected={id=library.selections.get(timetable_id,"K1")};page="services";period=0;search.text="";refresh();roster.grab_focus()

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
	var button:=Button.new();button.text=text;button.custom_minimum_size.y=40
	for state in ["normal","hover","pressed","disabled"]:
		var style:=theme.get_stylebox(state,"Button").duplicate();style.set_content_margin_all(9);button.add_theme_stylebox_override(state,style)
	button.add_theme_font_size_override("font_size",17);parent.add_child(button);button.pressed.connect(action)
	return button

func _box(colour: Color,border: Color=Color("29424c")) -> StyleBoxFlat:
	var box:=StyleBoxFlat.new();box.bg_color=colour;box.border_color=border
	box.set_border_width_all(1);box.set_corner_radius_all(8);box.set_content_margin_all(14)
	return box

func _build() -> void:
	theme=preload("res://game/menu_theme.gd").theme()
	var bg:=ColorRect.new();bg.color=Color("0b1119");add_child(bg);bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var margin:=MarginContainer.new();add_child(margin);margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	content=margin
	for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,24)
	for side in ["top","bottom"]:margin.add_theme_constant_override("margin_"+side,16)
	var outer:=VBoxContainer.new();outer.add_theme_constant_override("separation",8);margin.add_child(outer)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",12);outer.add_child(top)
	var brand:=VBoxContainer.new();brand.size_flags_horizontal=SIZE_EXPAND_FILL;top.add_child(brand)
	_label(brand,"KERALA COAST  /  JOURNEYS",13,Color("86e4be"));page_title=_label(brand,"Find your next departure",28)
	_button(top,"Home",_show_home)
	_button(top,"Explore by time",func():get_tree().change_scene_to_file("res://game/launch_timeline.tscn"))
	continue_button=_button(top,"Continue latest save",_continue)
	saved_button=_button(top,"Saved journeys",_toggle_saves)
	var day_row:=HBoxContainer.new();day_row.add_theme_constant_override("separation",16);outer.add_child(day_row)
	timetable_picker=OptionButton.new();timetable_picker.custom_minimum_size=Vector2(330,42);day_row.add_child(timetable_picker)
	for day in Days.DAYS:timetable_picker.add_item(day.name)
	timetable_picker.select(Days.index_of(timetable_id));timetable_picker.item_selected.connect(select_timetable)
	timetable_description=_label(day_row,Days.definition(timetable_id).description,15,Color("a8bdc6"))
	timetable_description.hide();timetable_picker.tooltip_text=Days.definition(timetable_id).description
	stock_picker=OptionButton.new();stock_picker.custom_minimum_size=Vector2(190,42);day_row.add_child(stock_picker)
	for label in library.STOCK_LABELS:stock_picker.add_item(label)
	stock_picker.item_selected.connect(func(index):library.stock=library.STOCK_KEYS[index];refresh())
	search=LineEdit.new();search.placeholder_text="Search train, station or service ID";search.size_flags_horizontal=SIZE_EXPAND_FILL
	search.clear_button_enabled=true
	day_row.add_child(search);search.text_changed.connect(func(_s):refresh())
	_button(day_row,"Reset",reset_filters)
	filter_row=HBoxContainer.new();filter_row.add_theme_constant_override("separation",8);outer.add_child(filter_row)
	for i in FILTERS.size():
		var index:=i
		var button:=_button(filter_row,FILTERS[i],func():set_period(index));button.toggle_mode=true;filters.append(button)
	favourites_button=_button(filter_row,"Favourites",func():library.favourites_only=not library.favourites_only;refresh());favourites_button.toggle_mode=true
	through_button=_button(filter_row,"Full route",func():library.through_only=not library.through_only;refresh());through_button.toggle_mode=true
	through_button.tooltip_text="Services covering the full Ernakulam–Nagercoil route in either direction."
	var spacer:=Control.new();spacer.size_flags_horizontal=SIZE_EXPAND_FILL;filter_row.add_child(spacer)
	sort_button=OptionButton.new();sort_button.custom_minimum_size=Vector2(320,42);filter_row.add_child(sort_button)
	for text in SORTS:sort_button.add_item(text)
	sort_button.item_selected.connect(func(index):sort_mode=index;refresh())
	var results_row:=HBoxContainer.new();outer.add_child(results_row)
	count_label=_label(results_row,"",16,Color("a8bdc6"));count_label.size_flags_horizontal=SIZE_EXPAND_FILL
	var columns:=HBoxContainer.new();columns.add_theme_constant_override("separation",24);columns.size_flags_vertical=SIZE_EXPAND_FILL;outer.add_child(columns)
	roster=ItemList.new();roster.size_flags_horizontal=SIZE_EXPAND_FILL;roster.size_flags_vertical=SIZE_EXPAND_FILL
	roster.add_theme_font_size_override("font_size",18);roster.add_theme_constant_override("v_separation",16)
	columns.add_child(roster);roster.item_selected.connect(_select);roster.item_activated.connect(func(_i):if not start_button.disabled:start_button.grab_focus())
	var panel:=PanelContainer.new();panel.custom_minimum_size.x=390;panel.size_flags_horizontal=SIZE_EXPAND_FILL;panel.size_flags_stretch_ratio=.75
	panel.add_theme_stylebox_override("panel",_box(Color("141e2a")));columns.add_child(panel)
	var details:=VBoxContainer.new();details.add_theme_constant_override("separation",8);panel.add_child(details)
	var service_header:=HBoxContainer.new();details.add_child(service_header)
	departure=_label(service_header,"",30);departure.size_flags_horizontal=SIZE_EXPAND_FILL
	favourite_button=_button(service_header,"☆",toggle_favourite);favourite_button.tooltip_text="Favourite this service · L3 / F2"
	detail_title=_label(details,"Choose a service",19);detail_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail_tabs=HBoxContainer.new();detail_tabs.add_theme_constant_override("separation",8);details.add_child(detail_tabs)
	stops_tab=_button(detail_tabs,"Stops",func():set_detail_mode(0));stops_tab.toggle_mode=true;stops_tab.size_flags_horizontal=SIZE_EXPAND_FILL
	traffic_tab=_button(detail_tabs,"Traffic",func():set_detail_mode(1));traffic_tab.toggle_mode=true;traffic_tab.size_flags_horizontal=SIZE_EXPAND_FILL
	traffic_summary=_label(details,"",14,Color("a8bdc6"));traffic_summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;details.add_child(scroll)
	detail_scroll=scroll
	var body:=VBoxContainer.new();body.size_flags_horizontal=SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",8);scroll.add_child(body)
	description=_label(body,"",16);description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	calls_grid=GridContainer.new();calls_grid.columns=3;calls_grid.add_theme_constant_override("h_separation",18);calls_grid.add_theme_constant_override("v_separation",8);body.add_child(calls_grid)
	briefing=_label(body,"",16,Color("a8bdc6"));briefing.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	traffic_list=VBoxContainer.new();traffic_list.add_theme_constant_override("separation",12);body.add_child(traffic_list)
	var boarding:=HBoxContainer.new();boarding.add_theme_constant_override("separation",8);details.add_child(boarding)
	start_button=_button(boarding,"Drive this service",start_selected);start_button.custom_minimum_size.y=52;start_button.size_flags_horizontal=SIZE_EXPAND_FILL
	ride_button=_button(boarding,"Ride as passenger",func():start_selected(true));ride_button.custom_minimum_size.y=52;ride_button.size_flags_horizontal=SIZE_EXPAND_FILL
	start_button.add_theme_stylebox_override("normal",_box(Color("253d48"),Color("82d8cd")))
	status=_label(outer,"",16,Color("efc382"));status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	browser_footer=_label(outer,"",15,Color("a8bdc6"));browser_footer.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_label(outer,preload("res://game/build_version.gd").current(),13,Color("7895a2"))
	busy_panel=PanelContainer.new();add_child(busy_panel);busy_panel.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	busy_panel.add_theme_stylebox_override("panel",_box(Color(.02,.06,.08,.98)))
	var center:=CenterContainer.new();busy_panel.add_child(center)
	var loading:=VBoxContainer.new();loading.add_theme_constant_override("separation",24);center.add_child(loading)
	_label(loading,"PREPARING YOUR JOURNEY",28,Color("86e4be"))
	busy_label=_label(loading,"",21)
	busy_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;busy_label.custom_minimum_size.x=720
	_label(loading,"Railway state → Train resources → Nearby scenery → Ready to drive",15,Color("9caebe"))
	_label(loading,preload("res://game/build_version.gd").current(),13,Color("9caebe"))
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
	if worker!=null or starting or page!="services":return
	page="services";period=posmod(value,FILTERS.size());refresh();roster.grab_focus()

func reset_filters() -> void:
	if page=="saves":search.text="";refresh();roster.grab_focus();return
	period=0;search.text="";library.stock="";library.favourites_only=false;library.through_only=false
	refresh();roster.grab_focus()

func toggle_favourite() -> void:
	if page!="services" or selected.is_empty():return
	library.toggle(timetable_id,selected.id);_save_browser();refresh()

func refresh() -> void:
	if worker!=null or starting:return
	page_title.text="Find your next departure" if page=="services" else "Saved journeys"
	filter_row.visible=page=="services";timetable_picker.visible=page=="services";stock_picker.visible=page=="services"
	search.placeholder_text="Search train, station or service ID" if page=="services" else "Search saved service or slot"
	browser_footer.text="D-pad / LS navigate · A select · B back · LB/RB filter · X sort · Y stops/traffic · L3 favourite · RS scroll" if page=="services" else "D-pad / LS navigate · A inspect/select · B back to journeys · RS scroll · Loads resume paused"
	var previous: String=selected.get("id","")
	shown.clear();roster.clear()
	for i in filters.size():filters[i].set_pressed_no_signal(page=="services" and period==i)
	stock_picker.select(maxi(0,library.STOCK_KEYS.find(library.stock)));stock_picker.disabled=page!="services"
	favourites_button.set_pressed_no_signal(library.favourites_only);through_button.set_pressed_no_signal(library.through_only)
	favourites_button.disabled=page!="services";through_button.disabled=page!="services"
	saved_button.text="Back to services" if page=="saves" else "Saved journeys"
	var needle:=search.text.strip_edges().to_lower()
	for row in (services if page=="services" else saves):
		var text: String=row.name+" "+row.id+" "+row.get("origin","")+" "+row.get("destination","")+" "+STOCK.get(row.get("stock",""),"")
		for call in row.get("calls",[]):text+=" "+call.name
		if page=="services" and not library.accepts(row,timetable_id,needle):continue
		if page=="saves" and not needle.is_empty() and not text.to_lower().contains(needle):continue
		if page=="services" and not in_period(row.departure,period):continue
		shown.append(row)
	if page=="services":shown=Briefing.ordered(shown,sort_mode)
	sort_button.disabled=page!="services";sort_button.select(sort_mode)
	for row in shown:
		var text: String=(Briefing.time_text(row.departure)+"  ·  "+row.id+"  ·  "+row.name) if page=="services" else row.name
		var tooltip:=text
		if page=="services":
			text=Briefing.time_text(row.departure)+"   "+row.id+"   "+row.origin.replace(" Junction","").replace(" Central","")+" → "+row.destination.replace(" Junction","").replace(" Central","")
			if library.favourite(timetable_id,row.id):text="★ "+text
			tooltip+="\n"+STOCK.get(row.stock,row.stock)+" · %d calls" % int(row.stops)
		if page=="services" and sort_mode in [1,2]:text="%.1f km/h  ·  " % row.average_kmh+text
		var index:=roster.add_item(text);roster.set_item_tooltip(index,tooltip)
	count_label.text=("%d / %d services · Start at the origin · Dynamic AI traffic" % [shown.size(),services.size()]) if page=="services" else "Saved journeys · Load paused · Previous backups are available"
	start_button.text="Drive this service" if page=="services" else "Load saved journey"
	start_button.disabled=shown.is_empty()
	ride_button.visible=page=="services";ride_button.disabled=shown.is_empty()
	favourite_button.visible=page=="services";favourite_button.disabled=shown.is_empty()
	if shown.is_empty():
		selected={};detail_title.text="No matching journeys";departure.text="";description.text="Try another departure filter or clear the search." if page=="services" else "Clear the search, or save a journey from the pause menu. Recovery checkpoints also appear here."
		description.show();calls_grid.hide();briefing.text="";detail_tabs.hide();traffic_summary.hide();traffic_list.hide();return
	var index:=0
	for i in shown.size():
		if shown[i].id==previous:index=i;break
	roster.select(index);_select(index);roster.ensure_current_is_visible()

func _select(index: int) -> void:
	if index<0 or index>=shown.size():return
	selected=shown[index];detail_title.text=selected.name
	favourite_button.text="★" if library.favourite(timetable_id,selected.id) else "☆"
	detail_scroll.scroll_vertical=0
	for child in calls_grid.get_children():calls_grid.remove_child(child);child.queue_free()
	for child in traffic_list.get_children():traffic_list.remove_child(child);child.queue_free()
	traffic_rows=[];detail_tabs.visible=page=="services";traffic_summary.visible=page=="services"
	calls_grid.visible=page=="services";briefing.text=""
	if page=="saves":
		description.show();briefing.show();traffic_list.hide()
		departure.text=selected.get("clock","")
		start_button.disabled=not selected.get("readable",true)
		start_button.text=("Load previous backup" if selected.get("backup",false) else "Load saved journey") if not start_button.disabled else "Save unavailable"
		if start_button.disabled:
			description.text=selected.get("reason","This save could not be read.")+"\n\n"+("Select this slot's previous backup from the list to recover the earlier version." if selected.get("has_backup",false) else "No readable previous backup was found for this slot. Other saves remain available.")
		else:description.text=preload("res://game/save_summary.gd").describe(selected.get("summary",{}),selected.get("backup",false))+"\n\nThe complete railway and your viewpoint will be restored, paused. Resume when ready."
		return
	departure.text=Briefing.time_text(selected.departure)+" departure"
	var duration:=roundi(float(selected.duration)/60)
	var daylight: float=preload("res://sim/daylight.gd").sample(selected.start_clock).daylight
	var light: String="Night" if daylight<.15 else ("Twilight" if daylight<.9 else "Daylight")
	description.text="%s · %d vehicles\n%d stops · %dh %02dm · %.1f km · %.1f km/h average\n%s · board at %s" % [STOCK.get(selected.stock,selected.stock),selected.cars,selected.stops,duration/60,duration%60,selected.distance_m/1000.0,selected.average_kmh,light,Briefing.time_text(selected.start_clock)]
	for heading in ["SCHEDULED STOPS","ARR","DEP"]:_label(calls_grid,heading,13,Color("86e4be"))
	for i in selected.calls.size():
		var call: Dictionary=selected.calls[i]
		var name_label:=_label(calls_grid,"%02d  %s" % [i+1,call.name],16)
		name_label.size_flags_horizontal=SIZE_EXPAND_FILL;name_label.custom_minimum_size.x=140;name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		_label(calls_grid,"—" if i==0 else Briefing.time_text(call.arrival),16)
		_label(calls_grid,"—" if i==selected.calls.size()-1 else Briefing.time_text(call.departure),16)
	briefing.text="Drive starts paused at the controls. Ride starts in a passenger seat with AI driving. Earlier traffic and delays are preserved."
	if not selected.get("departure_advice","").is_empty():briefing.text+="\n\nDispatcher at departure\n"+selected.departure_advice
	briefing.text+="\n\nCrossings and overtakes are decided dynamically; the signals and dispatcher give current instructions as you drive."
	traffic_rows=Traffic.for_service(traffic_data,selected.id)
	stops_tab.text="Stops · %d" % selected.calls.size();traffic_tab.text="Traffic · %d" % traffic_rows.size() if not traffic_data.is_empty() else "Traffic"
	traffic_summary.text=("Predictive V2 AI baseline · " if Days.definition(timetable_id).dispatcher=="predictive" else "Classic AI baseline · ")+Traffic.summary(traffic_rows) if not traffic_data.is_empty() else "Traffic preview unavailable"
	_build_traffic()
	set_detail_mode(detail_mode)

func set_detail_mode(mode: int) -> void:
	if page!="services" or selected.is_empty():return
	detail_mode=clampi(mode,0,1);detail_scroll.scroll_vertical=0
	stops_tab.set_pressed_no_signal(detail_mode==0);traffic_tab.set_pressed_no_signal(detail_mode==1)
	traffic_summary.visible=detail_mode==1
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
		var card:=PanelContainer.new();var style:=_box(Color("101b28"));style.set_content_margin_all(10);card.add_theme_stylebox_override("panel",style);traffic_list.add_child(card)
		var lines:=VBoxContainer.new();lines.add_theme_constant_override("separation",4);card.add_child(lines)
		var heading:=HBoxContainer.new();lines.add_child(heading)
		_label(heading,Traffic.time_text(event.time),17,Color("86e4be"))
		var kind:=_label(heading,event.role,14,Color("efc382") if event.kind=="overtake" else Color("a8bdc6"));kind.size_flags_horizontal=SIZE_EXPAND_FILL;kind.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		note=_label(lines,event.other+" · "+names.get(event.other,event.other),16);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		note=_label(lines,event.location+(" · route km %.1f" % (event.chainage_m/1000.0) if event.station.is_empty() else ""),14,Color("a8bdc6"));note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

func _saved_entries() -> Array:
	var entries:=[]
	for slot in store.slots():
		if slot.exists and not slot.ok:
			entries.append({id=slot.id,slot=slot.id,backup=false,name=Store.label(slot.id)+" · Unreadable save",readable=false,reason=slot.reason,has_backup=slot.backup,service="",clock="",saved_at="",summary={}})
		for backup in [false,true]:
			if not (slot.backup if backup else slot.ok):continue
			var info: Dictionary=slot.backup_summary if backup else slot.summary
			entries.append({id=slot.id+("-backup" if backup else ""),slot=slot.id,backup=backup,name=(preload("res://persistence/save_store.gd").label(slot.id))+(" · backup" if backup else "")+" · "+str(info.get("title","Journey")),
				service=info.get("service",""),clock="Day %d · %s" % [info.get("day",1),info.get("clock","")],saved_at=info.get("saved_at",""),summary=info.duplicate(true),readable=true})
	entries.sort_custom(func(a,b):return a.saved_at>b.saved_at)
	return entries

func _toggle_saves() -> void:
	if worker!=null or starting:return
	show_browser(page!="saves")

func _continue() -> void:
	for row in saves:
		if row.get("readable",true):_begin("save",row);return

func start_selected(passenger: bool=false) -> void:
	if selected.is_empty() or (page=="saves" and not selected.get("readable",true)):return
	var choice:=selected.duplicate(true)
	if page=="services":choice.passenger_start=passenger
	_begin("service" if page=="services" else "save",choice)

func _begin(kind: String,row: Dictionary) -> void:
	if worker!=null or starting:return
	_load_return_home=home!=null and home.visible
	_load_return_focus=get_viewport().gui_get_focus_owner()
	if home!=null:home.hide()
	cancelled=false;_set_status("");busy_panel.show();busy_label.text="Loading "+row.name+"…\nRestoring the railway; no day-long simulation needed."
	content.hide();cancel_button.grab_focus()
	worker=Thread.new()
	var error:=worker.start(_read_request.bind(kind,row.duplicate(true)))
	if error!=OK:worker=null;_load_finished_without_entry("Could not start loading: "+error_string(error),true)

func _load_finished_without_entry(message: String,failed: bool=false) -> void:
	busy_panel.hide()
	if _load_return_home and home!=null:
		content.hide();home.open()
		if is_instance_valid(_load_return_focus) and _load_return_focus.is_visible_in_tree():_load_return_focus.grab_focus()
		home.load_feedback(message,failed)
	else:
		content.show();roster.grab_focus();_set_status(message)
		if is_instance_valid(_load_return_focus) and _load_return_focus.is_visible_in_tree():_load_return_focus.grab_focus()

func _read_request(kind: String,row: Dictionary) -> Dictionary:
	if kind=="service":
		var result:=Starts.load_start(row,directory)
		if result.ok:
			if result.world.dispatcher().predictive.enabled!=(Days.definition(timetable_id).dispatcher=="predictive"):return Snapshot.error("Prepared journey uses a different dispatcher. Update the game.")
			result.service=row.id;result.timetable_id=timetable_id;result.passenger_start=row.get("passenger_start",false)==true
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
		continue_button.text="Continue latest save";continue_button.disabled=not saves.any(func(row):return row.get("readable",true));saved_button.disabled=false
		if home!=null:home.update_saves(saves)
	if worker!=null:
		if worker.is_alive():return
		var result: Dictionary=worker.wait_to_finish();worker=null
		if quitting:get_tree().quit();return
		if cancelled:_load_finished_without_entry("Loading cancelled.");return
		if not result.ok:_load_finished_without_entry(result.reason,true);return
		starting=true;busy_label.text="Loading the train and nearby scenery…"
		if result.has("service"):
			if not result.get("passenger_start",false):Starts.select(result.world,result.service)
			Days.stage_start(get_tree(),result)
		else:get_tree().set_meta("resume_session",result)
		get_tree().change_scene_to_file.call_deferred("res://game/main.tscn")
		return
	if not _focused or starting or roster==null:return
	if picker_input.update(delta,[sort_button,timetable_picker,stock_picker]):_axes=Vector2.ZERO;_scroll_axis=0;return
	if absf(_scroll_axis)>.25:
		if home!=null and home.visible:home.scroll(_scroll_axis*delta*650)
		else:detail_scroll.scroll_vertical+=roundi(_scroll_axis*delta*650)
	var direction:=Vector2i(0,signi(roundi(_axes.y))) if absf(_axes.y)>=absf(_axes.x) else Vector2i(signi(roundi(_axes.x)),0)
	if direction==Vector2i.ZERO:_direction=direction;_repeat=0;return
	_repeat-=delta
	if direction!=_direction or _repeat<=0:
		_navigate(direction);_repeat=.35 if direction!=_direction else .13;_direction=direction

func _navigate(direction: Vector2i) -> void:
	if home!=null and home.visible:home.navigate(direction);return
	var focus:=get_viewport().gui_get_focus_owner()
	if focus==null:roster.grab_focus();return
	if focus==roster and direction.y!=0 and not shown.is_empty():
		var indices:=roster.get_selected_items();var index: int=(indices[0] if not indices.is_empty() else 0)+direction.y
		if index<0:filters[period].grab_focus();return
		if index>=shown.size():start_button.grab_focus();return
		roster.select(index);_select(index);roster.ensure_current_is_visible();return
	if focus==roster and direction.x<0:
		if page=="services":filters[period].grab_focus()
		else:search.grab_focus()
		return
	if focus==roster and direction.x>0:start_button.grab_focus();return
	if focus==start_button and direction.x<0:roster.grab_focus();return
	if focus in filters and direction.y<0:timetable_picker.grab_focus();return
	if focus==timetable_picker and direction.y>0:filters[period].grab_focus();return
	var side:=SIDE_RIGHT if direction.x>0 else SIDE_LEFT if direction.x<0 else SIDE_BOTTOM if direction.y>0 else SIDE_TOP
	var next:=focus.find_valid_focus_neighbor(side)
	if next!=null:next.grab_focus()

func _input(event: InputEvent) -> void:
	if not _focused or roster==null:return
	if picker_input.handle(event,[sort_button,timetable_picker,stock_picker]):accept_event();return
	if picker_input.active([sort_button,timetable_picker,stock_picker])!=null:return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_F11 or (event.keycode==KEY_ENTER and event.alt_pressed):display.toggle();accept_event()
		elif event.keycode==KEY_ESCAPE:_back();accept_event()
		elif event.keycode==KEY_F2 and content.visible:toggle_favourite();accept_event()
	if event is InputEventJoypadMotion:
		if event.axis==JOY_AXIS_LEFT_X:_axes.x=event.axis_value
		if event.axis==JOY_AXIS_LEFT_Y:_axes.y=event.axis_value
		if event.axis==JOY_AXIS_RIGHT_Y:_scroll_axis=event.axis_value
		accept_event()
	if not event is InputEventJoypadButton or not event.pressed:return
	accept_event()
	if event.button_index==JOY_BUTTON_B:_back();return
	if worker!=null or starting:return
	if home!=null and home.visible:
		match event.button_index:
			JOY_BUTTON_DPAD_UP:home.navigate(Vector2i.UP)
			JOY_BUTTON_DPAD_DOWN:home.navigate(Vector2i.DOWN)
			JOY_BUTTON_DPAD_LEFT:home.navigate(Vector2i.LEFT)
			JOY_BUTTON_DPAD_RIGHT:home.navigate(Vector2i.RIGHT)
			JOY_BUTTON_LEFT_SHOULDER:
				if home.guide.visible:home.guide.open(home.guide.page-1)
			JOY_BUTTON_RIGHT_SHOULDER:
				if home.guide.visible:home.guide.open(home.guide.page+1)
			JOY_BUTTON_A:home.confirm()
		return
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
		JOY_BUTTON_LEFT_STICK:toggle_favourite()
		JOY_BUTTON_A:
			var focus:=get_viewport().gui_get_focus_owner()
			if focus==roster:
				if not start_button.disabled:start_button.grab_focus()
			elif focus==sort_button:sort_button.show_popup()
			elif focus==timetable_picker:timetable_picker.show_popup()
			elif focus==stock_picker:stock_picker.show_popup()
			elif focus is Button and not focus.disabled:focus.pressed.emit()

func _back() -> void:
	if worker!=null:_cancel()
	elif home!=null and home.visible:home.back()
	elif page=="services" and get_viewport().gui_get_focus_owner()!=roster:roster.grab_focus()
	elif page=="saves":_toggle_saves()
	else:_show_home()

func _show_home() -> void:
	if home==null or worker!=null or starting:return
	_save_browser()
	content.hide();home.open()

func show_browser(saved: bool=false) -> void:
	var returning: bool=not saved and page=="saves"
	if saved:_save_browser();search.text=""
	if home!=null:home.hide()
	content.show();page="saves" if saved else "services"
	if returning:_restore_browser()
	refresh();roster.grab_focus()

func _home_action(action: String) -> void:
	match action:
		"services":show_browser()
		"saves":show_browser(true)
		"continue":_continue()
		"explore":get_tree().change_scene_to_file("res://game/launch_timeline.tscn")
		"quit":_quit()

func _restore_browser() -> void:
	selected={id="K1"}
	if _isolated_browser():return
	library.restore(browser_preferences)
	var config:=ConfigFile.new()
	if config.load(browser_preferences)!=OK:return
	sort_mode=clampi(int(config.get_value("browser","sort",0)),0,SORTS.size()-1)
	period=clampi(int(config.get_value("browser","period",0)),0,FILTERS.size()-1)
	selected={id=library.selections.get(timetable_id,str(config.get_value("browser","service","K1")))}
	search.text=str(config.get_value("browser","search","")).left(100)

func _save_browser() -> void:
	if roster==null or page!="services":return
	if _isolated_browser():return
	var config:=ConfigFile.new();config.set_value("browser","sort",sort_mode);config.set_value("browser","period",period)
	config.set_value("browser","service",selected.get("id","K1"));config.set_value("browser","search",search.text)
	library.timetable=timetable_id
	if not selected.is_empty():library.selections[timetable_id]=selected.id
	library.write(config)
	config.save(browser_preferences)

func _isolated_browser() -> bool:
	return browser_preferences.begins_with("user://") and "--script" in OS.get_cmdline_args()

func _cancel() -> void:
	if worker!=null:cancelled=true;busy_label.text="Finishing the current load before returning…"

func _quit() -> void:
	if worker!=null:quitting=true;_cancel()
	else:get_tree().quit()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:_quit()
	elif what==NOTIFICATION_APPLICATION_FOCUS_OUT:_focused=false;_axes=Vector2.ZERO;_scroll_axis=0.0;picker_input.reset()
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN:_focused=true;_axes=Vector2.ZERO;_scroll_axis=0.0

func _exit_tree() -> void:
	_save_browser()
	if worker!=null:worker.wait_to_finish();worker=null
	if save_worker!=null:save_worker.wait_to_finish();save_worker=null
