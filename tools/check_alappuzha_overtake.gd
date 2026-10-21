extends SceneTree
## Replay R41's prepared 09:55 Intensive checkpoint matching the reported sequence.
const Snapshot := preload("res://sim/world_snapshot.gd")
const Policy := preload("res://sim/priority_dispatch.gd")
const CHECKPOINT := "res://art/performance/departure-depots-2026-10-21/alappuzha-r41-before.bin"
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var file:=FileAccess.open_compressed(CHECKPOINT,FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
	var result:=Snapshot.restore(file.get_var(false));file.close();assert(result.ok)
	var w: RailWorld=result.world;var k1: Train=w.trains.K1;var express: Train=w.trains.B024
	var journal:=[];var seq: int=w.dispatcher()._seq
	while w.clock_seconds()<38400 and k1.timetable.actual_departures[11]<0:
		w.step(.5)
		for entry in w.dispatcher().journal:
			if entry.seq>seq and entry.train in ["K1","B024"]:journal.append(entry.duplicate(true))
		seq=w.dispatcher()._seq
	var own: float=k1.timetable.actual_departures[11]
	var other: float=express.timetable.actual_departures[2]
	var premature:=journal.filter(func(e):return e.train=="K1" and e.kind=="replan" and e.text.begins_with("Circular advisory"))
	var tail_clear: bool=Policy.chainage(w,express)-w.stations.filter(func(s):return s.code=="ALLP")[0].s>express.length+500
	var passed: bool=own>other and other>0 and tail_clear and premature.is_empty() and w.events.is_empty()
	var report:={ok=passed,k1_departure=own,b024_arrival=express.timetable.actual_arrivals[2],b024_departure=other,express_tail_clear=tail_clear,premature_replans=premature,safety_events=w.events,journal=journal}
	FileAccess.open("res://.local/r42-alappuzha-overtake.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("ALAPPUZHA ",JSON.stringify(report));quit(0 if passed else 1)
