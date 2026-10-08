extends RefCounted
const Fixture:=preload("res://tests/overtake_fixture.gd")
const Policy:=preload("res://sim/priority_dispatch.gd")

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
