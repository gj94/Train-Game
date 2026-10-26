extends SceneTree
const OVERRIDES:="res://art/timetables/kerala-coast-network-departure-overrides.json"
const Clock:=preload("res://sim/world_clock.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var check_only: bool = "--check" in OS.get_cmdline_user_args()
	var network=load("res://sim/timetables/kerala_network.gd")
	var w=load("res://sim/layouts/kerala_coast.gd").build(true)
	var overrides=JSON.parse_string(FileAccess.get_file_as_string(OVERRIDES))
	if not overrides is Dictionary or overrides.get("format")!="train-game-authored-departure-overrides" or overrides.get("version")!=1 or not overrides.get("changes") is Array:
		printerr("Invalid authored departure overrides");quit(1);return
	for mode in [false,true]:
		var data: Dictionary=network.pack(w,mode)
		var seen:={}
		for edit in overrides.changes:
			if not edit is Dictionary or edit.size()!=4 or not edit.has_all(["service","from","to","reason"]) or seen.has(edit.service) or str(edit.reason).is_empty():
				printerr("Malformed or repeated departure edit");quit(1);return
			var matching: Array=data.services.filter(func(service):return service.id==edit.service)
			if matching.size()!=1 or matching[0].departure!=edit.from or not edit.to is String or Clock.parse_time(edit.to)<0 or Clock.parse_time(edit.to)>=86400:
				printerr("Departure edit does not match its authored source: ",edit.service);quit(1);return
			matching[0].departure=edit.to
			seen[edit.service]=true
		var checked: Dictionary=load("res://sim/service_pack.gd").build(data)
		if not checked.ok:printerr(checked.reason);quit(1);return
		var path:="res://art/timetables/kerala-coast-network"+("-v2" if mode else "")+".json"
		if check_only:
			var existing = JSON.parse_string(FileAccess.get_file_as_string(path))
			# Compare at the precision actually written by this JSON author, not
			# unrounded intermediate floating-point marker coordinates.
			if existing != JSON.parse_string(JSON.stringify(checked.data)):
				printerr("Authored pack differs from definitions and departure overrides: ",path);quit(1);return
			print("REPRODUCED ",path," services=",checked.world.trains.size())
			continue
		FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(checked.data,"\t")+"\n")
		print("AUTHORED ",path," services=",checked.world.trains.size())
	quit()
