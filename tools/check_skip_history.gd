extends SceneTree
## Corridor rollback audit: real passenger exchanges, live reservations and late
## operating-day state, followed by exactly repeated simulation after restoration.
const Snapshot := preload("res://sim/world_snapshot.gd")
const History := preload("res://sim/skip_history.gd")
const Events := preload("res://sim/skip_to_event.gd")
var report := {cases=[],complete=false}
var output := "res://.local/r41-history-audit.json"

func _initialize() -> void:call_deferred("run")

func run() -> void:
	for item in [
		{path="res://data/railway_times/T032400.bin",label="standard_0900"},
		{path="res://data/railway_times/T079200.bin",label="standard_2200"},
		{path="res://data/timetables/intensive/times/T034200.bin",label="intensive_0930"}]:
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
		var row:={label=item.label,services=w.trains.size(),active=w.active_trains().size(),exact_restore=exact_restore,exact_replay=exact_replay,same_objects=same_objects,safety_events=w.events.size()}
		report.cases.append(row);print("HISTORY_AUDIT ",JSON.stringify(row))
		FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
		if not exact_restore or not exact_replay or not same_objects:quit(1);return
	report.complete=true;FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));quit(0)
