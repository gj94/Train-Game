extends Control
## Lightweight front door: captured railway backdrop, no live world to load.
signal chosen(action: String)
const Style:=preload("res://game/menu_theme.gd")
var buttons: Dictionary={}
var subtitle: Label
var info: Label
var info_heading: Label
var info_title: Label
var _resume_entry: Dictionary={}
var _hints: Dictionary={}
var footer: Label
var options: PanelContainer
var option_list: VBoxContainer
var settings_title: Label
var settings_status: Label
var preferences:=preload("res://game/home_preferences.gd").new()
var guide
var graphics:=preload("res://game/graphics_options.gd").new()
var display:=preload("res://game/display_options.gd").new()
var _background: Texture2D
var _shade: GradientTexture2D
var _last_action:="services"
var _settings_group:=""

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT);theme=Style.theme()
	mouse_filter=MOUSE_FILTER_STOP
	if ResourceLoader.exists("res://assets/ui/kerala_home.png"):_background=load("res://assets/ui/kerala_home.png")
	_shade=GradientTexture2D.new();_shade.width=512;_shade.height=1;_shade.fill_from=Vector2.ZERO;_shade.fill_to=Vector2(1,0)
	_shade.gradient=Gradient.new();_shade.gradient.offsets=PackedFloat32Array([0,.25,.6,1])
	_shade.gradient.colors=PackedColorArray([Color(.015,.035,.05,.98),Color(.015,.035,.05,.93),Color(.015,.035,.05,.40),Color(.015,.035,.05,.10)])
	var margin:=MarginContainer.new();add_child(margin);margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for edge in ["left","right"]:margin.add_theme_constant_override("margin_"+edge,48)
	for edge in ["top","bottom"]:margin.add_theme_constant_override("margin_"+edge,28)
	var col:=VBoxContainer.new();col.add_theme_constant_override("separation",12);margin.add_child(col)
	var top:=HBoxContainer.new();col.add_child(top)
	Style.label(top,"TRAIN GAME   /   INDIAN RAILWAYS",13,Style.ACCENT).size_flags_horizontal=SIZE_EXPAND_FILL
	Style.label(top,"DRIVE. RIDE. EXPLORE.",13,Style.MUTED)
	var space:=Control.new();space.custom_minimum_size.y=18;col.add_child(space)
	var hero:=Style.label(col,"KERALA\nCOAST",68);hero.add_theme_constant_override("line_spacing",-6)
	subtitle=Style.label(col,"277 kilometres. A living railway.",20,Style.ACCENT)
	Style.label(col,"Ernakulam  /  Alappuzha  /  Thiruvananthapuram  /  Nagercoil",15,Style.MUTED)
	var main:=HBoxContainer.new();main.size_flags_vertical=SIZE_EXPAND_FILL;main.add_theme_constant_override("separation",40);col.add_child(main)
	var menu:=VBoxContainer.new();menu.custom_minimum_size.x=360;menu.add_theme_constant_override("separation",6);main.add_child(menu)
	for entry in [["services","Choose your journey","Departures, stops and encounters for every service."],["continue","Continue journey","Resume your most recent saved railway."],["explore","Explore by time","Visit a station or join a service throughout the day."],["saves","Saved journeys","Your manual saves and recovery checkpoints."],["settings","Settings & controls","Tune your experience before you travel."],["quit","Quit to desktop","Leave the railway for now."]]:
		var b:=Button.new();b.text=entry[1];b.alignment=HORIZONTAL_ALIGNMENT_LEFT;Style.button(b,46);b.add_theme_font_size_override("font_size",20)
		b.add_theme_stylebox_override("normal",Style.box(Color(.035,.07,.10,.82),12,Color(.23,.35,.40,.35)))
		menu.add_child(b);buttons[entry[0]]=b
		b.pressed.connect(func():_activate(entry[0]))
		_hints[entry[0]]=entry[2]
		b.focus_entered.connect(func():_last_action=entry[0];_show_hint(entry[0]))
		b.mouse_entered.connect(func():_show_hint(entry[0]))
	var right:=VBoxContainer.new();right.size_flags_horizontal=SIZE_EXPAND_FILL;main.add_child(right)
	var fill:=Control.new();fill.size_flags_vertical=SIZE_EXPAND_FILL;right.add_child(fill)
	var card:=PanelContainer.new();card.add_theme_stylebox_override("panel",Style.box(Color(.025,.06,.09,.86),20));right.add_child(card)
	var notes:=VBoxContainer.new();notes.add_theme_constant_override("separation",10);card.add_child(notes)
	info_heading=Style.label(notes,"ONE RAILWAY. YOUR WAY TO TRAVEL.",12,Style.ACCENT)
	info_title=Style.label(notes,"Take the controls, find a window seat, or watch the traffic from a platform.",22)
	info_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	info=Style.label(notes,"Departures, stops and encounters for every service.",16,Style.MUTED);info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	Style.divider(col)
	var bottom:=HBoxContainer.new();col.add_child(bottom)
	footer=Style.label(bottom,"A / Enter select     D-pad / LS navigate     F11 fullscreen",14,Style.MUTED);footer.size_flags_horizontal=SIZE_EXPAND_FILL
	Style.label(bottom,preload("res://game/build_version.gd").current(),12,Style.MUTED)
	options=PanelContainer.new();add_child(options);options.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	options.add_theme_stylebox_override("panel",Style.box(Style.INK,36));options.hide()
	var opt:=VBoxContainer.new();opt.add_theme_constant_override("separation",16);options.add_child(opt)
	Style.label(opt,"MAKE YOURSELF AT HOME",13,Style.ACCENT);settings_title=Style.label(opt,"Settings & controls",36)
	var scroll:=ScrollContainer.new();scroll.follow_focus=true;scroll.size_flags_vertical=SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;opt.add_child(scroll)
	option_list=VBoxContainer.new();option_list.size_flags_horizontal=SIZE_EXPAND_FILL;option_list.add_theme_constant_override("separation",8);scroll.add_child(option_list)
	settings_status=Style.label(opt,"Changes are saved for your next journey.  B / Esc back",15,Style.MUTED)
	settings_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	guide=preload("res://game/controller_guide.gd").new()
	guide.go_back=func():guide.hide();show_settings();focus_setting("Controller layout")
	# The guide must be a sibling of the settings panel, above it.
	if guide.get_parent()==null:add_child(guide)
	guide.hide();resized.connect(queue_redraw)
	resized.connect(_fit.bind(margin,col,hero,space));_fit(margin,col,hero,space)

func _fit(margin: MarginContainer, col: VBoxContainer, hero: Label, space: Control) -> void:
	var compact:=size.y<800
	col.add_theme_constant_override("separation",8 if compact else 12)
	hero.add_theme_font_size_override("font_size",50 if compact else 68)
	space.custom_minimum_size.y=6 if compact else 18
	for edge in ["top","bottom"]:margin.add_theme_constant_override("margin_"+edge,22 if compact else 28)
	for b in buttons.values():b.custom_minimum_size.y=42 if compact else 46

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("0b1721"))
	if _background!=null:
		var scale_factor:=maxf(size.x/_background.get_width(),size.y/_background.get_height())
		var extent:=_background.get_size()*scale_factor
		draw_texture_rect(_background,Rect2((size-extent)*.5,extent),false)
	if _shade!=null:draw_texture_rect(_shade,Rect2(Vector2.ZERO,size),false)
	for i in 32:
		var y:=float(i)/32
		draw_rect(Rect2(0,y*size.y,size.x,size.y/32+1),Color(.015,.035,.05,pow(y,4)*.65))

func _activate(action: String) -> void:
	if action=="settings":show_settings()
	else:chosen.emit(action)

func open() -> void:
	show();options.hide();guide.hide();buttons.get(_last_action,buttons.services).grab_focus()

func update_saves(entries: Array, checking: bool=false) -> void:
	var readable:=entries.filter(func(row):return row.get("readable",true))
	_resume_entry=readable[0].duplicate(true) if not checking and not readable.is_empty() else {}
	buttons.continue.disabled=checking or readable.is_empty()
	buttons.continue.text="Checking saved journeys…" if checking else "Continue journey"
	buttons.continue.tooltip_text="No readable saved journeys yet" if readable.is_empty() else readable[0].name+" · "+readable[0].clock
	if checking or readable.is_empty():buttons.continue.focus_mode=FOCUS_NONE
	else:buttons.continue.focus_mode=FOCUS_ALL
	if _last_action=="continue":_show_hint("continue")

func _show_hint(action: String) -> void:
	if info==null:return
	info_heading.text="ONE RAILWAY. YOUR WAY TO TRAVEL."
	info_title.text="Take the controls, find a window seat, or watch the traffic from a platform."
	info.text=_hints.get(action,"")
	if action!="continue" or _resume_entry.is_empty():return
	var summary: Dictionary=_resume_entry.get("summary",{})
	info_heading.text="RESUME PREVIOUS BACKUP" if _resume_entry.get("backup",false) else "RESUME YOUR RAILWAY"
	info_title.text=str(summary.get("title",_resume_entry.get("name","Saved journey")))
	info.text="%s · %s" % [_resume_entry.get("service",""),_resume_entry.get("clock","")]
	if not str(summary.get("viewpoint","")).is_empty():info.text+="\n"+str(summary.viewpoint)+" · "+str(summary.get("control",""))
	if summary.get("total",0)>0:info.text+="\n%d / %d stops completed" % [summary.get("stops",0),summary.total]
	info.text+="\nSaved "+str(summary.get("saved_at",_resume_entry.get("saved_at","Unknown time")))+" · resumes paused"

func load_feedback(message: String,failed: bool=false) -> void:
	info_heading.text="COULD NOT OPEN JOURNEY" if failed else "BACK AT HOME"
	info_title.text="Your saved journeys are unchanged."
	info.text=message

func show_settings(group: String="") -> void:
	_settings_group=group;graphics.restore();options.show()
	settings_title.text="Settings & controls"
	settings_status.text="Changes are saved for your next journey.  B / Esc back";settings_status.modulate=Color.WHITE
	for c in option_list.get_children():option_list.remove_child(c);c.queue_free()
	_setting("Back",func():back())
	if group.is_empty():
		_setting("Controller layout",func():guide.show();guide.open(0);guide.tabs[0].grab_focus())
		_setting("Controller preferences",func():show_settings("controller"))
		_setting("Sound mixer",func():show_settings("sound"))
		_setting("Display mode · "+("Fullscreen" if display.is_fullscreen() else "Windowed"),func():display.toggle();show_settings();focus_setting("Display mode"))
		_setting("Graphics preset · "+graphics.preset_name(),func():show_settings("presets"))
		for key in graphics.GROUPS:_setting(graphics.GROUPS[key].capitalize(),func():show_settings(key))
	elif group=="controller" or group.begins_with("sound"):
		preferences.build(self,group)
	elif group=="presets":
		settings_title.text="Graphics presets"
		for preset in graphics.PRESETS:_setting(preset+(" · selected" if graphics.preset_name()==preset else ""),func():graphics.preset(preset);var result: int=graphics.save();show_settings(group);focus_setting(preset);preference_result(result))
	else:
		settings_title.text=graphics.GROUPS.get(group,group).capitalize()
		for key in graphics.OPTIONS:
			var spec: Dictionary=graphics.OPTIONS[key]
			if spec.group!=group:continue
			var b:=_setting(spec.label+" · "+graphics.label_for(key),func():
				var index: int=spec.values.find(graphics.values[key]);graphics.set_option(key,spec.values[(index+1)%spec.values.size()]);var result: int=graphics.save();show_settings(group)
				focus_setting(spec.label);preference_result(result))
			b.tooltip_text=spec.help
			var help:=Style.label(option_list,spec.help,15,Style.MUTED);help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	option_list.get_child(0).grab_focus()

func preference_result(result: int) -> void:
	settings_status.text="Saved for your next journey.  B / Esc back" if result==OK else "Could not save preferences. Check access to the user-data folder, then try again."
	settings_status.modulate=Color.WHITE if result==OK else Color("ffb677")

func focus_setting(prefix: String) -> void:
	for child in option_list.get_children():
		if child is Button and child.text.begins_with(prefix):child.grab_focus();return

func _setting(text: String, callback: Callable) -> Button:
	var b:=Button.new();b.text=text;b.alignment=HORIZONTAL_ALIGNMENT_LEFT;Style.button(b,46);option_list.add_child(b);b.pressed.connect(callback);return b

func back() -> void:
	if guide.visible:guide.hide();option_list.get_child(1).grab_focus()
	elif options.visible:
		if _settings_group=="controller" or _settings_group.begins_with("sound"):
			var parent: Dictionary=preferences.parent(_settings_group);show_settings(parent.page);focus_setting(parent.focus)
		elif not _settings_group.is_empty():
			var prefix: String="Graphics preset" if _settings_group=="presets" else graphics.GROUPS.get(_settings_group,_settings_group).capitalize()
			show_settings();focus_setting(prefix)
		else:options.hide();buttons.settings.grab_focus()
	else:buttons.services.grab_focus()

func navigate(direction: Vector2i) -> void:
	var focus:=get_viewport().gui_get_focus_owner()
	if focus==null:buttons.services.grab_focus();return
	var next:=focus.find_valid_focus_neighbor(SIDE_BOTTOM if direction.y>0 else SIDE_TOP if direction.y<0 else SIDE_RIGHT if direction.x>0 else SIDE_LEFT)
	if next!=null:next.grab_focus()

func confirm() -> void:
	var focus:=get_viewport().gui_get_focus_owner()
	if focus is Button and not focus.disabled:focus.pressed.emit()

func scroll(amount: float) -> void:
	if guide.visible:guide.scroll.scroll_vertical+=roundi(amount)
	elif options.visible:option_list.get_parent().scroll_vertical+=roundi(amount)
