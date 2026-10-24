extends SceneTree
const Snapshot:=preload("res://sim/world_snapshot.gd")
const OUT:="res://.local/dispatcher-v2-2026-10-24/deletion-ui"
var checks:=0
var failures:=0
var reports: Array=[]
func _initialize():call_deferred("run")
func check(ok: bool,label: String):
	checks+=1;reports.append({"check":label,"ok":ok})
	if not ok:failures+=1;printerr("FAIL ",label)
func frames():
	for i in 4:await process_frame
func shot(name: String):
	await frames()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/"+name+".png")
func run():
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	var suite:=preload("res://tests/test_predictive_dispatch.gd").new()
	var w: RailWorld=suite.restored();var e=w.dispatcher()
	var desk:=preload("res://game/dispatch_desk.gd").new()
	root.add_child(desk);desk.selected_train="K1";desk.setup(w,true);desk.presentation_paused=true
	e.predictive.accept(w,e,suite.prepare(w));desk._refresh()
	check(not e.enabled and e.predictive.plans.has("K1"),"Paused dispatch retains an initial V2 plan")
	var before:=Snapshot.capture(w)
	desk.inspect_train("B002",true);desk._advanced_button.pressed.emit();await frames()
	desk._delete_service.pressed.emit();await frames()
	check(desk._confirm.visible and desk._confirm_id=="B002","Delete opens confirmation for inspected service")
	check(desk._confirm_no.has_focus(),"Controller defaults to keeping the service")
	check(root.get_visible_rect().encloses(desk._confirm.get_global_rect()),"Confirmation fits 720p")
	await shot("confirm-720")
	desk._confirm_no.pressed.emit();await frames()
	check(Snapshot.capture(w)==before,"Cancelling leaves the railway and advice unchanged")
	check(desk._delete_service.has_focus(),"Cancel returns controller focus to Delete")
	desk._delete_service.pressed.emit();desk._confirm_yes.pressed.emit();await frames()
	check(not w.trains.has("B002") and not desk._roster.has("B002"),"Confirmed service removed from railway and roster")
	check(desk.selected_train=="K1" and desk.inspected_train=="K1" and desk._roster.K1.has_focus(),"Own service and controller focus preserved")
	check(not e.enabled and e.predictive.plans.is_empty(),"Deletion invalidates advice without enabling dispatch")
	check(desk._delete_service.disabled,"Own service deletion remains disabled")
	var saved:=Snapshot.capture(w);var restored:=Snapshot.restore(saved)
	check(restored.ok and Snapshot.capture(restored.world)==saved,"Immediate save restores exactly after paused deletion")
	await shot("deleted-720")
	var f:=FileAccess.open(OUT+"/report.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"results":reports},"  "));f.close()
	desk.queue_free();await frames()
	print("DELETION_UI ",checks," checks, ",failures," failures");quit(1 if failures else 0)
