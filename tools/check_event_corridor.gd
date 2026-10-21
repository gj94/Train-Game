extends SceneTree
## Real Kerala encounters, including a changed driving state, not a booked-time lookup.
const Snapshot := preload("res://sim/world_snapshot.gd")
const EventSkip := preload("res://sim/skip_to_event.gd")
const Detector := preload("res://sim/skip_encounters.gd")
var report := {cases=[],complete=false}
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for item in [
		{clock=31500,service="K1",kind="crossing",other="B045",delayed=false},
		{clock=33000,service="K1",kind="overtaken",other="B001",delayed=false},
		{clock=33000,service="B001",kind="overtaking",other="K1",delayed=false},
		{clock=33000,service="K1",kind="overtaken",other="B001",delayed=true}]:
		var path:="res://data/railway_times/T%06d.bin" % item.clock
		var file:=FileAccess.open_compressed(path,FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
		var restored:=Snapshot.restore(file.get_var(false));file.close();assert(restored.ok)
		var w: RailWorld=restored.world
		if item.delayed:w.trains.B001.speed=0;w.trains.B001.controller=-1
		var options:={"stops":false,"signal":false,"crossing":false,"overtaking":false,"overtaken":false}
		options[item.kind]=true
		var skip:=EventSkip.new(w);skip.to_event(item.service,options)
		var count:=0
		while not skip.done and count<9000:skip.step();count+=1
		var end:=w.clock_seconds()
		var detected:=[];var observer:=Detector.new();observer.sample(w,item.service)
		if skip.done and skip.ok:
			for i in 320:
				w.step(.2)
				for event in observer.sample(w,item.service):
					if event.kind==item.kind and event.other==skip.last_event.other:detected.append(event)
		var event: Dictionary=skip.last_event
		var valid: bool=skip.ok and event.get("kind","")==item.kind and event.get("other","")==item.other and absf(event.get("time",0)-end-60)<.001 and not detected.is_empty() and absf(detected[0].time-event.time)<.1 and w.events.is_empty()
		var row: Dictionary=item.duplicate();row.merge({ok=valid,returned_clock=end,event=event,observed=detected,safety_events=w.events})
		report.cases.append(row);print("CORRIDOR_EVENT ",JSON.stringify(row))
		FileAccess.open("res://.local/r41-corridor-events.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
		if not valid:quit(1);return
	# The slowed express must actually produce a later forecast than baseline.
	report.delayed_pass_is_later=report.cases[3].event.time>report.cases[1].event.time+1
	report.complete=report.delayed_pass_is_later
	FileAccess.open("res://.local/r41-corridor-events.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	quit(0 if report.complete else 1)
