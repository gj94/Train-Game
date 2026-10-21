extends SceneTree
var checks:=0
var failures:=0
var samples:=[]
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func frames(n: int=3) -> void:
	for i in n:await process_frame
func loaded(page) -> bool:
	var began:=Time.get_ticks_msec()
	while page.worker!=null or page.loaded_index!=page.requested:
		await process_frame
		if Time.get_ticks_msec()-began>60000:check(false,"Read timeout");return false
	await frames();return page.world!=null
func run() -> void:
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	set_meta("timetable_id","intensive");set_meta("timeline_index",0)
	var page=preload("res://game/launch_timeline.gd").new();root.add_child(page);current_scene=page
	if not await loaded(page):quit(1);return
	var retired:=[]
	var repeat_baseline: bool="--same-times" in OS.get_cmdline_user_args()
	for i in (6 if repeat_baseline else 24):
		retired.append(weakref(page.world))
		var next: int=(19 if i%2==0 else 140) if repeat_baseline else (i*37+19)%page.states.size()
		if next==page.requested:next=(next+1)%page.states.size()
		page.choose(next)
		if not await loaded(page):quit(1);return
		check(retired.all(func(reference):return reference.get_ref()==null),"Old preview worlds released after replacement "+str(i))
		check(is_equal_approx(page.world.clock_seconds(),page.states[next].clock),"Latest loaded clock matches selector "+str(i))
		samples.append({iteration=i,clock=page.world.clock_text(),static_bytes=OS.get_static_memory_usage(),nodes=Performance.get_monitor(Performance.OBJECT_NODE_COUNT)})
	if repeat_baseline:
		for slot in 2:
			var bytes:=[]
			for i in range(slot,samples.size(),2):bytes.append(samples[i].static_bytes)
			check(bytes.max()-bytes.min()<2*1024*1024,"Same-time tracked allocations remain within 2 MiB across repeat loads "+str(slot))
	# Coalesce input while a worker actually owns an earlier request.
	page.choose((page.requested+1)%page.states.size());page._process(.2)
	check(page.worker!=null,"A worker owns the in-flight read")
	for i in 20:page.choose((page.requested+1)%page.states.size())
	var target: int=page.requested
	if not await loaded(page):quit(1);return
	check(page.loaded_index==target and is_equal_approx(page.world.clock_seconds(),page.states[target].clock),"Rapid time changes display only the latest requested snapshot")
	var latest: WeakRef=weakref(page.world);page.queue_free();await frames(6)
	check(latest.get_ref()==null,"Closing the preview frees its last railway")
	FileAccess.open("res://.local/r45/timeline-retention.json",FileAccess.WRITE).store_string(JSON.stringify(samples,"\t"))
	print("TIMELINE_RETENTION ",checks," checks, ",failures," failures");quit(1 if failures else 0)

