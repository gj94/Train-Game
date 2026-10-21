extends RefCounted
const Fixture := preload("res://tests/overtake_fixture.gd")

func arriving(reverse: bool=false) -> RailWorld:
	var w:=Fixture.build(reverse);var t: Train=w.trains.K1
	# Head still approaching its booked marker; its next signal is the starter.
	t.timetable.at_stop=false
	t.head_s=t.timetable.stops[0].s-t.path[0].dir*150
	t.speed=8
	return w

func test_arrival_dependency_does_not_cancel_promised_overtake():
	for reverse in [false,true]:
		var w:=arriving(reverse);var e=w.dispatcher()
		var state: Dictionary=e._evaluate(w,w.trains.K1,false)
		if state.status!="arriving":return "Starter hold misclassified an arrival"
		e.states={K1=state,K3={status="waiting",blockers=[{train="K1"}],wait_seconds=0}}
		e._reconcile_waits(w,true)
		if not w.dispatch_holds.has("K1") or not e._advisory_release_until.is_empty():return "Transient approach occupancy cancelled overtake"
	return true

func test_manual_arrival_keeps_driver_and_departure_order():
	var w:=arriving();var t: Train=w.trains.K1;var e=w.dispatcher()
	t.automatic=false;t.controller=-.3;e.manual_service=t.id
	var state: Dictionary=e._evaluate(w,t,true)
	return state.status=="arriving" and w.dispatch_holds.has(t.id) and not t.automatic and t.controller==-.3 and w.signals[state.signal_id].route.is_empty()

func test_completed_arrival_still_waits_for_the_committed_overtaker():
	var w:=arriving();var t: Train=w.trains.K1
	t.head_s=t.timetable.stops[0].s;t.speed=0;t.timetable.at_stop=true
	var state: Dictionary=w.dispatcher()._evaluate(w,t,true)
	return state.status=="held" and state.blockers.any(func(b):return b.train=="K3") and w.signals[state.signal_id].route.is_empty()

func test_signal_before_booked_stop_is_not_hidden_by_arrival_state():
	var w:=arriving();var t: Train=w.trains.K1;var ns:=w.next_signal(t)
	# An earlier home/approach signal must still be evaluated normally.
	var state: Dictionary=w.dispatcher()._evaluate(w,t,false,{id=ns.id,distance=20.0})
	return state.status!="arriving"
