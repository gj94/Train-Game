extends PanelContainer
## A browsable controller reference; tabs never operate the train.
const PAGES := [
	["DRIVING","You stay in control in pilot, head-out and following exterior views.",[
		["RT / LT","Combined handle","RT increases, LT decreases. Release to hold. A short pause and vibration mark coast; release/re-pull to cross immediately."],
		["B","Sound horn","Available while driving or watching your train from a following camera."],
		["X","Let AI drive","Tap and release. AI takes over without moving your viewpoint."],
		["HOLD X","Take manual control","Hold 0.65 seconds from pilot or a following view. The handle starts at coast; release controls before driving."],
		["Y","Leave the seat","Stand inside the cab. AI takes over automatically."],
		["RB / LB","Power down / brake release","Hold RB to reduce power; hold LB to release the brake. Both stop at coast and never enter the opposite range. Emergency brake remains in the menu / keyboard Space."]]],
	["WALKING","Explore the moving train while AI handles the driving.",[
		["LS / RS","Move / look","Left stick walks and strafes within the carriage. Right stick looks around."],
		["L3","Walk / run","Click the left stick to toggle running. Triggers never operate traction on foot."],
		["A","Interact / sit","Use the highlighted seat, door or gangway. At a stopped platform, use a doorway to alight or board."],
		["Y","Stand / driver seat","Stand from a passenger seat. When walking beside driving controls, sit at them. Hold X separately to take over."],
		["UP / DOWN","Adjacent carriage","Tap D-pad up toward the loco, down toward the tail. Arrive standing with AI driving, including WAP passenger coaches."],
		["HOLD ↑ / ↓","Return to locomotive","Hold either vertical D-pad direction to arrive standing at the loco. RB toggles your torch."]]],
	["CAMERAS","Tap changes the view. Hold returns you to the cab.",[
		["LEFT / RIGHT","Head-out first","From pilot, the first D-pad tap looks out on that side. Further taps cycle close, far, rear and head-out follow views."],
		["HOLD ← / →","Return to pilot","Hold either horizontal D-pad direction. The current driver stays in control; returning does not take over from AI."],
		["LS / RS","Compose / look","In following views, LS changes distance and angle without detaching. RS looks or orbits."],
		["R3 / HOLD R3","Recenter / passenger seat","Tap to reset look. Hold to return to your remembered passenger seat with AI driving; hold while seated to remember that seat and view direction."],
		["SEATED ← / →","Passenger row head-out","After sitting with A, cycle left / interior / right from that same row. Y stands; AI continues driving."],
		["FREE VIEW","Platform observer","Pause → Train & camera → Cameras & walking → Free camera. LS moves, RS looks, RT/LT zoom; AI drives."]]],
	["MENUS","The same buttons confirm and cancel throughout the interface.",[
		["MENU","Pause / settings","LB/RB switches Journey, Train & camera, Settings, Reference and Session. Each section remembers its selection."],
		["VIEW","Dispatch / progress","Tap for Dispatch. Hold 0.65 seconds for journey progress without opening the desk first."],
		["A / B","Confirm / back","A selects or interacts. B returns to the previous page; it never sounds the horn in a menu."],
		["LS / D-PAD","Navigate","Move focus. Use right stick to scroll; LB/RB switch areas, or guide tabs here."],
		["DISPATCH","Navigate the railway","X finds YOUR train; Y follows the inspected train. LB/RB switches map, services, inspector and activity. On map: LS pan, triggers zoom, D-pad targets; View timetable."],
		["RECONNECT","Release to resume","Disconnect pauses the railway. After reconnecting or closing a menu, release all controls before driving."]]],
	["JOURNEYS","Find a departure, board as a passenger, or resume your saved railway.",[
		["A / B","Choose before boarding","In the departure roster, A moves to the explicit Drive action. Move right for Ride as passenger. B returns to the roster before Home."],
		["L3 / X / Y","Favourites / sort / details","In departures, L3 stars the selected service, X changes sort and Y switches stops/traffic. Favourites are separate for each timetable; RS scrolls details."],
		["DROPDOWNS","Pickers without surprises","A opens or confirms, B cancels. LS/D-pad moves; LB/RB pages choices. Shoulder buttons stay inside an open stock, timetable, sort or station picker."],
		["EXPLORE TIME","Find nearby services","Outside a picker, LB/RB steps five minutes. Near station lists services within 15 km along the line. X locates the selected train; Y fits the route."],
		["PASSENGER SEAT","Let the railway drive","Ride or Passenger seat boards with AI driving. Carriage menus find an empty seat; Hold R3 recalls your remembered seat. Skip settings can return you there after advancing time."],
		["CONTINUE","Know where you return","Highlight Continue to preview service, time, seat and progress. Backups are labelled. Loads resume paused; B cancels back to the menu you started from."]]]
]
var page := 0
var tabs: Array[Button] = []
var cards: GridContainer
var subtitle: Label
var scroll: ScrollContainer
var back: Button
var go_back: Callable

func label(text: String, size: int, color: Color=Color("e1ecef")) -> Label:
	var node:=Label.new();node.text=text;node.add_theme_font_size_override("font_size",size)
	node.add_theme_color_override("font_color",color);return node
func panel(color: Color) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=color;style.set_corner_radius_all(10)
	style.set_content_margin_all(18);return style
func _ready() -> void:
	theme=preload("res://game/menu_theme.gd").theme()
	add_theme_stylebox_override("panel",panel(Color("101b28")))
	var col:=VBoxContainer.new();col.add_theme_constant_override("separation",14);add_child(col)
	col.add_child(label("YOUR CONTROLLER",27,Color("ffca72")))
	var nav:=HBoxContainer.new();nav.add_theme_constant_override("separation",10);col.add_child(nav)
	for i in PAGES.size():
		var button:=Button.new();button.text=PAGES[i][0];button.toggle_mode=true
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.custom_minimum_size.y=46
		button.pressed.connect(func():open(i));nav.add_child(button);tabs.append(button)
	subtitle=label("",18,Color("a8c4ce"));subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;col.add_child(subtitle)
	scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;col.add_child(scroll)
	cards=GridContainer.new();cards.columns=2;cards.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("h_separation",12);cards.add_theme_constant_override("v_separation",12);scroll.add_child(cards)
	var footer:=HBoxContainer.new();col.add_child(footer)
	var note:=label("LB / RB tabs   ·   RS scroll   ·   Hold = 0.65 seconds",16,Color("a8c4ce"))
	note.size_flags_horizontal=Control.SIZE_EXPAND_FILL;footer.add_child(note)
	back=Button.new();back.text="B  Back";back.custom_minimum_size=Vector2(130,44)
	back.pressed.connect(func():go_back.call());footer.add_child(back)
	get_viewport().size_changed.connect(resize)
	resize();open(0)
func resize() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var half: Vector2=(get_viewport().get_visible_rect().size-Vector2(32,32)).min(Vector2(1120,820))*.5
	offset_left=-half.x;offset_right=half.x;offset_top=-half.y;offset_bottom=half.y
	cards.columns=1 if half.x<410 else 2
func open(index: int) -> void:
	page=posmod(index,PAGES.size())
	for i in tabs.size():tabs[i].set_pressed_no_signal(i==page)
	subtitle.text=PAGES[page][1]
	for child in cards.get_children():cards.remove_child(child);child.queue_free()
	for row in PAGES[page][2]:
		var card:=PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel",panel(Color("1d2b3a")))
		cards.add_child(card)
		var col:=VBoxContainer.new();col.add_theme_constant_override("separation",7);card.add_child(col)
		col.add_child(label(row[0],19,Color("8bdac3")))
		col.add_child(label(row[1],20))
		var body:=label(row[2],17,Color("c0d0d6"));body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size.y=76;col.add_child(body)
	scroll.scroll_vertical=0
	tabs[page].grab_focus()
