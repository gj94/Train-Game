extends SceneTree
## Real viewport input/GUI integration, with a synthetic standard-layout pad.
var game
var pad
var failures := 0
var checks := 0
const DEVICE := 13

func _initialize() -> void:
	set_meta("traffic_seed", 2)
	set_meta("route", "southern_corridor") # pin six-service fixture, independent of release default
	call_deferred("run_check")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("Controller FAIL: ",label)

func frames() -> void:
	await process_frame
	await process_frame
	pad._process(.016)

func button(index: int, pressed: bool, device: int = DEVICE) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = index
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func tap(index: int) -> void:
	button(index,true)
	await frames()
	button(index,false)
	await frames()

func axis(index: int, value: float, device: int = DEVICE) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = index
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func focus_action(action: String) -> void:
	for child in game.hud._buttons.get_children():
		if child.get_meta("action", "") == action:
			child.grab_focus()
			await tap(JOY_BUTTON_A)
			return
	check(false,"missing menu action: "+action)

func screenshot(name: String) -> void:
	if "--screenshots" not in OS.get_cmdline_user_args(): return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/controller-"+name+".png")

func run_check() -> void:
	change_scene_to_file("res://game/main.tscn")
	await process_frame
	await process_frame
	game = current_scene
	pad = game.controller
	pad.tsw_layout = false # Preserve regression coverage of the optional legacy layout.
	pad.settings_path = "res://.local/controller-test.cfg"
	game.set_process(false)
	game.set_physics_process(false)
	game.cam.set_process(false)
	pad.set_process(false)
	game.dispatcher.set_process(false)
	for sound in game.train_audio.values(): sound.set_process(false)
	game.dispatcher.auto_dispatch = false
	pad.window_focus(true)
	pad._adopt(DEVICE)
	pad._set_mode(true)
	await frames()
	check(game.world.trains.size() == 6 and pad._armed,"six-service startup arms only after neutral")
	game.train.controller = 0
	axis(JOY_AXIS_TRIGGER_RIGHT,.03)
	game._physics_process(.2)
	check(game.train.controller == 0,"trigger noise does not drive")
	axis(JOY_AXIS_TRIGGER_RIGHT,.53)
	check(absf(pad.drive_input()-.5) < .001,"analog half-trigger shaping")
	game._physics_process(.2)
	check(game.train.controller > 0 and game.train.controller < .2,"RT changes actual train handle proportionally")
	axis(JOY_AXIS_TRIGGER_LEFT,1)
	check(pad.drive_input() == -1,"brake wins simultaneous triggers")
	axis(JOY_AXIS_TRIGGER_RIGHT,0)
	axis(JOY_AXIS_TRIGGER_LEFT,0)
	var handle: float = game.train.controller
	game._physics_process(.2)
	check(game.train.controller == handle,"released triggers hold handle")
	axis(JOY_AXIS_TRIGGER_RIGHT,1,DEVICE+1)
	check(pad.drive_input() == 0,"second device cannot move selected train")
	await tap(JOY_BUTTON_X)
	check(game.train.controller == 0,"X coasts")
	await tap(JOY_BUTTON_A)
	check(game.train.automatic,"A enables AI exactly once")
	axis(JOY_AXIS_TRIGGER_LEFT,.8)
	game._physics_process(.1)
	check(not game.train.automatic,"deliberate trigger takes manual control")
	axis(JOY_AXIS_TRIGGER_LEFT,0)
	await tap(JOY_BUTTON_B)
	check(game.train.emergency,"B emergency")
	game.train.speed = 0
	await tap(JOY_BUTTON_B)
	check(not game.train.emergency,"B releases emergency at a stand")
	await tap(JOY_BUTTON_Y)
	check(game.cam.mode == 0,"Y enters exterior")
	var yaw: float = game.cam.yaw
	axis(JOY_AXIS_RIGHT_X,1)
	pad._process(.5)
	check(game.cam.yaw < yaw,"right stick orbits exterior")
	axis(JOY_AXIS_RIGHT_X,0)
	axis(JOY_AXIS_LEFT_X,1)
	pad._process(.5)
	check(not game.cam.follow,"left stick pans independently")
	axis(JOY_AXIS_LEFT_X,0)
	await tap(JOY_BUTTON_RIGHT_STICK)
	check(game.cam.mode==0 and not game.cam.follow,"R3 selects detached exterior")
	var distance: float = game.cam.distance
	button(JOY_BUTTON_RIGHT_SHOULDER,true)
	pad._process(.5)
	button(JOY_BUTTON_RIGHT_SHOULDER,false)
	check(game.cam.distance < distance,"RB zooms")
	await tap(JOY_BUTTON_DPAD_DOWN)
	check(game.cam.mode == 2,"D-pad last coach enters passenger view")
	var last: int = game.tv.passenger_coach
	await tap(JOY_BUTTON_DPAD_UP)
	check(game.tv.passenger_coach < last,"D-pad first/last coach positions differ")
	await tap(JOY_BUTTON_DPAD_RIGHT)
	check(game.tv.passenger_coach > 0,"D-pad next coach")
	var bay: int = game.tv.passenger_bay
	axis(JOY_AXIS_LEFT_X,1)
	pad._process(.02)
	axis(JOY_AXIS_LEFT_X,0)
	pad._process(.02)
	check(game.tv.passenger_bay != bay,"left stick moves within passenger coach")
	axis(JOY_AXIS_RIGHT_X,1)
	pad._process(20)
	check(absf(game.cam._look.x) <= game.cam.cab_yaw_limit+.00001,"passenger look stays bounded")
	axis(JOY_AXIS_RIGHT_X,0)
	await tap(JOY_BUTTON_RIGHT_STICK)
	check(game.cam.mode==0 and not game.cam.follow,"R3 leaves passenger view for external free")
	await tap(JOY_BUTTON_START)
	check(game.paused and game.hud.modal == "pause","Menu pauses")
	await screenshot("pause")
	axis(JOY_AXIS_TRIGGER_RIGHT,1)
	var before: float = game.world.time
	game._physics_process(1)
	check(game.world.time == before and pad.drive_input() == 0,"modal blocks clock and triggers")
	await tap(JOY_BUTTON_A)
	check(not game.paused and game.hud.modal == "","A activates focused resume exactly once")
	check(pad.drive_input() == 0,"held RT cannot leak across resume")
	axis(JOY_AXIS_TRIGGER_RIGHT,0)
	await frames()
	axis(JOY_AXIS_TRIGGER_RIGHT,1)
	check(pad.drive_input() == 1,"neutral then deliberate trigger restores driving")
	axis(JOY_AXIS_TRIGGER_RIGHT,0)
	await tap(JOY_BUTTON_START)
	await tap(JOY_BUTTON_DPAD_DOWN)
	check(root.gui_get_focus_owner().get_meta("action","") == "fullscreen","D-pad reaches the prominent fullscreen action")
	await tap(JOY_BUTTON_DPAD_DOWN)
	check(root.gui_get_focus_owner().get_meta("action","") == "progress","D-pad reaches progress after fullscreen")
	await tap(JOY_BUTTON_DPAD_DOWN)
	check(root.gui_get_focus_owner().get_meta("action","") == "help","D-pad reaches help after progress")
	await tap(JOY_BUTTON_A)
	check(game.hud.modal == "help" and "XBOX CONTROLLER" in game.hud._body.text,"Help contains scenario and controller reference")
	axis(JOY_AXIS_RIGHT_Y,1)
	pad._process(1)
	check(game.hud._body.get_v_scroll_bar().value > 0,"RS scrolls help")
	axis(JOY_AXIS_RIGHT_Y,0)
	await tap(JOY_BUTTON_B)
	await focus_action("controllers")
	check(game.hud.modal == "controllers","controller settings reachable")
	var old_deadzone: float = pad.deadzone
	await focus_action("pad_setting:deadzone")
	check(pad.deadzone != old_deadzone and FileAccess.file_exists(pad.settings_path),"A changes and saves deadzone")
	var saved_deadzone: float = pad.deadzone
	pad.deadzone = .4
	pad._load_settings()
	check(pad.deadzone == saved_deadzone,"settings reload persists")
	await focus_action("pad_setting:defaults")
	check(pad.tsw_layout,"defaults select TSW-style layout")
	pad.tsw_layout=false
	await screenshot("settings")
	await tap(JOY_BUTTON_B)
	await focus_action("controller_actions")
	await focus_action("train_controls")
	await focus_action("points")
	check(game.hud._buttons.get_child_count() == game.world.graph.switches.size()+1,"all manual points listed")
	var unlocked := ""
	var locked := ""
	for id in game.world.graph.switches:
		if game.world.switch_lock_reason(id).is_empty(): unlocked = id
		else: locked = id
	check(not unlocked.is_empty() and not locked.is_empty(),"point fixture includes free and locked points")
	if not unlocked.is_empty():
		var original: bool = game.world.graph.switches[unlocked].reversed
		await focus_action("padpoint:"+unlocked)
		check(game.world.graph.switches[unlocked].reversed != original,"controller throws a free point")
		await focus_action("padpoint:"+unlocked)
	if not locked.is_empty():
		var original: bool = game.world.graph.switches[locked].reversed
		await focus_action("padpoint:"+locked)
		check(game.world.graph.switches[locked].reversed == original,"controller cannot throw occupied/locked point")
	await tap(JOY_BUTTON_B)
	await focus_action("quit")
	await tap(JOY_BUTTON_B)
	check(game.hud.modal == "pause" and not game.train.emergency,"B cancels confirmation without emergency leak")
	# Native focus traversal must reach every enabled pause control and scroll.
	game.hud.focus_first()
	var visited := {}
	for i in game.hud._buttons.get_child_count():
		visited[root.gui_get_focus_owner().get_meta("action","")] = true
		await tap(JOY_BUTTON_RIGHT_SHOULDER)
	check(visited.size() == game.hud._buttons.get_child_count(),"bumper navigation reaches every pause action")
	await tap(JOY_BUTTON_B)
	pad.shortcut("dispatch");await frames()
	check(game.dispatcher._root.visible,"dispatch menu action opens desk")
	check(game.dispatcher._map.has_focus(),"desk starts with map focus")
	var map_center: float=game.dispatcher._map.center_s
	axis(JOY_AXIS_LEFT_X,1);pad._process(.5);axis(JOY_AXIS_LEFT_X,0)
	check(game.dispatcher._map.center_s!=map_center,"left stick pans dispatcher")
	var map_span: float=game.dispatcher._map.span
	axis(JOY_AXIS_TRIGGER_RIGHT,1);pad._process(.5);axis(JOY_AXIS_TRIGGER_RIGHT,0)
	check(game.dispatcher._map.span<map_span and pad.drive_input()==0,"triggers zoom desk without driving")
	game.dispatcher.select_signal(game.dispatcher.source,true)
	game.dispatcher._source.grab_focus()
	await tap(JOY_BUTTON_A)
	check(game.dispatcher._source.get_popup().visible,"A opens native signal dropdown")
	var selected: int = game.dispatcher._source.selected
	await tap(JOY_BUTTON_DPAD_DOWN)
	check(game.dispatcher._source.get_popup().get_focused_item() == selected+1,"one D-pad press moves dropdown exactly one row")
	await tap(JOY_BUTTON_A)
	check(not game.dispatcher._source.get_popup().visible and game.dispatcher._source.selected != selected,"dropdown navigation and accept")
	game.dispatcher._exit.grab_focus()
	await tap(JOY_BUTTON_A)
	await tap(JOY_BUTTON_B)
	check(game.dispatcher._root.visible and pad._popup() == null,"B cancels dropdown before closing desk")
	var route_source := ""
	for id in game.world.signals:
		if id in game.world.automatic_signals: continue
		for option in game.world.route_options(id):
			if game.world.route_reason(id,option.destination).is_empty():
				route_source = id
				game.dispatcher.select_signal(id,true)
				game.dispatcher._select_destination(option.destination)
				break
		if not route_source.is_empty(): break
	check(not route_source.is_empty(),"available safe route fixture")
	if not route_source.is_empty():
		game.dispatcher._set.grab_focus()
		await tap(JOY_BUTTON_A)
		check(not game.world.signals[route_source].route.is_empty(),"A sets selected safe route")
		game.dispatcher._cancel.grab_focus()
		await tap(JOY_BUTTON_A)
		check(game.world.aspect(route_source) == RailWorld.Aspect.RED,"A puts selected signal to red")
	await tap(JOY_BUTTON_BACK)
	# Force real overflow even when the test viewport happens to fit all columns.
	game.dispatcher._timetable._table.set_column_custom_minimum_width(0,1500)
	await frames()
	axis(JOY_AXIS_RIGHT_X,1)
	pad._process(1)
	await frames()
	check(game.dispatcher._timetable._table.get_scroll().x > 0,"RS scrolls native timetable horizontally")
	axis(JOY_AXIS_RIGHT_X,0)
	game.dispatcher._timetable._table.set_column_custom_minimum_width(0,145)
	await frames()
	await screenshot("desk")
	var target := "T1" if game.train.id != "T1" else "T2"
	var assigned: String=game.train.id
	game.dispatcher._roster[target].grab_focus()
	await tap(JOY_BUTTON_A)
	check(game.dispatcher.inspected_train==target and game.train.id==assigned and game.audio.train==game.train,"controller roster inspects without changing driver/audio")
	game.dispatcher._view.grab_focus()
	await tap(JOY_BUTTON_A)
	check(game.train.id==assigned and game.audio.train.id==assigned and game.cam.mode==0,"View train only changes exterior camera")
	game._pilot_camera()
	check(game.cam.follow_point==game.tv.overview_position,"return to pilot restores assigned train follow target")
	game.dispatcher.set_open(true)
	game.dispatcher._take.grab_focus()
	await tap(JOY_BUTTON_A)
	check(game.dispatcher._confirm.visible and game.train.id==assigned,"controller asks before handover")
	await tap(JOY_BUTTON_B)
	check(not game.dispatcher._confirm.visible and game.train.id==assigned,"B cancels handover safely")
	game.dispatcher._take.grab_focus()
	await tap(JOY_BUTTON_A)
	game.dispatcher._confirm_yes.grab_focus()
	await tap(JOY_BUTTON_A)
	check(game.train.id==target and game.audio.train==game.train,"confirmed handover changes driver/audio")
	game.dispatcher.set_open(true)
	await tap(JOY_BUTTON_B)
	check(not game.dispatcher._root.visible and root.gui_get_focus_owner() == null,"closing dispatch releases GUI focus")
	pad._connection_changed(DEVICE,false)
	check(game.paused and game.hud.modal == "pause" and pad.drive_input() == 0,"disconnect pauses safely")
	pad._connection_changed(DEVICE,true)
	await frames()
	check(game.paused,"reconnect does not resume")
	await tap(JOY_BUTTON_B)
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.paused and not pad._focused,"focus loss pauses and disables pad")
	await tap(JOY_BUTTON_B)
	check(game.paused,"unfocused input ignored")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await tap(JOY_BUTTON_B)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	check(game.train.emergency and not pad.controller_mode,"keyboard emergency works after controller UI")
	pad.shortcut("performance")
	game.performance_overlay._process(1)
	check(game.performance_overlay.enabled and "queued impacts" in game.performance_overlay._label.text,"performance diagnostics accessible with controller command")
	pad.shortcut("performance")
	check(not game.performance_overlay.enabled,"performance overlay closes")
	var release := key.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	print("Controller integration: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
