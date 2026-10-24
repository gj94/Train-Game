extends SceneTree
const OUT:="res://.local/dispatcher-v2-2026-10-24/forecast-ui"
var checks:=0
var failures: Array=[]
func _initialize():call_deferred("run")
func check(ok: bool,label: String):
	checks+=1
	if not ok:failures.append(label);printerr("FAIL ",label)
func frames():
	for i in 5:await process_frame
func shot(name: String):
	await frames()
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/"+name+".png")
func run():
	DirAccess.make_dir_recursive_absolute(OUT)
	var fixture:=preload("res://tests/test_predictive_dispatch.gd").new()
	var w: RailWorld=fixture.restored();var e=w.dispatcher()
	e.predictive.accept(w,e,fixture.prepare(w));e.enabled=true
	var desk:=preload("res://game/dispatch_desk.gd").new()
	root.add_child(desk);desk.auto_dispatch=true;desk.selected_train="K1";desk.setup(w,true);desk.presentation_paused=true
	var handovers: Array=[]
	desk.train_selected.connect(func(id):handovers.append(id))
	var before:=preload("res://sim/world_snapshot.gd").capture(w)
	var panel=desk._forecast_details
	for size in [Vector2i(1280,720),Vector2i(1600,900)]:
		root.size=size;root.content_scale_size=size
		desk.inspect_train("K1");await frames();panel.toggle.grab_focus()
		if not panel.expanded:panel.toggle.pressed.emit()
		await frames()
		desk._inspector.scroll_vertical=roundi(panel.position.y)
		await frames()
		check(panel.visible and panel.expanded and panel.shown.available,"Current proposal expanded "+str(size.y))
		check(panel.detail.text.contains("STKT_P3") and panel.detail.text.contains("STKT_P1"),"Both planned roads "+str(size.y))
		check(panel.detail.text.contains("reaches station:") and panel.detail.text.contains("projected lateness"),"ETA and order tradeoff "+str(size.y))
		check(panel.size.x<=desk._inspector.size.x,"Forecast wraps inside inspector "+str(size.y))
		await shot("plan-"+str(size.y))
	panel.station_button.pressed.emit();await frames()
	check(desk._map.focus_index==panel.shown.station_index and desk._map.has_focus(),"Locate passes focus to map")
	panel.service_button.pressed.emit();await frames()
	check(desk.inspected_train=="B002" and desk.selected_train=="K1" and panel.toggle.has_focus(),"Inspect counterpart keeps player and focus")
	check(not panel.expanded and panel.shown.other_id=="K1","Counterpart starts collapsed with reciprocal action")
	panel.toggle.pressed.emit();await frames()
	await shot("counterpart-900")
	check(handovers.is_empty() and before==preload("res://sim/world_snapshot.gd").capture(w),"Presentation actions leave entire railway unchanged")
	panel.service_button.grab_focus();w.time+=16;desk._refresh();await frames()
	check(not panel.shown.available and not panel.station_button.visible and not panel.service_button.visible,"Expired forecast hides obsolete actions")
	check(panel.toggle.has_focus(),"Expired action returns controller focus")
	check(panel.detail.text.contains("No current passing proposal"),"Expired proposal explained")
	e.enabled=false;desk._refresh()
	check(panel.detail.text.contains("Automatic dispatch is off"),"Paused automatic dispatch explained")
	e.predictive.configure(false);desk._refresh()
	check(not panel.visible,"Classic hides V2 details")
	check(desk._view.has_focus(),"Mode change preserves visible controller focus")
	desk.queue_free();await frames()
	var report:={checks=checks,failures=failures,ok=failures.is_empty()}
	FileAccess.open(OUT+"/result.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("FORECAST_UI ",JSON.stringify(report));quit(0 if report.ok else 1)
