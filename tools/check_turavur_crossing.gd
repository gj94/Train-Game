extends SceneTree
## Actual three-train motion: opposing ICF enters, VB departs, local follows.
func _init() -> void:
	var w=preload("res://tests/overtake_fixture.gd").build();var e=w.dispatcher()
	# The passenger has already finished boarding and spent a long time at red.
	var pax=preload("res://sim/passenger_service.gd")
	pax.update(w,w.trains.K1,0);pax.update(w,w.trains.K1,300)
	w.trains.K1.timetable.passenger_release=w.clock_seconds()-1
	var icf: Train=w.trains.K4;var road:="TUVR_VAY_M0"
	w.place_train(icf,road,w.graph.edges[road].length-icf.length-20,-1)
	icf.timetable.at_stop=false;icf.timetable.index=0
	e._wait_since.K1=w.time-1801;e.enabled=true
	var admitted:=-1.0;var express:=-1.0;var local:=-1.0;var last:=""
	for i in 900:
		w.step(2)
		if icf.path.size()==1 and icf.path[0].edge=="TUVR_P3" and admitted<0:admitted=w.clock_seconds()
		if not w.signals["TUVR-S1"].route.is_empty() and express<0:express=w.clock_seconds()
		if not w.signals["TUVR-S2"].route.is_empty() and local<0:local=w.clock_seconds()
		var now: String=str(e.states.K1.status)+"/"+str(e.states.K3.status)+"/"+icf.path[0].edge
		if now!=last:
			print("TURAVUR ",w.clock_text()," ",now," ",e.states.K1.reason);last=now
		if not w.events.is_empty():printerr("SAFETY ",w.events);quit(1);return
		if local>=0:break
	var ok: bool=admitted>=0 and express>=admitted and local>express
	print("TURAVUR_ORDER ",{opponent_contained=admitted,vb_clear=express,local_clear=local,ok=ok})
	quit(0 if ok else 1)
