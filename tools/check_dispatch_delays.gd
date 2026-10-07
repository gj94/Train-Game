extends SceneTree
## Real-route timing variations; the world owns the dispatcher throughout.
func _init():
	var failed:=false
	for variant in [0,480,1200]:
		var w=preload("res://sim/layouts/kerala_coast.gd").build_traffic()
		var e=w.dispatcher();e.enabled=true;e.manual_service="K1"
		var t: Train=w.trains.K1;t.automatic=false;t.controller=-1
		var started:=Time.get_ticks_msec()
		for tick in 2400:
			if w.time>=variant:t.automatic=true
			w.step(2)
			if not w.events.is_empty():failed=true;printerr("DELAY_SAFETY ",variant," ",w.events);break
			if tick%600==0:print("DELAY_PROGRESS ",variant," ",w.clock_text()," ",t.path[0].edge)
		var okay: bool=w.events.is_empty() and w.trains.K2.service_complete and t.timetable.index>=7
		failed=failed or not okay
		print("DELAY_CASE ",variant," ","PASS" if okay else "FAIL"," call=",t.timetable.index," edge=",t.path[0].edge," elapsed=",(Time.get_ticks_msec()-started)*.001)
		if not okay:print(JSON.stringify(e.snapshot().services))
	quit(1 if failed else 0)
