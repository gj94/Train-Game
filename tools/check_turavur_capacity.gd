extends SceneTree
## Resume the real standard day before the four-train Turavur cycle.
const Snapshot:=preload("res://sim/world_snapshot.gd")
const Fixture:="res://art/performance/intensive-2026-10-20/turavur-before-cycle.bin"
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var file:=FileAccess.open_compressed(Fixture,FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
	var loaded:=Snapshot.restore(file.get_var(false));file.close()
	if not loaded.ok:printerr(loaded.reason);quit(1);return
	var w: RailWorld=loaded.world
	var start:=w.clock_seconds()
	var observed:={}
	var cleared:={}
	var elapsed:={}
	var maximum_wait:=0.0
	var checkpoints:={B005="SRTL_P",B013="KUMM_P",B015="ERS_P",B037="TUVR_P"}
	while w.clock_seconds()<start+7200 and w.events.is_empty():
		w.step(2)
		for id in checkpoints:
			var t: Train=w.trains[id]
			var road: String=t.path[0].edge
			if road.begins_with(checkpoints[id]):observed[id]=true
			if observed.has(id) and not road.begins_with(checkpoints[id]) and not cleared.has(id):
				cleared[id]=w.clock_seconds()-start
			var waiting: bool=t.lifecycle=="active" and not t.service_complete and t.speed<.1 and w.clock_seconds()>t.timetable.release_time()+2
			elapsed[id]=elapsed.get(id,0.0)+2 if waiting else 0.0
			maximum_wait=maxf(maximum_wait,elapsed[id])
		if cleared.size()==checkpoints.size():break
	var result:={ok=cleared.size()==checkpoints.size() and w.events.is_empty() and maximum_wait<=1800,
		fixture_sha256=FileAccess.get_sha256(Fixture),start_clock=start,clock=w.clock_seconds(),
		cleared_after_seconds=cleared,maximum_wait=maximum_wait,events=w.events,
		trains=checkpoints.keys().map(func(id):return {id=id,road=w.trains[id].path[0].edge,status=w.trains[id].status})}
	FileAccess.open("res://.local/turavur-capacity.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print(JSON.stringify(result));quit(0 if result.ok else 1)
