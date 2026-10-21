extends SceneTree
const Snapshot:=preload("res://sim/world_snapshot.gd")
var game
var checks:=0
var failures:=0
var folder:="res://.local/r45/recovery-qol"
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func frames() -> void:
	for i in 4:await process_frame
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(folder+"/"+name+".png")
func freeze(value,saves: String) -> void:
	game=value
	game.set_physics_process(false);game.set_process(false);game.cam.set_process(false);game.controller.set_process(false);game.dispatcher.set_process(false)
	game.journey_tools.set_process(false);game.journey_tools.autosaves=false
	game.save_load.store.directory=saves;game.journey_tools.save_directory=saves
	# The source scene is frozen for menu/state checks; do not obscure the modal
	# with a scenery-loading overlay whose update loop is intentionally stopped.
	if game.geographic_drive:game.wv._loading_panel.hide()
	game.controller.settings_path=folder+"/controller.cfg";game.controller.window_focus(true);game.controller._adopt(16);game.controller._set_mode(true)
func wait_for_scene(previous_id: int) -> bool:
	var began:=Time.get_ticks_msec()
	while current_scene==null or current_scene.get_instance_id()==previous_id:
		await process_frame
		if Time.get_ticks_msec()-began>60000:check(false,"Scene transition timeout");return false
	return true
func run() -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	var saves:=folder+"/run-"+str(Time.get_ticks_usec())
	var starts:=preload("res://persistence/service_starts.gd")
	var catalogue:=starts.catalogue()
	if not catalogue.ok:check(false,catalogue.reason);quit(1);return
	var row: Dictionary=catalogue.data.services.filter(func(s):return s.id=="K1")[0]
	var choice:=starts.load_start(row)
	if not choice.ok:check(false,choice.reason);quit(1);return
	choice.service="K1";choice.passenger_start=true;choice.timetable_id="standard"
	preload("res://persistence/operating_days.gd").stage_start(self,choice)
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	game=load("res://game/main.tscn").instantiate();game.set_physics_process(false);game.set_process(false);root.add_child(game);current_scene=game
	freeze(game,saves)
	scene_changed.connect(func():
		if current_scene!=null and current_scene.has_method("_start_as_passenger"):freeze(current_scene,saves))
	game._set_paused(true);game._passenger_preset(1);game.tv.passenger_seat_index=0;game.tv.passenger_seat=true;game._enter_passenger()
	var before:=Snapshot.capture(game.world)
	check(game.save_load.save("1").ok,"Manual passenger save written")
	var saved: Dictionary=game.save_load.store.read_slot("1")
	check(saved.ok and saved.data.summary.viewpoint.contains("Passenger seat") and saved.data.summary.control=="AI driving","Saved metadata describes passenger role")
	check(game.journey_tools.safeguard("Player recovery test").ok,"Required recovery succeeds with optional autosave disabled")
	var recoveries: Array=game.save_load.store.slots().filter(func(s):return s.id.begins_with("auto") and s.ok)
	check(recoveries.size()==1 and recoveries[0].summary.reason=="Player recovery test","Recovery metadata retains purpose")
	check(var_to_bytes(before)==var_to_bytes(Snapshot.capture(game.world)),"Saving preserves every railway field")
	var blocker:=folder+"/not-a-directory"
	var file:=FileAccess.open(blocker,FileAccess.WRITE);file.store_string("Fixture blocks directory creation");file.close()
	game.journey_tools.save_directory=blocker+"/saves"
	game._request_action("landing");game._confirm_action();await frames()
	check(current_scene==game and game._pending_action=="landing" and game.hud.save_menu.title=="JOURNEY NOT SAVED","Failed recovery keeps current journey open")
	check(game.hud.save_menu.options.size()==3 and game.hud.save_menu.options[0][1]=="cancel","Failure defaults to staying; retry and explicit discard offered")
	check(game.save_load.store.read_slot("1").ok,"Failed recovery leaves manual save intact")
	await shot("recovery-failed-720")
	game._ui_action("confirm");await frames()
	check(current_scene==game and game._pending_action=="landing","Retry failure still does not leave")
	game.controller._back();await frames()
	check(game._pending_action.is_empty() and game.hud.modal=="pause","Controller Back cancels leaving after failed recovery")
	game.save_load.open("load");game.save_load.action("save:load:1");game.save_load.action("save:confirm");await frames()
	check(current_scene==game and game.save_load.pending.get("kind")=="load" and game.hud.save_menu.title=="CURRENT JOURNEY NOT SAVED","Loading another save protects current run first")
	check(game.hud.save_menu.options[2][1]=="save:confirm_discard","Loading requires explicit choice to discard after failure")
	if "--discard-load" in OS.get_cmdline_user_args():
		var previous_id: int=game.get_instance_id();game.save_load.action("save:confirm_discard")
		if not await wait_for_scene(previous_id):quit(1);return
		check(game._passenger_seated() and game.paused and game.train.automatic,"Explicit discard loads chosen passenger save despite failed recovery")
	else:
		game.controller._back();await frames()
		check(game.save_load.pending.is_empty() and current_scene==game,"Back cancels pending load")
	check(var_to_bytes(before)==var_to_bytes(Snapshot.capture(game.world)),"Cancelled failures preserve complete railway")
	var discard_leave: bool="--discard-leave" in OS.get_cmdline_user_args()
	game.journey_tools.save_directory=blocker+"/saves" if discard_leave else saves
	var previous_id: int=game.get_instance_id()
	game._request_action("landing");game._confirm_action()
	if discard_leave:game._ui_action("confirm_discard")
	if not await wait_for_scene(previous_id):quit(1);return
	var page=current_scene
	while page.save_worker!=null:await process_frame
	page.store=preload("res://persistence/save_store.gd").new(saves);page.saves=page._saved_entries();page.show_browser(true);await frames()
	check(page.saves.any(func(s):return s.summary.get("reason","")=="Before landing")!=discard_leave,"Return Home writes recovery unless player explicitly discards")
	check(page.description.text.contains("Passenger seat") and page.description.text.contains("scheduled stops"),"Saved journeys show viewpoint and progress")
	await shot("saved-journeys-720")
	# Corrupt only this fixture's primary after a valid overwrite made a backup.
	page.store.write_slot("1",saved.data.checkpoint,saved.data.summary)
	file=FileAccess.open(page.store.path("1"),FileAccess.WRITE);file.store_string("incomplete fixture save");file.close()
	page.saves=page._saved_entries();page.selected={id="1"};page.refresh();await frames()
	check(page.selected.id=="1" and not page.selected.readable and page.start_button.disabled,"Unreadable primary stays visible with loading disabled")
	check(page.page_title.text=="Saved journeys" and not page.filter_row.visible and not page.stock_picker.visible,"Saved-journey page omits unrelated departure filters")
	check(page.description.text.contains("previous backup"),"Unreadable save points to recovery backup")
	page.start_selected();check(page.worker==null,"Unavailable primary cannot start loading")
	page.selected={id="1-backup"};page.refresh();await frames()
	check(not page.start_button.disabled and page.description.text.contains("Previous version"),"Readable backup remains selectable")
	check(page.description.text.contains("Passenger seat"),"Backup retains previous viewpoint metadata")
	page.home.update_saves(page.saves.filter(func(s):return not s.readable))
	check(page.home.buttons.continue.disabled,"Continue disabled if only unreadable saves exist")
	page.home.update_saves(page.saves);check(not page.home.buttons.continue.disabled,"Continue enabled with readable backup or recovery")
	page.set_period(1);check(page.page=="saves","Bumpers cannot unexpectedly leave the saved-journey page")
	page.queue_free();await frames()
	print("RECOVERY_QOL ",checks," checks, ",failures," failures");quit(1 if failures else 0)
