extends RefCounted
const Fixture:=preload("res://tests/overtake_fixture.gd")
const Policy:=preload("res://sim/priority_dispatch.gd")

func test_new_overtake_cannot_hold_an_already_cleared_departure():
	for reverse in [false,true]:
		var w:=Fixture.build(reverse);var t: Train=w.trains.K1
		w.dispatch_holds.erase("K1")
		var starter: String=w.next_signal(t).id
		var option: Dictionary=w.route_options(starter)[0]
		if not w.set_route(starter,option.destination).ok:return "Could not reserve departure"
		Policy.update(w)
		if w.dispatch_holds.has("K1") or not Policy.hold_reason(w,t).is_empty():return "Clear starter contradicted by a new overtake"
		w._drive_automatic(t)
		if t.horn_sequence!=1 or t.controller>=0:return "Committed departure did not begin stationary horns"
		w.time+=5;w._drive_automatic(t)
		if t.horn_sequence!=2 or t.controller<=0:return "Committed departure remained trapped"
	return true

func test_stale_overtake_hold_is_reconciled_with_existing_authority():
	var w:=Fixture.build();var t: Train=w.trains.K1
	var starter: String=w.next_signal(t).id
	if not w.set_route(starter,w.route_options(starter)[0].destination).ok:return "Could not reserve departure"
	Policy.update(w)
	return not w.dispatch_holds.has("K1") and Policy.departure_committed(w,t)

func test_cancelled_starter_does_not_suppress_new_overtake_planning():
	var w:=Fixture.build();var t: Train=w.trains.K1
	var starter: String=w.next_signal(t).id
	if not w.set_route(starter,w.route_options(starter)[0].destination).ok:return "Could not reserve departure"
	w.set_signal(starter,false)
	return not Policy.departure_committed(w,t)

func test_arrived_vb_keeps_overtake_order_after_long_crossing_wait():
	var w:=Fixture.build();var e=w.dispatcher()
	e._wait_since.K1=w.time-1801
	e.run_cycle(true)
	return w.dispatch_holds.has("K1") and w.signals["TUVR-S2"].route.is_empty() and not w.signals["TUVR-S1"].route.is_empty()

func test_northbound_overtake_preserves_order_on_the_other_loop():
	var w:=Fixture.build(true);var e=w.dispatcher();e._wait_since.K1=w.time-1801
	e.run_cycle(true)
	return w.dispatch_holds.has("K1") and w.signals["TUVR-N3"].route.is_empty() and not w.signals["TUVR-N1"].route.is_empty()

func test_fresh_overtake_does_not_inherit_earlier_signal_wait_age():
	var w:=Fixture.build();var e=w.dispatcher();Fixture.on_approach(w,"K3")
	w.dispatch_holds.K1.created=w.time;e._wait_since.K1=w.time-3600
	w.trains.K1.timetable.departure=w.clock_seconds() # This station has only just become ready.
	e.run_cycle(true)
	return w.dispatch_holds.has("K1") and not e._advisory_release_until.has("K1")

func test_manual_driver_remains_held_without_control_handover():
	var w:=Fixture.build();var e=w.dispatcher();e._wait_since.K1=w.time-1801
	w.trains.K1.automatic=false;w.trains.K1.controller=.4;e.manual_service="K1"
	e.run_cycle(true)
	return e.states.K1.status=="held" and not w.trains.K1.automatic and w.trains.K1.controller==.4 and w.aspect("TUVR-S2")==RailWorld.Aspect.RED

func test_overtake_survives_head_departure_until_full_tail_clearance():
	var w:=Fixture.build();Policy.update(w)
	Fixture.just_departed(w,w.trains.K3.length+490)
	Policy.update(w)
	if not w.dispatch_holds.has("K1") or not Policy.overtake_in_progress(w,w.dispatch_holds.K1):return "Released before the tail cleared"
	Fixture.just_departed(w,w.trains.K3.length+510)
	Policy.update(w)
	return not w.dispatch_holds.has("K1") and w.dispatch_history.any(func(h):return h.train=="K1" and h.other=="K3" and h.kind=="overtake")

func test_unarrived_express_can_still_be_replanned_after_a_long_overtake_hold():
	var w:=Fixture.build();var e=w.dispatcher();Fixture.on_approach(w,"K3")
	e.run_cycle(true)
	return not w.dispatch_holds.has("K1") and e._advisory_release_until.has("K1") and e.journal.any(func(j):return j.kind=="replan")

func test_unavailable_arrived_express_does_not_block_everyone_forever():
	for reason in ["emergency","operator","signal"]:
		var w:=Fixture.build();var e=w.dispatcher();e._wait_since.K1=w.time-1801
		if reason=="emergency":w.trains.K3.emergency=true
		elif reason=="operator":e.operator_holds.K3=true
		else:e.inhibited_signals["TUVR-S1"]=true
		e.run_cycle(true)
		if w.dispatch_holds.has("K1") or not e._advisory_release_until.has("K1"):return "Could not replan "+reason
	return true

func test_replanning_never_revokes_existing_express_authority():
	var w:=Fixture.build();var e=w.dispatcher()
	var option: Dictionary=w.route_options("TUVR-S1")[0]
	if not w.set_route("TUVR-S1",option.destination).ok:return "Could not establish express authority"
	w.trains.K3.emergency=true;e._wait_since.K1=w.time-1801;e.run_cycle(true)
	return not w.signals["TUVR-S1"].route.is_empty() and w.signals["TUVR-S2"].route.is_empty()

func test_successive_express_cannot_restart_the_same_station_wait():
	var w:=Fixture.build();var e=w.dispatcher();Fixture.on_approach(w,"K3")
	w.dispatch_holds.K1.created=w.time # A newly chosen express, after thirty minutes here.
	w.trains.K1.timetable.departure=w.clock_seconds()-1801
	e.run_cycle(true)
	return not w.dispatch_holds.has("K1") and Policy.conflict(w,w.trains.K1,Policy.station(w,"TUVR_P2")).is_empty()

func test_public_dwell_and_passenger_exchange_do_not_consume_wait_budget():
	var w:=Fixture.build();Fixture.on_approach(w,"K3")
	w.trains.K1.timetable.passenger_release=w.clock_seconds()+30
	w.dispatch_holds.erase("K1")
	w.dispatcher().run_cycle(true)
	return w.dispatch_holds.has("K1")

func test_wait_budget_does_not_reopen_after_two_minute_backoff():
	var w:=Fixture.build();var e=w.dispatcher();Fixture.on_approach(w,"K3")
	w.trains.K1.timetable.departure=w.clock_seconds()-1801
	e.inhibited_signals["TUVR-S2"]=true
	e.run_cycle(true);w.time+=121
	e.run_cycle(true)
	return not w.dispatch_holds.has("K1") and Policy.conflict(w,w.trains.K1,Policy.station(w,"TUVR_P2")).is_empty()

func test_previous_station_lateness_does_not_use_new_station_budget():
	var w:=Fixture.build();var t: Train=w.trains.K1;Fixture.on_approach(w,"K3")
	t.timetable.departure=w.clock_seconds()-3600
	t.timetable.passenger_release=w.clock_seconds()-30
	w.dispatch_holds.K1.created=w.time
	w.dispatcher().run_cycle(true)
	return w.dispatch_holds.has("K1")

func test_wait_budget_survives_save_load_and_next_express_selection():
	var w:=Fixture.build();Fixture.on_approach(w,"K3")
	w.trains.K1.timetable.departure=w.clock_seconds()-1801
	w.dispatch_holds.K1.created=w.time
	var restored:=preload("res://sim/world_snapshot.gd").restore(preload("res://sim/world_snapshot.gd").capture(w))
	if not restored.ok:return restored.reason
	var other: RailWorld=restored.world
	other.dispatcher().run_cycle(true)
	return not other.dispatch_holds.has("K1")

func test_ten_minutes_is_not_a_hard_overtake_cutoff():
	var w:=Fixture.build();Fixture.on_approach(w,"K3")
	w.trains.K1.timetable.departure=w.clock_seconds()-660
	w.dispatch_holds.K1.created=w.time
	w.dispatcher().run_cycle(true)
	return w.dispatch_holds.has("K1")
