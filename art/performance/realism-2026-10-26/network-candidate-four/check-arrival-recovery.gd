extends SceneTree
## Limited continuation of a rejected historical state; never baseline data.
func _initialize():call_deferred("run")
func run():
	var mode:="classic"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):mode=arg.trim_prefix("--mode=")
	var folder:="res://.local/realism-2026-10-26/rehearsals-v4/"+mode+"-network-delayed"
	var f:=FileAccess.open(folder+"/failure.bin",FileAccess.READ)
	var restored: Dictionary=preload("res://sim/world_snapshot.gd").restore(f.get_var());f.close()
	if not restored.ok:printerr(restored.reason);quit(1);return
	var w: RailWorld=restored.world
	var ids: Array=["L002","L021","L033","V005"] if mode=="classic" else ["L002","L022","M061","M078"]
	var initial:={};var cleared:={}
	for id in ids:initial[id]=w.trains[id].path.map(func(p):return p.edge)
	var start: float=w.clock_seconds()
	for i in 1800:
		w.step(2.0)
		for id in ids:
			if not cleared.has(id) and not w.trains[id].path.any(func(p):return p.edge in initial[id]):cleared[id]=w.clock_seconds()
		if not w.events.is_empty() or cleared.size()==ids.size():break
	var result:={scope="Limited historical failure-state continuation, not a baseline or complete-day acceptance",mode=mode,input_sha256=FileAccess.get_sha256(folder+"/failure.bin"),planner_sha256=FileAccess.get_sha256("res://sim/dispatch_planner.gd"),start=start,finish=w.clock_seconds(),initial_roads=initial,cleared_at=cleared,events=w.events,all_cleared=cleared.size()==ids.size()}
	FileAccess.open("res://.local/realism-2026-10-26/arrival-recovery-"+mode+".json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print(JSON.stringify(result));quit(0 if result.all_cleared and w.events.is_empty() else 1)
