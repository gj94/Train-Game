extends SceneTree
## Continue the actual rejected 140-train candidate, without rearranging traffic.
const Snapshot:=preload("res://sim/world_snapshot.gd")
const Fixture:="res://art/performance/intensive-2026-10-20/orphaned-crossing.bin"
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var file:=FileAccess.open_compressed(Fixture,FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
	var loaded:=Snapshot.restore(file.get_var(false));file.close()
	if not loaded.ok:printerr(loaded.reason);quit(1);return
	var w: RailWorld=loaded.world
	var engine=w.dispatcher()
	var original: Array=engine.future_clearances.plans.duplicate(true)
	var waiting: Train=w.trains.B096
	var road: String=waiting.path[0].edge
	var start:=w.clock_seconds()
	var existed: bool=original.any(func(p):return p.incoming=="D103" and not p.received)
	engine.run_cycle(true)
	var removed: bool=not engine.future_clearances.plans.any(func(p):return p.incoming=="D103")
	var departed:=-1.0
	while w.clock_seconds()<start+1200 and w.events.is_empty():
		w.step(2)
		if waiting.path[0].edge!=road:
			departed=w.clock_seconds();break
	var result:={ok=existed and removed and departed>=0 and w.events.is_empty(),fixture_sha256=FileAccess.get_sha256(Fixture),
		start_clock=start,orphan_removed=removed,b096_departed_after=departed-start if departed>=0 else -1,
		events=w.events,original_plans=original,remaining_plans=engine.future_clearances.plans}
	FileAccess.open("res://.local/orphaned-crossing-recovery.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print(JSON.stringify(result));quit(0 if result.ok else 1)
