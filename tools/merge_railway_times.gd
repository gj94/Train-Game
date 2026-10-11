extends SceneTree
func _initialize() -> void:
	var count:=int(OS.get_cmdline_user_args()[0]);var data:={}
	var steps:=0;var total_seconds:=0.0;var longest_seconds:=0.0
	for i in count:
		var part=JSON.parse_string(FileAccess.get_file_as_string("res://.local/railway-time-parts/%d.json" % i))
		if not part is Dictionary or not part.get("complete",false) or not part.get("audit",{}).get("ok",false) or part.get("part")!=i or part.get("parts")!=count:
			printerr("Incomplete timeline partition ",i);quit(1);return
		if i==0:data=part.duplicate(true);data.states=[]
		if part.sources!=data.sources or part.engine!=data.engine or part.layout_signature!=data.layout_signature or part.departure_catalogue_sha256!=data.departure_catalogue_sha256 or not part.audit.events.is_empty():
			printerr("Mismatched timeline partition ",i);quit(1);return
		data.states.append_array(part.states);steps+=int(part.audit.steps)
		total_seconds+=float(part.audit.wall_seconds);longest_seconds=maxf(longest_seconds,float(part.audit.wall_seconds))
	data.erase("part");data.erase("parts")
	data.audit={ok=true,states=data.states.size(),round_trips=data.states.size(),events=[],steps=steps,parallel_workers=count,
		worker_seconds=total_seconds,longest_worker_seconds=longest_seconds}
	var path:="res://data/railway_times/catalogue.json"
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(data,"\t"))
	var verified:=preload("res://persistence/railway_times.gd").catalogue()
	if not verified.ok:printerr(verified.reason);quit(1);return
	print("TIMELINE MERGED ",JSON.stringify(data.audit));quit()
