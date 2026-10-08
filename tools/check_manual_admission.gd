extends SceneTree
## Manual K1 stays outside AI ownership; the harness supplies driver inputs.
## Replays early approach and late departures against the actual Kumbalam throat.
func _init() -> void:
	var failures:=0
	for delay in [-1,600,1200]:
		if "--early-only" in OS.get_cmdline_user_args() and delay!=-1:continue
		var w:=preload("res://tests/test_receiving_capacity.gd").new().fixture()
		var t: Train=w.trains.K1
		var engine=w.dispatcher();engine.enabled=true;engine.manual_service="K1"
		t.automatic=false
		if delay<0:
			w.place_train(t,preload("res://tests/kerala_fixture.gd").kumbalam_approach(w),w.graph.edges[preload("res://tests/kerala_fixture.gd").kumbalam_approach(w)].length-100,1)
			t.timetable.index=2;t.timetable.at_stop=false
		var passed:=false
		var cycle_seconds:=0.0
		var first_cycle:=false
		while w.time<5400 and w.events.is_empty():
			if w.time<delay:t.controller=-1
			else:w._drive_automatic(t) # input driver only; t.automatic remains false
			w.step(.25)
			if engine.alerts.any(func(a):return a.get("kind","")=="conflict"):
				cycle_seconds+=.25
				if not first_cycle:
					first_cycle=true
					print("FIRST_CYCLE ",delay," ",w.clock_text()," ",engine.alerts," ",engine.states.values().map(func(s):return [s.id,s.reason,s.blockers])," positions=",w.trains.values().map(func(v):return [v.id,v.path,v.head_s,v.speed]))
			if t.timetable.index>=4 and w.trains.K2.service_complete:
				passed=true;break
		if not passed or not w.events.is_empty() or t.automatic or cycle_seconds>0:
			failures+=1
			printerr("FAIL manual delay=",delay," time=",w.clock_text()," cycle_seconds=",cycle_seconds," events=",w.events)
		else:print("MANUAL_KUMBALAM delay=",delay," passed at ",w.clock_text()," cycle_seconds=",cycle_seconds)
	print("Manual admission: 3 scenarios, ",failures," failures")
	quit(1 if failures else 0)
