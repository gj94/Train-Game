extends SceneTree
const Days:=preload("res://persistence/operating_days.gd")
const Starts:=preload("res://persistence/service_starts.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func frames() -> void:await process_frame;await process_frame
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/operating-days-ui/"+name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.local/operating-days-ui"))
	root.size=Vector2i(1280,720)
	set_meta("timetable_id","standard")
	var page:=preload("res://game/launch.gd").new()
	page.store=preload("res://persistence/save_store.gd").new("res://.local/operating-days-ui/saves")
	root.add_child(page);await frames()
	check(page.services.size()==100,"Standard day is intact")
	page.roster.grab_focus();page._navigate(Vector2i.LEFT)
	for _i in 6:
		if root.gui_get_focus_owner()==page.timetable_picker:break
		page._navigate(Vector2i.UP)
	check(root.gui_get_focus_owner()==page.timetable_picker,"D-pad reaches operating-day selector from roster")
	if root.gui_get_focus_owner()!=page.timetable_picker:
		page.queue_free();await frames();quit(1);return
	var a:=InputEventJoypadButton.new();a.button_index=JOY_BUTTON_A;a.pressed=true;page._input(a);await frames()
	check(page.timetable_picker.get_popup().visible,"Controller opens operating-day selector")
	page.timetable_picker.get_popup().hide();page.select_timetable(1);await frames()
	check(page.services.size()==140 and page.selected.id=="K1","Intensive roster and default passenger")
	check(page.directory==Days.definition("intensive").starts,"Separate intensive snapshots")
	check(not page.traffic_data.is_empty(),"Intensive traffic catalogue")
	if page.services.size()!=140 or page.traffic_data.is_empty():
		page.queue_free();await frames();quit(1);return
	var overtakers:={}
	for row in page.traffic_rows:
		if row.role=="Overtakes you":overtakers[row.other]=true
	check(overtakers.size()>=10,"At least ten distinct overtakers of K1")
	page.sort_mode=2;page.refresh()
	check(page.shown[0].id=="K1","K1 is the slowest scheduled service")
	page.set_detail_mode(1);await frames();await shot("intensive-traffic")
	var results:=page._read_request("service",page.selected)
	check(results.ok and results.world.trains.size()==140 and results.timetable_id=="intensive","Selected railway identity survives departure loading")
	Starts.select(results.world,"K1")
	check(not results.world.trains.K1.automatic and results.world.trains.values().all(func(t):return t.id=="K1" or t.automatic),"Only selected service changes to manual")
	page.search.text="B042";page.refresh();page.set_detail_mode(1);await frames()
	check(page.selected.id=="B042","IDs can repeat safely between operating days")
	check(page.traffic_rows.filter(func(r):return r.other=="B002" and r.role=="You overtake").is_empty(),"Corrected B042 preview has no reverse pass")
	await shot("b042")
	page.select_timetable(0);await frames()
	check(page.services.size()==100 and page.directory==Starts.DIRECTORY,"Switching back restores standard day")
	page.search.text="B042";page.refresh()
	var standard_data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Starts.DIRECTORY+"/traffic.json"))
	check(page.traffic_data.events==standard_data.events,"Switching back loads the standard day's measured traffic")
	await shot("standard")
	page.select_timetable(1);await frames();page.queue_free();await frames()
	var timeline:=preload("res://game/launch_timeline.gd").new();root.add_child(timeline)
	var began:=Time.get_ticks_msec()
	while timeline.world==null and not timeline.states.is_empty() and Time.get_ticks_msec()-began<60000:await process_frame
	await frames()
	check(timeline.directory==Days.definition("intensive").times,"Explore by time uses the selected day")
	check(timeline.world!=null and timeline.world.trains.size()==140,"Time preview loads the intensive railway")
	await shot("intensive-time")
	timeline.queue_free();await frames()
	remove_meta("timetable_id")
	print("OPERATING_DAYS_UI ",JSON.stringify({checks=checks,failures=failures,k1_distinct_overtakers=overtakers.size()}))
	quit(1 if failures else 0)
