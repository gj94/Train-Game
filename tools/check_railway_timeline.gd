extends SceneTree
const Times:=preload("res://persistence/railway_times.gd")
const Snapshot:=preload("res://sim/world_snapshot.gd")
var folder:="res://.local/timeline-ui"
var directory:=Times.DIRECTORY
var preview:=false
var checks:=0
var failures:=0

func _initialize() -> void:
	preview="--preview" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder));call_deferred("run")

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)

func frames() -> void:await process_frame;await process_frame

func tap(page,button: int) -> void:
	var event:=InputEventJoypadButton.new();event.button_index=button;event.pressed=true;page._input(event);await frames()

func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(folder+"/"+name+".png")

func fixture() -> void:
	directory=folder+"/fixture";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var source=JSON.parse_string(FileAccess.get_file_as_string("res://data/service_starts/catalogue.json"))
	var loaded:=preload("res://persistence/service_starts.gd").load_start(source.services[-1])
	var w: RailWorld=loaded.world;var first:=ceili(w.clock_seconds()/300)*300
	var data:={version=1,engine=Engine.get_version_info().string,complete=true,states=[]}
	for target in [first,first+300]:
		while w.clock_seconds()<target-.001:w.step(minf(2,target-w.clock_seconds()))
		var id:="T%06d" % target;var path:=directory+"/"+id+".bin"
		var file:=FileAccess.open_compressed(path,FileAccess.WRITE,FileAccess.COMPRESSION_ZSTD);file.store_var(Snapshot.capture(w));file.close()
		data.states.append({id=id,file=id+".bin",clock=target,sha256=FileAccess.get_sha256(path)})
	FileAccess.open(directory+"/catalogue.json",FileAccess.WRITE).store_string(JSON.stringify(data))

func menu() -> Control:
	var page:=preload("res://game/launch_timeline.gd").new();page.directory=directory;root.add_child(page);current_scene=page;return page

func loaded(page) -> void:
	var began:=Time.get_ticks_msec()
	while page.worker!=null or page.loaded_index!=page.requested:
		await process_frame
		if Time.get_ticks_msec()-began>60000:check(false,"timeline load timeout");return
	await frames()

func settle(g) -> void:
	var began:=Time.get_ticks_msec()
	while g.wv.loading or g.wv.has_pending_work():
		await process_frame
		if Time.get_ticks_msec()-began>180000:check(false,"scenery settled");return
	await frames()

func run() -> void:
	root.size=Vector2i(1600,900)
	if preview:fixture()
	var page:=menu();await loaded(page)
	check(page.world!=null and page.map!=null,"dispatcher preview restored")
	check(page.world.trains.size()==100,"all timetable services present")
	var before:=Snapshot.capture(page.world)
	page.map.focus_station(2);page.map.zoom_at(1.5);await frames()
	check(var_to_bytes(before)==var_to_bytes(Snapshot.capture(page.world)),"inspection and zoom preserve railway state")
	page.choose(0);page.choose(1);await loaded(page)
	check(absf(page.world.clock_seconds()-page.states[1].clock)<.001,"rapid time changes display only latest request")
	await tap(page,JOY_BUTTON_LEFT_SHOULDER);await loaded(page)
	check(page.requested==0,"controller steps back five minutes")
	page.choose(1);page.debounce=0;await frames();page.choose(0);await loaded(page)
	check(page.map.visible and absf(page.world.clock_seconds()-page.states[0].clock)<.001,"return to current time during another read restores its preview")
	page._station(2);check(page.map.focus_index==2,"station picker focuses yard")
	page.roster.grab_focus();await tap(page,JOY_BUTTON_A)
	check(root.gui_get_focus_owner()==page.board_button and current_scene==page,"selection requires explicit boarding")
	page.station_picker.grab_focus();await tap(page,JOY_BUTTON_A)
	check(page.station_picker.get_popup().visible,"controller opens station picker");page.station_picker.get_popup().hide()
	await shot("preview")
	if preview:
		root.size=Vector2i(1280,720);await frames();await shot("preview-720p")
		page.queue_free();await frames();print("Timeline preview: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0);return
	var index:=0
	for i in page.states.size():
		if page.states[i].clock==20*3600:index=i;break
	page.choose(index);await loaded(page)
	var moving: Array=page.services.filter(func(t):return t.speed>3)
	check(not moving.is_empty(),"night fixture contains moving services")
	if moving.is_empty():quit(1);return
	page._select_train(moving[0].id);var id: String=page.selected_id
	check(not page.detail.text.contains("No reachable route"),"moving services do not show stopped-train waiting advice")
	before=Snapshot.capture(page.world);await shot("night-preview")
	if "--inspect-only" in OS.get_cmdline_user_args():
		page.queue_free();await frames();print("Timeline inspection: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0);return
	page._board()
	while current_scene==page or current_scene==null:await process_frame
	var g=current_scene;await settle(g)
	check(g.train.id==id and g.train.automatic and g.cam.mode==1 and g.paused,"moving train starts paused in AI pilot")
	check(var_to_bytes(before)==var_to_bytes(Snapshot.capture(g.world)),"boarding preserves exact AI motion and authority")
	check(g.wv.day_night.state.night>.9,"time start has night lighting")
	g.hud.show_modal("");await shot("night-pilot");g.hud.show_modal("pause")
	g.dispatcher.toggle_driver();g._set_paused(false);g._physics_process(0);g._set_paused(true)
	check(not g.train.automatic and g.world.dispatcher().manual_service==id,"manual takeover remains eligible for automatic dispatch")
	g._ui_action("landing");g._confirm_action()
	while current_scene==g or current_scene==null:await process_frame
	current_scene.queue_free();await frames();page=menu();await loaded(page)
	var station: int=page.world.stations.find(page.world.stations.filter(func(s):return s.code=="TVC")[0])
	page._station(station);before=Snapshot.capture(page.world);page._visit()
	while current_scene==page or current_scene==null:await process_frame
	g=current_scene;await settle(g)
	check(g.walker.active and g.walker.platform.outside and g.cam.mode==4,"station starts in platform walking mode")
	check(g.walker.platform.surface.edge.begins_with("TVC_"),"exact requested station, not nearest to selected train")
	check(g.world.trains.values().all(func(t):return t.automatic),"all trains remain under AI from platform")
	check(var_to_bytes(before)==var_to_bytes(Snapshot.capture(g.world)),"platform entry preserves railway state")
	check(g.walker.platform.surface.allowed(g.walker.platform.position),"platform landing is walkable")
	g.hud.show_modal("");await shot("night-platform");g.hud.show_modal("pause")
	g.save_load.store.directory=folder+"/saves"
	check(g.save_load.save("1").ok,"platform time start can be saved")
	var saved: Dictionary=g.save_load.store.read_slot("1");var restored:=Snapshot.restore(saved.data.checkpoint)
	check(restored.ok and preload("res://game/save_validation.gd").check(restored.world,restored.session).is_empty(),"platform save validates")
	check(restored.session.prepared_time==g._prepared_time and restored.session.walk.outside,"saved platform and original time retained")
	g._ui_action("landing");g._confirm_action()
	while current_scene==g or current_scene==null:await process_frame
	page=current_scene
	# Wait for automatic discovery before substituting this check's isolated slots.
	while page.save_worker!=null:await process_frame
	page.store=preload("res://persistence/save_store.gd").new(folder+"/saves");page.saves=page._saved_entries();page._continue()
	while current_scene==page or current_scene==null:await process_frame
	g=current_scene;await settle(g)
	check(g.paused and g.walker.platform.outside and g.walker.platform.surface.edge.begins_with("TVC_"),"Continue restores requested station walking view")
	check(var_to_bytes(before)==var_to_bytes(Snapshot.capture(g.world)),"Continue preserves exact platform railway state")
	g._ui_action("landing");g._confirm_action()
	while current_scene==g or current_scene==null:await process_frame
	current_scene.queue_free();await frames();page=menu();await loaded(page)
	page.choose(page.states.size()-1);await loaded(page)
	check(page.services.is_empty() and page.board_button.disabled and not page.visit_button.disabled,"finished day allows station visits without inactive service boarding")
	page._station(station);before=Snapshot.capture(page.world);page._visit()
	while current_scene==page or current_scene==null:await process_frame
	g=current_scene;await settle(g)
	check(g.walker.platform.outside and g.walker.platform.surface.edge.begins_with("TVC_"),"station remains accessible after last service depots")
	check(var_to_bytes(before)==var_to_bytes(Snapshot.capture(g.world)),"finished-day visit preserves depot state")
	g._ui_action("landing");g._confirm_action()
	while current_scene==g or current_scene==null:await process_frame
	current_scene.queue_free();await frames()
	var report:={checks=checks,failures=failures,service=id,clock=20*3600,station="TVC"}
	FileAccess.open(folder+"/result.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("Timeline UI: ",JSON.stringify(report));quit(1 if failures else 0)
