extends RefCounted
const Kerala := preload("res://sim/layouts/kerala_coast.gd")
const Dispatch := preload("res://sim/dispatch_plan.gd")

func test_manual_stop_accepts_full_train_inside_platform_without_precise_marker():
	var w:=Kerala.build_traffic()
	var t: Train=w.trains.K1
	t.automatic=false
	t.timetable.index=1;t.timetable.at_stop=false
	w.place_train(t,"TNU_P1",t.timetable.stops[1].s+35,1)
	t.timetable.observe(t,w.clock_seconds(),false,w._arrival_tolerance(t))
	return t.timetable.at_stop and t.timetable.actual_arrivals[1]>=0

func test_manual_stop_outside_platform_is_not_counted():
	var w:=Kerala.build_traffic()
	var t: Train=w.trains.K1
	t.automatic=false
	t.timetable.index=1;t.timetable.at_stop=false
	w.place_train(t,"TNU_P1",980,1)
	t.timetable.observe(t,w.clock_seconds(),false,w._arrival_tolerance(t))
	return not t.timetable.at_stop and t.timetable.missed_stop

func test_missed_first_call_explains_kumbalam_deadlock_and_explicit_skip_releases_free_road():
	var w:=Kerala.build_traffic()
	var t: Train=w.trains.K1
	t.automatic=false;t.timetable.index=1;t.timetable.at_stop=false;t.timetable.missed_stop=true
	var road:="TNU_KUMM_M2"
	w.place_train(t,road,w.graph.edges[road].length-80,1)
	var opposing: Train=w.trains.K2
	w.place_train(opposing,"KUMM_P1",400,-1)
	opposing.timetable.index=1;opposing.timetable.at_stop=true;opposing.timetable.actual_arrivals[1]=w.clock_seconds()
	w.trains.erase("K3") # VB has left its platform, as in the reported sequence.
	w.time=20*60
	Dispatch.update(w,false,t.id)
	var ns:=w.next_signal(t)
	if w.signals[ns.id].cleared:return "Fixture did not reproduce rejected alternative platforms"
	if not preload("res://sim/priority_dispatch.gd").hold_reason(w,t,true).contains("Missed stop: Tirunettur"):return "Misleading traffic advice"
	if not t.timetable.skip_missed_stop():return "Explicit recovery failed"
	Dispatch.update(w,false,t.id)
	return w.signals[ns.id].cleared and t.timetable.actual_arrivals[1]<0 and t.timetable.stops[1].skipped and t.timetable.stops[2].block!="KUMM_P1"
