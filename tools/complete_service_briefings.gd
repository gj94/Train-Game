extends SceneTree
## Refresh menu-only metadata without rerunning or changing the audited railway.
const Starts:=preload("res://persistence/service_starts.gd")
const Briefing:=preload("res://persistence/service_briefing.gd")

func _initialize() -> void:call_deferred("run")

func run() -> void:
	var path:=Starts.DIRECTORY+"/catalogue.json"
	var data=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or not data.get("complete",false):printerr("Replay is incomplete");quit(1);return
	var sources:=preload("res://persistence/prepared_sources.gd").collect()
	for source_path in data.sources:
		if sources.get(source_path)!=data.sources[source_path]:printerr("Railway changed after replay: "+source_path);quit(1);return
	for row in data.services:
		var loaded:=Starts.load_start(row)
		if not loaded.ok:printerr(row.id+": "+loaded.reason);quit(1);return
		var info:=Briefing.describe(loaded.world,loaded.world.trains[row.id])
		if info.is_empty():printerr("Unreachable schedule: "+row.id);quit(1);return
		row.merge(info,true)
	data.sources=sources
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(data,"\t"))
	var verified:=Starts.catalogue()
	print("Service briefings: ",data.services.size()," checked railway states, ",verified.reason)
	quit(0 if verified.ok else 1)
