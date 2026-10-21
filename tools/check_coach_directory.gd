extends SceneTree
const Snapshot:=preload("res://sim/world_snapshot.gd")
const Directory:=preload("res://game/coach_directory.gd")
var game
var checks:=0
var failures:=0
var service:="K1"
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--service="):service=arg.trim_prefix("--service=")
	call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func frames() -> void:
	for i in 3:await process_frame
func button(index: int,pressed: bool) -> void:
	var event:=InputEventJoypadButton.new();event.device=16;event.button_index=index;event.pressed=pressed
	Input.parse_input_event(event);Input.flush_buffered_events()
func tap(index: int) -> void:
	button(index,true);await frames();button(index,false);await frames()
func choose(action: String) -> void:
	game.hud.focus_action(action);await frames()
	var focus:=root.gui_get_focus_owner()
	check(focus!=null and focus.get_meta("action","")==action,"Action reachable: "+action)
	await tap(JOY_BUTTON_A)
func run() -> void:
	var folder:="res://.local/r45/coach-directory"
	DirAccess.make_dir_recursive_absolute(folder)
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	var starts:=preload("res://persistence/service_starts.gd")
	var catalogue:=starts.catalogue()
	if not catalogue.ok:check(false,catalogue.reason);quit(1);return
	var row: Dictionary=catalogue.data.services.filter(func(s):return s.id==service)[0]
	var choice:=starts.load_start(row)
	if not choice.ok:check(false,choice.reason);quit(1);return
	choice.service=service;choice.passenger_start=true;choice.timetable_id="standard"
	preload("res://persistence/operating_days.gd").stage_start(self,choice)
	game=load("res://game/main.tscn").instantiate();game.set_process(false);game.set_physics_process(false);root.add_child(game);current_scene=game
	game.set_process(false);game.set_physics_process(false);game.cam.set_process(false);game.controller.set_process(false);game.dispatcher.set_process(false)
	game.journey_tools.autosaves=false;game.journey_tools.set_process(false);game.journey_tools.save_directory=folder+"/saves"
	game.wv._loading_panel.hide();game.controller.settings_path=folder+"/controller.cfg"
	game.controller.window_focus(true);game.controller._adopt(16);game.controller._set_mode(true)
	game._ui_action("view_controls");await frames()
	var names: Array=game.world.stations.slice(0,3).map(func(st):return st.name+" view")
	var menu_names: Array=game.hud._buttons.get_children().map(func(b):return b.text)
	check(names.all(func(value):return value in menu_names),"Camera menu names the current route's stations")
	check(game._passenger_seated() and game.tv.passenger_seat_index in Directory.available(game.tv,game.train,game.tv.passenger_coach),"Ride starts in an unoccupied seat")
	var before:=var_to_bytes(Snapshot.capture(game.world))
	var remembered: Dictionary=game.passenger_bookmark.current()
	game._ui_action("passengers");await frames()
	await choose("coaches")
	check(game.hud.controller_options.coaches.size()==game.tv.passenger_coaches().size(),"All passenger carriages listed")
	check(game.hud.controller_options.coaches.any(func(c):return "YOU ARE HERE" in c.label),"Current carriage identified")
	check(game.hud.controller_options.coaches.any(func(c):return "Saved seat" in c.label),"Remembered seat identified")
	check(before==var_to_bytes(Snapshot.capture(game.world)),"Inspecting carriage directory preserves railway")
	for resolution in [Vector2i(1280,720),Vector2i(1600,900)]:
		root.size=resolution;root.content_scale_size=resolution;await frames()
		check(root.get_visible_rect().encloses(game.hud._dialog.get_global_rect()),"Carriage modal fits "+str(resolution))
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(folder+"/"+service+"-"+str(resolution.y)+".png")
	var target: int=game.tv.passenger_coaches()[3]
	await choose("coach:"+str(target))
	check(game.walker.active and game.walker.car==target and game.train.automatic and not game.paused,"Selecting carriage stands in its aisle with AI")
	check(game.walker.nav.allowed(game.walker.position,false),"Transferred passenger stands on accessible floor")
	game._ui_action("passengers");await frames();await choose("seat:available")
	check(game._passenger_seated() and game.tv.passenger_coach==target and game.tv.passenger_seat_index in Directory.available(game.tv,game.train,target),"Empty-seat action uses current carriage")
	game._ui_action("passengers");await frames();await tap(JOY_BUTTON_B)
	check(not game.paused and game.hud.modal.is_empty(),"B returns to previous gameplay context")
	check(before==var_to_bytes(Snapshot.capture(game.world)),"Walking/seating transfers preserve complete railway state")
	game.passenger_bookmark.seats[service]=remembered
	game._ui_action("passengers");await frames();await choose("seat:return")
	check(game._passenger_seated() and game.tv.passenger_coach==remembered.car and game.tv.passenger_seat_index==remembered.seat,"Saved-seat action returns across carriages")
	if game.train.stock_kind.begins_with("ported:vb"):
		game.train.cab_end=2;game._pilot_camera();game._set_paused(false)
		var coaches: Array=game.tv.passenger_coaches()
		preload("res://game/controller_camera.gd").step_coach(game,1)
		check(game.walker.active and game.walker.car==coaches[0],"Reverse-ended train enters nearest passenger carriage")
		preload("res://game/controller_camera.gd").step_coach(game,1)
		check(game.walker.car==coaches[1],"Reverse-ended D-pad progresses away from driving cab")
	game._pilot_camera();game.train.automatic=false;game._ui_action("coaches");await frames();await choose("coach:"+str(target))
	check(game.train.automatic and game.walker.active,"Manual driver explicitly hands over when choosing an aisle")
	await game._return_to_landing();await frames()
	print("COACH_DIRECTORY ",service," ",checks," checks, ",failures," failures");quit(1 if failures else 0)
