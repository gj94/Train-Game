extends SceneTree
## Mount the release read-only from a minimal audit project; never launch gameplay.
func _initialize() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.is_empty() or not ProjectSettings.load_resource_pack(args[0]):printerr("Pack mount failed");quit(1);return
	if FileAccess.file_exists("res://pack-index.json"):
		var index=JSON.parse_string(FileAccess.get_file_as_string("res://pack-index.json"))
		if not index is Dictionary or index.get("format")!=1:printerr("Invalid split-pack index");quit(1);return
		for relative in index.packs:
			if not ProjectSettings.load_resource_pack(args[0].get_base_dir().path_join(relative),false):
				printerr("Split pack mount failed: "+relative);quit(1);return
	for path in ["game/launch.tscn","game/launch.gd","game/launch_timeline.tscn","game/launch_timeline.gd","game/day_night.gd","game/audio_menu.gd","persistence/operating_days.gd","persistence/service_starts.gd","persistence/railway_times.gd"]:
		if not ResourceLoader.exists("res://"+path):printerr("Missing resource: "+path);quit(1);return
	for day in [
		{name="Standard",starts="service_starts",times="railway_times",count=100},
		{name="Intensive",starts="timetables/intensive/starts",times="timetables/intensive/times",count=140}]:
		var counts:=[]
		for folder in [day.starts,day.times]:
			var base: String="res://data/"+folder+"/"
			var data=JSON.parse_string(FileAccess.get_file_as_string(base+"catalogue.json"))
			if not data is Dictionary or not data.get("complete",false):printerr("Incomplete packaged catalogue: "+folder);quit(1);return
			var rows: Array=data.services if folder==day.starts else data.states
			for row in rows:
				if FileAccess.get_sha256(base+row.file)!=row.sha256:printerr("Packaged state differs: "+row.id);quit(1);return
			counts.append(rows.size())
		if counts[0]!=day.count or counts[1]<100:printerr("Prepared states missing for "+day.name);quit(1);return
		print("%s: %d service starts, %d time states verified." % [day.name,counts[0],counts[1]])
	print("Prepared pack audit passed. Launch/night/mixer resources verified. Gameplay not launched.");quit()
