extends SceneTree
const Policy := preload("res://sim/priority_dispatch.gd")
func _init() -> void:
	var failures:=0
	for disturbance in [{id="K1",delay=600},{id="K1",delay=1200},{id="K2",delay=900},{id="K3",delay=1800}]:
		var w:=preload("res://tests/test_receiving_capacity.gd").new().fixture()
		var e=w.dispatcher();e.enabled=true;e.future_clearances.enabled=true
		e.run_cycle(true)
		if e.future_clearances.plans.size()!=1:
			failures+=1;printerr("No initial plan");continue
		var paused: Train=w.trains[disturbance.id]
		paused.automatic=false;paused.controller=-1
		if paused.id=="K1":e.manual_service="K1"
		var completed:=false
		var circular_seconds:=0.0
		var wrong_platform:=false
		var unsafe_release:=false
		var received:=false
		var waiting_at_home:=false
		var finish_s:=0.0
		for st in w.stations:
			if st.code=="TUVR":finish_s=st.s+1000
		while w.time<10800 and w.events.is_empty():
			if w.time>=disturbance.delay:paused.automatic=true
			w.step(.5)
			var incoming: Train=w.trains.K1
			if incoming.path[0].edge.begins_with("KUMM_P") and incoming.path[0].edge!="KUMM_P3":wrong_platform=true
			received=received or (incoming.path.size()==1 and incoming.path[0].edge=="KUMM_P3")
			if w.trains.K2.timetable.actual_departures[1]>=0 and not received:unsafe_release=true
			var ns:=w.next_signal(incoming)
			if not ns.is_empty() and ns.id.begins_with("TNU_KUMM_") and ns.id.ends_with("-SH") and incoming.speed<.1:waiting_at_home=true
			if e.alerts.any(func(a):return a.kind=="conflict"):circular_seconds+=.5
			if w.trains.K2.service_complete and Policy.chainage(w,w.trains.K1)>finish_s and Policy.chainage(w,w.trains.K3)>finish_s:
				completed=true;break
		var ok: bool=completed and w.events.is_empty() and circular_seconds==0 and not wrong_platform and not unsafe_release
		print("FUTURE_DISRUPTION ",JSON.stringify({disturbance=disturbance,ok=ok,completed=completed,time=w.clock_text(),circular_seconds=circular_seconds,wrong_platform=wrong_platform,unsafe_release=unsafe_release,waited_at_home=waiting_at_home,events=w.events}))
		if not ok:failures+=1
	print("Future disruption rehearsals: 4 scenarios, ",failures," failed")
	quit(0 if failures==0 else 1)
