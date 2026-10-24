extends SceneTree
## Use only after certified baselines are installed. Real menu loaders and
## timeline workers, isolated preferences/saves, no alternate fixture catalogues.
const Days:=preload("res://persistence/operating_days.gd")
const Traffic:=preload("res://persistence/service_traffic.gd")
const OUT:="res://.local/dispatcher-v2-2026-10-24/prepared-ui"
var checks:=0
var failures:=[]
var results:=[]
var requested:=[]
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:failures.append(label);printerr("FAIL ",label)
	return ok
func frames() -> void:
	for i in 4:await process_frame
func shot(label: String) -> void:
	await frames()
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/"+label+".png")
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--day="):requested.append(arg.trim_prefix("--day="))
	for id: String in requested:
		if not Days.DAYS.any(func(day):return day.id==id):printerr("Unknown day ",id);quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	for index in Days.DAYS.size():
		var day: Dictionary=Days.DAYS[index]
		if not requested.is_empty() and day.id not in requested:continue
		if not check(Days.available(day.id),day.id+" certified catalogues available"):continue
		var page:=preload("res://game/launch.gd").new()
		page.browser_preferences=OUT+"/browser.cfg"
		page.store=preload("res://persistence/save_store.gd").new(OUT+"/saves")
		root.add_child(page);await frames();page.show_browser();page.select_timetable(index)
		page.period=0;page.search.text="";page.selected={id="K1"};page.refresh();await frames()
		check(page.services.size()==day.count,day.id+" service count")
		check(page.selected.get("id","")=="K1",day.id+" passenger selectable")
		check(page.directory==day.starts,day.id+" isolated departure directory")
		check(page.calls_grid.get_child_count()==(page.selected.get("calls",[]).size()+1)*3,day.id+" all booked calls shown")
		page.set_detail_mode(1);await frames()
		check(page.traffic_summary.text.begins_with("Predictive V2 AI baseline" if day.dispatcher=="predictive" else "Classic AI baseline"),day.id+" traffic mode label")
		var overtakers:={}
		for row: Dictionary in page.traffic_rows:
			if row.role=="Overtakes you":overtakers[row.other]=true
		if day.count==140:check(overtakers.size()>=10,day.id+" ten distinct measured K1 overtakers")
		check(not page.traffic_rows.is_empty(),day.id+" measured traffic available")
		await shot(day.id+"-traffic")
		var entry:=page._read_request("service",page.selected)
		if check(entry.ok,day.id+" departure restoration"):
			check(entry.timetable_id==day.id and entry.world.trains.size()==day.count,day.id+" restored railway identity")
			check(entry.world.dispatcher().predictive.enabled==(day.dispatcher=="predictive"),day.id+" restored dispatch mode")
		# An actual counterpart list must show the reverse role for every K1 pass.
		for other: String in overtakers:
			var reciprocal:=Traffic.for_service(page.traffic_data,other)
			check(reciprocal.any(func(row):return row.other=="K1" and row.role=="You overtake"),day.id+" reciprocal pass "+other)
		page.queue_free();await frames()
		set_meta("timetable_id",day.id)
		var timeline:=preload("res://game/launch_timeline.gd").new();root.add_child(timeline);await frames()
		var noon:=timeline.states.find_custom(func(row):return row.clock==43200)
		if check(noon>=0,day.id+" noon checkpoint available"):
			timeline.choose(noon)
			var started:=Time.get_ticks_msec()
			while (timeline.loaded_index!=noon or timeline.worker!=null) and Time.get_ticks_msec()-started<60000:await process_frame
			if check(timeline.world!=null and timeline.loaded_index==noon,day.id+" real timeline worker restoration"):
				check(timeline.world.trains.size()==day.count and is_equal_approx(timeline.world.clock_seconds(),43200),day.id+" noon railway identity")
				check(timeline.world.dispatcher().predictive.enabled==(day.dispatcher=="predictive"),day.id+" noon dispatch mode")
				check(timeline.services.any(func(t):return t.id=="K1"),day.id+" K1 available at noon")
				timeline._select_train("K1");await shot(day.id+"-noon")
		results.append({day=day.id,k1_distinct_overtakers=overtakers.size(),timeline_loaded=timeline.world!=null})
		timeline.queue_free();await frames()
	remove_meta("timetable_id")
	var report:={ok=failures.is_empty(),checks=checks,failures=failures,days=results}
	FileAccess.open(OUT+"/result.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("PREPARED_UI ",JSON.stringify(report));quit(0 if report.ok else 1)
