extends SceneTree
## Mount the release read-only from a minimal audit project; never launch gameplay.
func _initialize() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.is_empty() or not ProjectSettings.load_resource_pack(args[0]):printerr("Pack mount failed");quit(1);return
	for path in ["game/launch.tscn","game/launch.gd","game/launch_timeline.tscn","game/launch_timeline.gd","game/day_night.gd","persistence/service_starts.gd","persistence/railway_times.gd"]:
		if not ResourceLoader.exists("res://"+path):printerr("Missing resource: "+path);quit(1);return
	var counts:=[]
	for folder in ["service_starts","railway_times"]:
		var base: String="res://data/"+folder+"/"
		var data=JSON.parse_string(FileAccess.get_file_as_string(base+"catalogue.json"))
		if not data is Dictionary or not data.get("complete",false):printerr("Incomplete packaged catalogue: "+folder);quit(1);return
		var rows: Array=data.services if folder=="service_starts" else data.states
		for row in rows:
			if FileAccess.get_sha256(base+row.file)!=row.sha256:printerr("Packaged state differs: "+row.id);quit(1);return
		counts.append(rows.size())
	if counts[0]!=100 or counts[1]<100:printerr("Prepared states missing");quit(1);return
	print("Prepared pack audit: %d service starts, %d time states and launch/night resources verified. Gameplay not launched." % counts);quit()
