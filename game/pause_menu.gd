extends Control
## Presentation-only pause hub; existing action handlers retain ownership.
const MenuStyle:=preload("res://game/menu_theme.gd")
const PAGES:=["Journey","Train & camera","Settings","Reference","Session"]
const ENTRIES:=[
	[
		["resume","Resume journey","Return to the railway with your current driving mode."],
		["progress","Journey progress","Your completed calls, next stop and remaining journey."],
		["skip:open","Skip ahead","Advance to your next event, a chosen time or a future stop."],
		["game_speed","Time speed","Choose normal speed or fast-forward the whole railway."],
		["save:quick","Quick save","Keep this railway and your current viewpoint in a quick-save slot."],
		["save:menu:save","Save journey","Choose a named save slot for the complete railway."],
		["save:menu:load","Load journey","Continue a saved run or recover its previous backup."]
	],
	[
		["controller_actions","Driving actions","Hand driving to AI, take control, coast or sound the horn."],
		["view_controls","Cameras & walking","Choose a viewpoint, stand up or move around the train."],
		["passengers","Passenger coaches","Visit another carriage while keeping your assigned service."],
		["padcmd:dispatch","Open dispatcher","Inspect traffic, find your train and manage routes."],
		["clean","Clean view","Hide the driving HUD for an unobstructed view. F4 restores it."],
		["labels","Track labels","Toggle technical track labels in the world."]
	],
	[
		["graphics","Graphics & performance","Choose a preset or tune scenery, shadows, reflections and detail."],
		["audio:open","Sound mixer","Balance rail joints, rolling hiss, wind, traction and other layers."],
		["journey:open","HUD, recovery & tools","Signal hints, recovery saves, bookmarks and local diagnostics."],
		["controllers","Controller preferences","Sensitivity, deadzones, inverted look and vibration."],
		["skip:settings","Time-skip events","Choose the events that bring you back to your journey."],
		["fullscreen","Display mode","Switch between fullscreen and a window. Also available with F11."]
	],
	[
		["controller_guide","Controller layout","Separate driving, walking and camera control diagrams."],
		["help","Scenario & keyboard guide","Understand your service, the railway and keyboard shortcuts."],
		["train_controls","Driving & signalling","Driving commands, protection and route controls."],
		["sound_controls","Sound & diagnostics","Audio tools, rail-contact markers and the performance overlay."]
	],
	[
		["landing","Choose another service","Return to the service browser. Save before leaving this run."],
		["services","Service designer","Create, import and export a timetable for your layout."],
		["fleet","Traffic & solo drives","Choose another scenario or explore a train on its own."],
		["routes","Route selection","Choose the Kerala coast or the Southern corridor."],
		["restart","Restart this run","Start the current services again. Confirmation is required."],
		["quit","Quit to desktop","Leave the game. You will be asked before discarding this run."]
	]
]
var hud
var page:=0
var actions: VBoxContainer
var tabs: Array[Button]=[]
var memories:={}
var context:={}
var _title: Label
var _description: Label
var _service: Label
var _clock: Label
var _next: Label
var _driver: Label
var _index: Label
var _hint: Label
var _labels_on:=false

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT);theme=MenuStyle.theme()
	mouse_filter=MOUSE_FILTER_STOP
	var margin:=MarginContainer.new();add_child(margin);margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,48)
	for side in ["top","bottom"]:margin.add_theme_constant_override("margin_"+side,28)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",18);margin.add_child(column)
	var header:=HBoxContainer.new();column.add_child(header)
	var identity:=VBoxContainer.new();identity.size_flags_horizontal=SIZE_EXPAND_FILL;header.add_child(identity)
	MenuStyle.label(identity,"KERALA COAST   /   JOURNEY PAUSED",13,MenuStyle.ACCENT)
	_service=MenuStyle.label(identity,"Your railway. Your journey.",28);_service.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_clock=MenuStyle.label(header,"",18,MenuStyle.MUTED)
	var navigation:=HBoxContainer.new();navigation.add_theme_constant_override("separation",6);column.add_child(navigation)
	MenuStyle.label(navigation,"LB",14,MenuStyle.ACCENT).vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	for i in PAGES.size():
		var b:=Button.new();b.text=PAGES[i];b.toggle_mode=true;b.size_flags_horizontal=SIZE_EXPAND_FILL
		MenuStyle.button(b,44);navigation.add_child(b);tabs.append(b)
		b.pressed.connect(func():set_page(i))
	MenuStyle.label(navigation,"RB",14,MenuStyle.ACCENT).vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	MenuStyle.divider(column)
	var body:=HBoxContainer.new();body.add_theme_constant_override("separation",36);body.size_flags_vertical=SIZE_EXPAND_FILL;column.add_child(body)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus=true;scroll.size_flags_horizontal=SIZE_EXPAND_FILL;scroll.size_flags_stretch_ratio=.9;body.add_child(scroll)
	actions=VBoxContainer.new();actions.size_flags_horizontal=SIZE_EXPAND_FILL;actions.add_theme_constant_override("separation",8);scroll.add_child(actions)
	var detail:=PanelContainer.new();detail.size_flags_horizontal=SIZE_EXPAND_FILL;detail.add_theme_stylebox_override("panel",MenuStyle.box(Color("101d2a"),28));body.add_child(detail)
	var right:=VBoxContainer.new();right.add_theme_constant_override("separation",20);detail.add_child(right)
	_index=MenuStyle.label(right,"01  /  JOURNEY",13,MenuStyle.ACCENT)
	_title=MenuStyle.label(right,"Resume journey",34);_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_description=MenuStyle.label(right,"",18,MenuStyle.MUTED);_description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var space:=Control.new();space.size_flags_vertical=SIZE_EXPAND_FILL;right.add_child(space)
	MenuStyle.divider(right)
	MenuStyle.label(right,"NEXT SCHEDULED CALL",12,MenuStyle.MUTED)
	_next=MenuStyle.label(right,"",20);_next.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_driver=MenuStyle.label(right,"",15,MenuStyle.ACCENT);_driver.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	MenuStyle.divider(column)
	var footer:=HBoxContainer.new();column.add_child(footer)
	_hint=MenuStyle.label(footer,"",15,MenuStyle.MUTED);_hint.size_flags_horizontal=SIZE_EXPAND_FILL
	MenuStyle.label(footer,preload("res://game/build_version.gd").current(),13,MenuStyle.MUTED)
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),MenuStyle.INK)
	# Subtle railway lines give the shell an identity without loading scene assets.
	for i in 7:
		var x:=size.x*.66+float(i)*78
		draw_line(Vector2(x,0),Vector2(x-size.y*.25,size.y),Color(.15,.27,.35,.13),1,true)

func open(labels_on: bool, state: Dictionary) -> void:
	_labels_on=labels_on;context=state
	_service.text=str(state.get("train_id",""))+"  ·  "+str(state.get("service_name","Your railway journey"))
	_clock.text="DAY %d   %s" % [state.get("world_day",1),state.get("world_clock","—")]
	_next.text=preload("res://game/journey_hud.gd").text(state.get("journey",{}))
	_driver.text=("AI is driving" if state.get("automatic",false) else "You are driving")+"  ·  Clock paused"
	update_input_hint()
	set_page(page,false)

func update_input_hint() -> void:
	_hint.text="LB / RB sections    D-pad / LS navigate    A select    B resume" if hud.controller_active else "Q / E sections    ↑ / ↓ navigate    Enter select    Esc resume"

func remember() -> void:
	var owner:=get_viewport().gui_get_focus_owner()
	if owner!=null and actions.is_ancestor_of(owner):memories[page]=owner.get_meta("action","")

func set_page(value: int, move_focus: bool=true) -> void:
	remember();page=posmod(value,PAGES.size())
	for child in actions.get_children():actions.remove_child(child);child.queue_free()
	for i in tabs.size():tabs[i].set_pressed_no_signal(i==page)
	for entry in ENTRIES[page]:
		var title: String=entry[1]
		if entry[0]=="labels":title+="  ·  "+("On" if _labels_on else "Off")
		var b: Button=hud._button(actions,title,entry[0])
		b.alignment=HORIZONTAL_ALIGNMENT_LEFT;b.custom_minimum_size.y=62
		b.add_theme_font_size_override("font_size",19)
		b.tooltip_text=entry[2]
		b.focus_entered.connect(func():_describe(entry))
		b.mouse_entered.connect(func():_describe(entry))
		if entry[0] in ["quit","restart"]:b.add_theme_color_override("font_color",MenuStyle.DANGER)
	var choices:=actions.get_children()
	for i in choices.size():
		choices[i].focus_neighbor_top=choices[posmod(i-1,choices.size())].get_path()
		choices[i].focus_neighbor_bottom=choices[(i+1)%choices.size()].get_path()
		choices[i].focus_previous=choices[i].focus_neighbor_top;choices[i].focus_next=choices[i].focus_neighbor_bottom
	hud._buttons=actions
	_describe(ENTRIES[page][0])
	if move_focus:focus_first()

func _describe(entry: Array) -> void:
	_index.text="%02d  /  %s" % [page+1,PAGES[page].to_upper()]
	_title.text=entry[1];_description.text=entry[2]

func focus_first() -> void:
	for b in actions.get_children():
		if b.get_meta("action","")==memories.get(page,""):b.grab_focus();return
	if actions.get_child_count()>0:actions.get_child(0).grab_focus()

func focus_action(action: String) -> bool:
	for i in ENTRIES.size():
		for entry in ENTRIES[i]:
			if entry[0]!=action:continue
			if page!=i:set_page(i,false)
			for b in actions.get_children():
				if b.get_meta("action","")==action:b.grab_focus();return true
	return false

func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event is InputEventKey or not event.pressed or event.echo:return
	if event.physical_keycode in [KEY_Q,KEY_E]:
		set_page(page+(-1 if event.physical_keycode==KEY_Q else 1));get_viewport().set_input_as_handled()
