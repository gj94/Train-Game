extends SceneTree
const Snap:=preload("res://sim/world_snapshot.gd")
var checks:=0
var failures:=0
var report:=[]
var folder:="res://.local/r45/layout-audit"
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func frames(count: int=3) -> void:
	for i in count:await process_frame
func wait_loaded(page) -> bool:
	var began:=Time.get_ticks_msec()
	while page.worker!=null or page.loaded_index!=page.requested:
		await process_frame
		if Time.get_ticks_msec()-began>60000:check(false,"Timeout");return false
	await frames();return page.world!=null
func run() -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	for day in ["standard","intensive"]:
		set_meta("timetable_id",day);set_meta("timeline_clock",8*3600)
		var page=preload("res://game/launch_timeline.gd").new();root.add_child(page);current_scene=page
		if not await wait_loaded(page):quit(1);return
		for minute in [480,570,660,840,1200,1380]:
			var best: int=0
			for i in page.states.size():
				if absf(page.states[i].clock-minute*60)<absf(page.states[best].clock-minute*60):best=i
			page.choose(best)
			if not await wait_loaded(page):quit(1);return
			var before:=var_to_bytes(Snap.capture(page.world));var overflow:=[];var inspected:=0
			for train in page.services:
				page._select_train(train.id,false);await frames(2);inspected+=1
				if not root.get_visible_rect().encloses(page.version_label.get_global_rect()):
					overflow.append({id=train.id,detail=page.detail.text,bottom=page.version_label.get_global_rect().end.y})
					if overflow.size()==1 and DisplayServer.get_name()!="headless":
						await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(folder+"/"+day+"-"+str(minute)+".png")
			check(overflow.is_empty(),"720p "+day+" "+str(minute)+" minutes: "+str(overflow))
			check(before==var_to_bytes(Snap.capture(page.world)),"Inspection preserves "+day+" "+str(minute)+" railway")
			report.append({day=day,minutes=minute,inspected=inspected,overflow=overflow})
		page.queue_free();await frames()
	FileAccess.open(folder+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("TIMELINE_LAYOUT ",checks," checks, ",failures," failures");quit(1 if failures else 0)
