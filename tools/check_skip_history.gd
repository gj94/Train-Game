extends SceneTree
## Corridor rollback audit: real passenger exchanges, live reservations and late
## operating-day state, followed by exactly repeated simulation after restoration.
const Snapshot := preload("res://sim/world_snapshot.gd")
const History := preload("res://sim/skip_history.gd")
const Events := preload("res://sim/skip_to_event.gd")
var report := {cases=[],complete=false}
var output := "res://.local/r41-history-audit.json"
var standard := "res://data/railway_times"
var intensive := "res://data/timetables/intensive/times"

func _initialize() -> void:call_deferred("run")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
		elif arg.begins_with("--standard="):standard=arg.trim_prefix("--standard=")
		elif arg.begins_with("--intensive="):intensive=arg.trim_prefix("--intensive=")
	for item in [
		{path=standard+"/T032400.bin",label="standard_0900"},
		{path=standard+"/T079200.bin",label="standard_2200"},
		{path=intensive+"/T034200.bin",label="intensive_0930"}]:
		var file:=FileAccess.open_compressed(item.path,FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
		var result:=Snapshot.restore(file.get_var(false));file.close()
		assert(result.ok)
		var w: RailWorld=result.world
		w.dispatcher().enabled=true;w.dispatcher().manual_service=""
		for t in w.trains.values():t.automatic=true
		var history:=History.new();var state:=history.capture(w)
		var original:=Snapshot.capture(w)
		var identities:={}
		for id in w.trains:identities[id]=w.trains[id].get_instance_id()
		for i in 600:w.step(.2)
		var future:=Snapshot.capture(w)
		history.restore(w,state)
		var exact_restore:=Snapshot.capture(w)==original
		for i in 600:w.step(.2)
		var exact_replay:=Snapshot.capture(w)==future
		var same_objects: bool=identities.keys().all(func(id):return identities[id]==w.trains[id].get_instance_id())
		var row:={label=item.label,snapshot_sha256=FileAccess.get_sha256(item.path),services=w.trains.size(),active=w.active_trains().size(),exact_restore=exact_restore,exact_replay=exact_replay,same_objects=same_objects,safety_events=w.events.size()}
		report.cases.append(row);print("HISTORY_AUDIT ",JSON.stringify(row))
		FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
		if not exact_restore or not exact_replay or not same_objects or not w.events.is_empty():quit(1);return
	report.complete=true;FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));quit(0)
