extends SceneTree
const Snapshot:=preload("res://sim/world_snapshot.gd")
var checks:=0
var failures:=0
var folder:="res://.local/r45/browser-navigation"
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func frames() -> void:
	for i in 4:await process_frame
func tap(page,index: int) -> void:
	for pressed in [true,false]:
		var event:=InputEventJoypadButton.new();event.device=16;event.button_index=index;event.pressed=pressed
		if "--event-pipeline" in OS.get_cmdline_user_args():Input.parse_input_event(event);Input.flush_buffered_events()
		else:page._input(event)
		await frames()
func axis(page,value: float) -> void:
	var event:=InputEventJoypadMotion.new();event.axis=JOY_AXIS_LEFT_Y;event.axis_value=value;page._input(event)
func loaded(page) -> bool:
	var start:=Time.get_ticks_msec()
	while page.worker!=null or page.loaded_index!=page.requested:
		await process_frame
		if Time.get_ticks_msec()-start>60000:check(false,"Preview timeout");return false
	await frames();return true
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(folder+"/"+name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	var page=preload("res://game/launch.gd").new();page.browser_preferences=folder+"/browser.cfg"
	root.add_child(page);current_scene=page;await frames()
	page.home.buttons.settings.grab_focus();await tap(page,JOY_BUTTON_A)
	check(page.home.options.visible,"Controller opens Home settings through event pipeline")
	page.home.focus_setting("Controller layout");await tap(page,JOY_BUTTON_A);await tap(page,JOY_BUTTON_RIGHT_SHOULDER)
	check(page.home.guide.visible and page.home.guide.page==1,"RB advances exactly one controller-guide section")
	await tap(page,JOY_BUTTON_B)
	check(not page.home.guide.visible and page.home.options.visible and root.gui_get_focus_owner().text=="Controller layout","Guide B restores settings entry without closing Home settings")
	await tap(page,JOY_BUTTON_B)
	check(not page.home.options.visible and root.gui_get_focus_owner()==page.home.buttons.settings,"Settings B restores Home focus")
	page.show_browser();page.select_timetable(0);page.reset_filters();await frames()
	page.stock_picker.select(0);page.stock_picker.grab_focus();await tap(page,JOY_BUTTON_A)
	check(page.stock_picker.get_popup().visible,"Controller opens stock picker")
	await tap(page,JOY_BUTTON_RIGHT_SHOULDER)
	check(page.stock_picker.get_popup().get_focused_item()==4,"Popup RB jumps within stock choices")
	await tap(page,JOY_BUTTON_B)
	check(not page.stock_picker.get_popup().visible and page.library.stock.is_empty() and page.content.visible,"B cancels picker without leaving departures or changing stock")
	page.stock_picker.grab_focus();await tap(page,JOY_BUTTON_A)
	page.stock_picker.set_item_disabled(2,true)
	await tap(page,JOY_BUTTON_DPAD_DOWN);await tap(page,JOY_BUTTON_DPAD_DOWN)
	check(page.stock_picker.get_popup().get_focused_item()==3,"D-pad skips disabled picker choice")
	await tap(page,JOY_BUTTON_A)
	check(page.library.stock=="vb8" and page.shown.all(func(s):return s.stock=="vb8"),"Picker A applies Vande Bharat filter")
	page.stock_picker.set_item_disabled(2,false)
	page.timetable_picker.grab_focus();await tap(page,JOY_BUTTON_A);await tap(page,JOY_BUTTON_DPAD_DOWN);await tap(page,JOY_BUTTON_A)
	check(page.timetable_id=="intensive","Controller changes timetable through native picker")
	page.queue_free();await frames()
	set_meta("timetable_id","standard");set_meta("timeline_clock",20*3600)
	page=preload("res://game/launch_timeline.gd").new();root.add_child(page);current_scene=page
	if not await loaded(page):quit(1);return
	var before:=var_to_bytes(Snapshot.capture(page.world));var clock: float=page.world.clock_seconds()
	var start_index: int=page.requested
	page.station_picker.grab_focus();await tap(page,JOY_BUTTON_A)
	check(page.station_picker.get_popup().visible,"Controller opens station picker")
	await tap(page,JOY_BUTTON_RIGHT_SHOULDER)
	check(page.station_picker.get_popup().get_focused_item()==8 and page.requested==start_index,"RB pages stations without advancing timeline")
	await tap(page,JOY_BUTTON_B)
	check(page.station_index==0 and page.requested==start_index and not page.closing,"B cancels station selection without leaving preview")
	page.station_picker.grab_focus();await tap(page,JOY_BUTTON_A)
	axis(page,.8);page.picker_input.update(.4,[page.station_picker]);axis(page,0);await frames()
	check(page.station_picker.get_popup().get_focused_item()==2,"Left stick repeats station navigation")
	await tap(page,JOY_BUTTON_A)
	check(page.station_index==2 and page.world.clock_seconds()==clock,"Station selection preserves preview time")
	page._station(1)
	check(page.visit_button.disabled and page.visit_button.text.contains("No accessible"),"Closed Tirunettur does not offer false platform boarding")
	var kzk: int=-1
	for i in page.world.stations.size():
		if page.world.stations[i].code=="KZK":kzk=i;break
	page._station(kzk);page.filter_services(true);await frames()
	check(page.shown_services.size()>0 and page.shown_services.size()<page.services.size(),"Nearby filter narrows the night service roster")
	check(page.shown_services.any(func(t):return t.id=="B007") and not page.shown_services.any(func(t):return t.id=="B032"),"Kazhakuttam roster includes local B007 and excludes distant B032")
	check(page.roster_title.text.contains("KZK") and page.visit_button.text.contains("Kazhakuttam"),"Nearby roster and station entry share station context")
	var selected: String=page.selected_id
	page.roster.grab_focus();axis(page,.8);page._process(.01);axis(page,0);await frames()
	check(page.selected_id!=selected or page.shown_services.size()==1,"Left stick navigates service roster")
	page.roster.grab_focus();await tap(page,JOY_BUTTON_DPAD_RIGHT)
	check(page.map.has_focus(),"D-pad right enters map from roster")
	await tap(page,JOY_BUTTON_DPAD_LEFT)
	check(root.gui_get_focus_owner()==page.roster,"D-pad left returns from map to roster")
	check(before==var_to_bytes(Snapshot.capture(page.world)),"Filtering and picker navigation preserve full railway state")
	await shot("nearby-night-720")
	check(root.get_visible_rect().encloses(page.version_label.get_global_rect()),"Waiting-train preview fits 720p")
	var fit_all:=true
	for train in page.shown_services:
		page._select_train(train.id,false);await frames()
		if not root.get_visible_rect().encloses(page.version_label.get_global_rect()):fit_all=false
	check(fit_all,"All nearby waiting messages fit 720p")
	root.size=Vector2i(1600,900);root.content_scale_size=root.size;await frames();await shot("nearby-night-900")
	check(root.get_visible_rect().encloses(page.version_label.get_global_rect()),"Preview fits 900p")
	root.size=Vector2i(1280,720);root.content_scale_size=root.size;await frames()
	# Mutate only this scene's in-memory expected hash, never a prepared file.
	var expected: String=page.states[page.requested].sha256
	page.states[page.requested].sha256="0".repeat(64);page.retry()
	check(page.roster.item_count==0 and page.board_button.disabled and page.passenger_button.disabled,"Starting a new read removes stale services and disables boarding")
	if not await loaded(page):quit(1);return
	check(page.world==null and page.retry_button.visible and page.roster.item_count==0,"Failed preview shows retry with no stale world")
	check(page.status.text.contains("checksum") and page.visit_button.disabled,"Failure reason is visible and station entry is disabled")
	await shot("preview-error-720")
	check(root.get_visible_rect().encloses(page.version_label.get_global_rect()),"Failure screen fits 720p")
	page.states[page.requested].sha256=expected;page.retry_button.grab_focus();await tap(page,JOY_BUTTON_A)
	if not await loaded(page):quit(1);return
	check(page.world!=null and not page.retry_button.visible and page.nearby_only,"Retry restores preview and keeps nearby preference")
	check(page.world!=null and before==var_to_bytes(Snapshot.capture(page.world)),"Retry restores exactly the original baseline")
	page.choose(page.states.size()-1)
	if not await loaded(page):quit(1);return
	page.filter_services(false);await frames()
	check(page.services.is_empty() and page.shown_services.is_empty() and page.board_button.disabled and page.passenger_button.disabled,"Finished day offers no stale boarding service")
	check(not page.visit_button.disabled and page.detail.text.contains("No passenger services"),"Finished day still offers valid station visit")
	page.queue_free();await frames()
	var broken:=folder+"/catalogue-fixture";DirAccess.make_dir_recursive_absolute(broken)
	var file:=FileAccess.open(broken+"/catalogue.json",FileAccess.WRITE);file.store_string('{"version":1,"complete":false}');file.close()
	page=preload("res://game/launch_timeline.gd").new();page.directory=broken;root.add_child(page);current_scene=page;await frames()
	check(page.retry_button.visible and not page.slider.editable and page.world==null,"Unavailable catalogue offers retry and disables timeline")
	page.directory=preload("res://persistence/railway_times.gd").DIRECTORY;page.retry()
	if not await loaded(page):quit(1);return
	check(page.world!=null and page.slider.editable and not page.retry_button.visible,"Retry recovers from an unavailable catalogue")
	page.queue_free();await frames()
	print("BROWSER_NAVIGATION ",checks," checks, ",failures," failures");quit(1 if failures else 0)
