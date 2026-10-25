extends RefCounted
const Fixture := preload("res://tests/test_exit_capacity.gd")
const Planner := preload("res://sim/dispatch_planner.gd")

func fixture(with_arrival: bool = true) -> RailWorld:
	var f := Fixture.new()
	var w: RailWorld = f.fixture()
	f.add(w,"I",["PASA_P2","NYY_P2","NEM_P1","TVC_P2"],-1)
	f.add(w,"V",["NYY_P1","NEM_P1","TVC_P2"],-1)
	var o: Train = f.add(w,"O",["NEM_P1","NYY_P2","PASA_P1"],1)
	w.place_train(o,"NEM_BRAM_M0",300,1)
	o.timetable.index=1;o.timetable.at_stop=false
	f.add(w,"H",["NEM_P2","NYY_P1","PASA_P1"],1)
	if with_arrival:
		var a: Train = f.add(w,"ARRIVAL",["TVC_P1","NEM_P1","NYY_P1"],1)
		w.place_train(a,"TVC_NEM_M5",300,1)
		a.timetable.index=1;a.timetable.at_stop=false
	return w

func test_escape_berth_cannot_steal_an_already_admitted_arrivals_capacity():
	var w:=fixture();var e=w.dispatcher()
	var st: Dictionary=w.stations.filter(func(s):return s.code=="NEM")[0]
	var claims:=Planner.new()._station_claims(w,st)
	if not claims.any(func(c):return c.id=="ARRIVAL"):return "Fixture lost the admitted arrival"
	return e.future_clearances.propose(w,e,w.trains.I).is_empty()

func test_escape_remains_available_without_the_conflicting_admitted_arrival():
	var w:=fixture(false);var e=w.dispatcher()
	var p: Dictionary=e.future_clearances.propose(w,e,w.trains.I)
	return not p.is_empty() and p.escape_road=="NEM_P1" and p.vacater=="V"

func test_escape_respects_an_arrival_with_a_departure_route_already_granted():
	var w:=fixture();var e=w.dispatcher();var t: Train=w.trains.ARRIVAL
	w.place_train(t,"TVC_P1",preload("res://sim/berth_clearance.gd").marker(w,t,"TVC_P1",1),1)
	var ns:=w.next_signal(t)
	var options: Array=w.route_options(ns.id).filter(func(o):return o.edges[-1].edge=="TVC_NEM_M0")
	if options.size()!=1:return "Fixture departure option missing"
	var granted: Dictionary=w.set_route(ns.id,options[0].destination)
	if not granted.ok:return granted.reason
	return e.future_clearances.propose(w,e,w.trains.I).is_empty()
