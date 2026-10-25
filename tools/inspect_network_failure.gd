extends SceneTree
## Read-only inspection of a failed real rehearsal, never a simulation replay.
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var folder:="res://.local/realism-2026-10-26/rehearsals-v1/classic-network-delayed"
	var station_code:="AMPA"
	var train_ids:=["M001","S001","S002","M041"]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--folder="):folder=arg.trim_prefix("--folder=")
		elif arg.begins_with("--station="):station_code=arg.trim_prefix("--station=")
		elif arg.begins_with("--trains="):train_ids=Array(arg.trim_prefix("--trains=").split(","))
	var f:=FileAccess.open(folder+"/failure.bin",FileAccess.READ)
	var restored: Dictionary=preload("res://sim/world_snapshot.gd").restore(f.get_var());f.close()
	if not restored.ok:printerr(restored.reason);quit(1);return
	var w: RailWorld=restored.world;var before:=var_to_bytes(preload("res://sim/world_snapshot.gd").capture(w))
	var planner:=preload("res://sim/dispatch_planner.gd").new()
	var station: Dictionary=w.stations.filter(func(s):return s.code==station_code)[0]
	var info:={clock=w.clock_seconds(),station=station,claims=planner._station_claims(w,station),occupancy=w.occupancy(),trains={},signals=[]}
	for id in train_ids:
		var t: Train=w.trains[id];var ns:=w.next_signal(t)
		info.trains[id]={path=t.path,head_s=t.head_s,length=t.length,speed=t.speed,stop=t.timetable.stop_ahead(),calls=t.timetable.stops,arrivals=t.timetable.actual_arrivals,departures=t.timetable.actual_departures,next_signal=ns,
			status=t.status,dispatch=w.dispatcher().states.get(id,{}),candidates=planner.candidates(w,t,ns.id) if not ns.is_empty() else [],approaches=planner.approach_signals(w,t)}
	for id in w.signals:
		if station_code in id:info.signals.append(w.signals[id])
	var after:=var_to_bytes(preload("res://sim/world_snapshot.gd").capture(w))
	info.snapshot_unchanged=before==after
	FileAccess.open(folder+"/receiving-inspection.json",FileAccess.WRITE).store_string(JSON.stringify(info,"\t"))
	print(JSON.stringify({clock=info.clock,claims=info.claims,snapshot_unchanged=info.snapshot_unchanged}))
	quit(0 if info.snapshot_unchanged else 1)
