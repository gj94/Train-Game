extends SceneTree
## Native/headless source UI check; does not play or modify prepared baselines.
var failures:=0
var checks:=0
const ROOT:="res://.local/dispatcher-v2-2026-10-24/ui"
func _initialize():call_deferred("run")
func check(ok: bool,label: String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func frames():
	for i in 4:await process_frame
func shot(name: String):
	await frames()
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ROOT+"/"+name+".png")
func run():
	DirAccess.make_dir_recursive_absolute(ROOT)
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	var launch:=preload("res://game/launch.gd").new();launch.browser_preferences=ROOT+"/browser.cfg";root.add_child(launch)
	await frames();launch.show_browser();launch.select_timetable(1);await frames()
	check(launch.timetable_picker.item_count==4,"Four explicit dispatcher/day choices")
	check(launch.timetable_picker.get_item_text(2).contains("Predictive V2"),"V2 option label")
	launch.set_detail_mode(1);await frames()
	check(launch.traffic_summary.text.begins_with("Classic AI baseline"),"Classic preview identified")
	check(root.get_visible_rect().encloses(launch.timetable_picker.get_global_rect()),"Day selector fits 720p")
	await shot("days-720")
	launch.timetable_picker.show_popup();await shot("day-picker-720");launch.timetable_picker.get_popup().hide()
	launch.queue_free();await frames()
	var w:=preload("res://tests/predictive_fixture.gd").build();var e=w.dispatcher();e.predictive.configure(true,false);e.run_cycle()
	var desk:=preload("res://game/dispatch_desk.gd").new();root.add_child(desk);desk.auto_dispatch=true;desk.setup(w,true);desk.set_open(true);desk.presentation_paused=true
	desk._map.focus_station(w.stations.find(w.stations.filter(func(s):return s.code=="STKT")[0]))
	for size in [Vector2i(1280,720),Vector2i(1600,900)]:
		root.size=size;root.content_scale_size=size;await frames();desk._refresh()
		check(desk._auto_button.text.begins_with("V2 DISPATCH"),"Live dispatcher mode visible")
		check(desk._inspect_reason.text.contains("Planned overtake") and desk._inspect_reason.text.contains("follow +"),"Plan and order-delay comparison shown")
		check(root.get_visible_rect().encloses(desk._auto_button.get_global_rect()),"Mode control fits")
		await shot("dispatch-"+str(size.y))
	var signals:=var_to_bytes(w.signals);e.set_mode("classic");desk._refresh()
	check(desk._auto_button.text.begins_with("CLASSIC") and signals==var_to_bytes(w.signals),"Mode switch keeps routes")
	desk.queue_free();await frames()
	print("PREDICTIVE_UI ",checks," checks, ",failures," failures");quit(1 if failures else 0)
