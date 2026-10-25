extends RefCounted
const Fixture := preload("res://tests/test_exit_capacity.gd")
const Planner := preload("res://sim/dispatch_planner.gd")

func fixture() -> RailWorld:
	var f:=Fixture.new()
	var w: RailWorld=f.fixture()
	w.dispatcher().future_clearances.enabled=true
	f.add(w,"S",["PASA_P1","KZT_P1","ERL_P1","NCJ_P1"],1)
	f.add(w,"N1",["KZT_P2","PASA_P2","NYY_P1","NEM_P1","TVC_P2"],-1)
	f.add(w,"N2",["KZT_P1","PASA_P2","NYY_P1","NEM_P1","TVC_P2"],-1)
	var arriving: Train=f.add(w,"ARRIVING",["KZT_P2","PASA_P2","NYY_P1","NEM_P1","TVC_P2"],-1)
	w.place_train(arriving,"PASA_KZTW_M0",100,-1)
	arriving.timetable.index=1;arriving.timetable.at_stop=false
	return w

func test_admitted_arrival_can_finish_into_its_only_compatible_free_road():
	var w:=fixture()
	var t: Train=w.trains.ARRIVING
	var p:=Planner.new()
	var st: Dictionary=w.stations.filter(func(s):return s.code=="PASA")[0]
	var claims:=p._station_claims(w,st)
	if not claims.any(func(c):return c.id==t.id):return "Fixture lost the admitted approach"
	if not Planner._can_berth(claims):return "Fixture already overfills the receiving station"
	var choices:=p.candidates(w,t,w.next_signal(t).id)
	var free: Array=choices.filter(func(c):return c.option.edges[-1].edge=="PASA_P2")
	return free.size()==1 and free[0].available

func test_four_train_crossing_drains_after_admitted_arrival_finishes():
	var w:=fixture()
	w.dispatcher().enabled=true
	for i in 5400:
		w.step(2.0)
		if not w.events.is_empty():return str(w.events)
		if w.trains.values().all(func(t):return t.service_complete):return true
	return "Admitted crossing did not drain: "+str(w.dispatcher().states)
