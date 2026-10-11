extends SceneTree
## Source-game menu/controller/load verification, with isolated save slots.
const Starts:=preload("res://persistence/service_starts.gd")
var failures:=0
var checks:=0
var folder:="res://.local/service-selection"
var preview:=false

func _initialize() -> void:
	preview="--preview" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	call_deferred("run")

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)

func frames() -> void:
	await process_frame;await process_frame

func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"/"+name+".png")

func tap(menu,button: int) -> void:
	var event:=InputEventJoypadButton.new();event.button_index=button;event.pressed=true
	menu._input(event);await frames()

func menu() -> Control:
	var page:=preload("res://game/launch.gd").new()
	page.store=preload("res://persistence/save_store.gd").new(folder+"/saves")
	if preview:
		# Explicitly labelled temporary UI fixture, never the published catalogue.
		var data=JSON.parse_string(FileAccess.get_file_as_string(Starts.DIRECTORY+"/catalogue.json"));data.complete=true
		page.directory=folder+"/preview";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(page.directory))
		for row in data.services:
			DirAccess.copy_absolute(Starts.DIRECTORY.path_join(row.file),page.directory.path_join(row.file))
			var loaded:=Starts.load_start(row)
			if loaded.ok:row.merge(preload("res://persistence/service_briefing.gd").describe(loaded.world,loaded.world.trains[row.id]),true)
		FileAccess.open(page.directory+"/catalogue.json",FileAccess.WRITE).store_string(JSON.stringify(data))
	root.add_child(page);current_scene=page
	return page

func settle(g) -> void:
	var start:=Time.get_ticks_msec()
	while g.wv.loading or g.wv.has_pending_work():
		await process_frame
		if Time.get_ticks_msec()-start>180000:check(false,"scenery settled");return
	await frames()

func run() -> void:
	root.size=Vector2i(1600,900)
	var page:=menu();await frames()
	check(page.services.size()==100 if not preview else page.services.size()>0,"catalogue displayed")
	check(page.get_node_or_null("WorldEnvironment")==null,"menu has no 3D railway")
	check(root.gui_get_focus_owner()==page.roster,"controller begins on service list")
	check(page.selected.id=="K1","slow Ernakulam passenger remains default")
	page.search.text="Vande Bharat";page.refresh()
	check(page.shown.size()==2,"search finds both full-route Vande Bharats")
	page.search.text="";page.refresh();await frames()
	var old_index: int=page.roster.get_selected_items()[0]
	page.roster.grab_focus();await tap(page,JOY_BUTTON_DPAD_DOWN)
	check(page.selected.id==page.shown[old_index+1].id,"D-pad changes the selected service")
	await tap(page,JOY_BUTTON_A)
	check(root.gui_get_focus_owner()==page.start_button and page.worker==null,"A inspects before starting")
	await tap(page,JOY_BUTTON_B)
	check(root.gui_get_focus_owner()==page.roster,"B returns to service list")
	var selected_id: String=page.selected.id
	await tap(page,JOY_BUTTON_X)
	check(page.sort_mode==1 and page.selected.id==selected_id,"controller speed sort preserves selection")
	check(page.shown[0].average_kmh>=page.shown[-1].average_kmh,"fastest schedule first")
	check(page.calls_grid.get_child_count()==(page.selected.calls.size()+1)*3,"every booked call displayed")
	page.sort_button.grab_focus();await tap(page,JOY_BUTTON_A)
	check(page.sort_button.get_popup().visible,"controller opens sorting menu")
	page.sort_button.get_popup().hide();page.sort_mode=0;page.refresh();page.roster.grab_focus()
	await shot("services")
	page._begin("service",page.selected);page._cancel()
	while page.worker!=null:await process_frame
	check(current_scene==page and not page.busy_panel.visible,"cancelled load stays in menu")
	if preview:
		page.queue_free();await frames();print("Preview UI: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0);return
	page.set_period(4);await frames();await shot("night-services")
	check(not page.shown.is_empty() and page.shown.all(func(r):return page.in_period(r.departure,4)),"night departure filtering")
	var row: Dictionary=page.shown[-1];page.roster.select(page.shown.size()-1);page._select(page.shown.size()-1)
	var began:=Time.get_ticks_msec();page.start_selected()
	while current_scene==page or current_scene==null:await process_frame
	var g=current_scene;await settle(g)
	check(g.train.id==row.id and g._prepared_id==row.id,"chosen night service bound to pilot")
	check(g.paused and g.cam.mode==1 and not g.train.automatic and g.train.controller==-1,"safe paused manual pilot start")
	check(g.world.trains.size()==100 and g.world.active_trains().size()>1,"surrounding railway restored")
	check(absf(g.world.clock_seconds()-row.start_clock)<.001 and g.wv.day_night.state.night>.9,"night clock and lighting restored")
	check(g.world.trains.values().all(func(t):return t.id==row.id or t.automatic),"other services under AI")
	g.hud.show_modal("");await shot("night-pilot");g.hud.show_modal("pause")
	g.save_load.store.directory=folder+"/saves"
	check(g.save_load.save("1").ok,"departure journey saves")
	var expected:=preload("res://sim/world_snapshot.gd").capture(g.world)
	g._ui_action("landing")
	check(g.hud.modal=="confirm","return to services protects unsaved progress")
	g._confirm_action()
	while current_scene==g or current_scene==null:await process_frame
	page=current_scene;page.store=preload("res://persistence/save_store.gd").new(folder+"/saves");page.saves=page._saved_entries()
	page._continue()
	while current_scene==page or current_scene==null:await process_frame
	g=current_scene;await settle(g)
	check(g.paused and g.train.id==row.id and g._prepared_id==row.id,"Continue preserves service and restart identity")
	check(var_to_bytes(expected)==var_to_bytes(preload("res://sim/world_snapshot.gd").capture(g.world)),"Continue restores exact railway state")
	g._ui_action("landing");g._confirm_action()
	while current_scene==g or current_scene==null:await process_frame
	current_scene.queue_free();await frames()
	var report:={checks=checks,failures=failures,service=row.id,start_clock=row.start_clock,wall_seconds=(Time.get_ticks_msec()-began)*.001}
	FileAccess.open(folder+"/result.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("Service selection: ",JSON.stringify(report));quit(1 if failures else 0)
