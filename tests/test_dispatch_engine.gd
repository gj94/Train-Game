extends RefCounted
const Traffic := preload("res://sim/layouts/traffic_service.gd")
const Kerala := preload("res://sim/layouts/kerala_coast.gd")
const Prediction := preload("res://sim/dispatch_prediction.gd")
const Resources := preload("res://sim/dispatch_resources.gd")
const Planner := preload("res://sim/dispatch_planner.gd")

func test_world_owns_one_engine_without_reference_cycle():
	var w:=Traffic.build()
	var weak: WeakRef=weakref(w)
	var engine=w.dispatcher()
	if engine!=w.dispatcher(): return "Dispatcher was recreated"
	w=null
	return weak.get_ref()==null and engine._world.get_ref()==null

func test_engine_dispatches_without_scene_or_explicit_update_loop():
	var w:=Traffic.build()
	w.dispatcher().enabled=true
	w.step(1)
	return not w.signals["CPM-E1"].route.is_empty() and w.dispatcher().cycles>=2

func test_disabled_engine_observes_but_does_not_set_routes():
	var w:=Traffic.build()
	w.dispatcher()
	w.step(1)
	return w.signals["CPM-E1"].route.is_empty() and w.dispatcher().states.T1.status=="ready"

func test_engine_manual_authority_does_not_change_handle_or_driver():
	var w:=Traffic.build()
	var t: Train=w.trains.T1
	t.automatic=false;t.controller=-.7
	var engine=w.dispatcher();engine.manual_service=t.id;engine.set_enabled(true)
	return not w.signals["CPM-E1"].route.is_empty() and not t.automatic and t.controller==-.7

func test_operator_hold_and_release():
	var w:=Traffic.build();var e=w.dispatcher()
	e.set_service_hold("T1",true);e.set_enabled(true)
	if not w.signals["CPM-E1"].route.is_empty():return "Held train received route"
	e.set_service_hold("T1",false)
	return not e.operator_holds.has("T1") and not e.states.T1.reason.contains("Operator hold")

func test_put_to_red_is_not_undone_by_auto_dispatch():
	var w:=Traffic.build();var e=w.dispatcher()
	e.set_enabled(true)
	if not e.put_to_red("CPM-E1").ok:return "Cancellation failed"
	w.step(2)
	if w.signals["CPM-E1"].cleared:return "Auto immediately re-cleared operator's red"
	e.release_signal("CPM-E1")
	return not e.inhibited_signals.has("CPM-E1")

func test_put_to_red_retains_approach_lock():
	var w:=Traffic.build();var e=w.dispatcher()
	e.set_enabled(true)
	var t: Train=w.trains.T1
	t.automatic=false;t.speed=15
	t.head_s=w.signals["CPM-E1"].s-10
	e.put_to_red("CPM-E1")
	return w.signals["CPM-E1"].cancel_pending and not w.signals["CPM-E1"].route.is_empty() and w.aspect("CPM-E1")==RailWorld.Aspect.RED

func test_operator_commands_reject_invalid_targets_atomically():
	var w:=Traffic.build();var e=w.dispatcher()
	var old: int=w.trains.T1.dispatch_priority
	return not e.set_priority("T1",101).ok and w.trains.T1.dispatch_priority==old and not e.set_service_hold("missing",true).ok and not e.request_route("missing","missing").ok and not e.put_to_red("missing").ok

func test_automatic_signal_cannot_be_overridden():
	var w:=Traffic.build();var e=w.dispatcher()
	var id: String=w.automatic_signals[0]
	return not e.put_to_red(id).ok and not e.request_route(id,"bad").ok and not e.inhibited_signals.has(id)

func test_dynamic_priority_changes_first_departure_without_hardcoded_id():
	var w:=Traffic.build();var e=w.dispatcher()
	e.set_priority("T5",100);e.set_priority("T1",10)
	e.set_enabled(true)
	var ns:=w.next_signal(w.trains.T5)
	return w.aspect(ns.id)!=RailWorld.Aspect.RED and w.aspect("CPM-E1")==RailWorld.Aspect.RED

func test_waiting_age_prevents_permanent_priority_starvation():
	var w:=Traffic.build();var e=w.dispatcher()
	w.trains.T1.dispatch_priority=0;w.trains.T5.dispatch_priority=100
	e._wait_since.T1=0.0;w.time=2400
	return e._effective_priority(w,w.trains.T1)>e._effective_priority(w,w.trains.T5)

func test_decisions_are_deterministic():
	var a:=Traffic.build();var b:=Traffic.build()
	a.dispatcher().set_enabled(true);b.dispatcher().set_enabled(true)
	for id in a.signals:
		if a.signals[id].destination!=b.signals[id].destination:return "Unstable route choice"
	return JSON.stringify(a.dispatcher().journal)==JSON.stringify(b.dispatcher().journal)

func test_snapshot_cannot_mutate_engine_state():
	var w:=Traffic.build();var e=w.dispatcher();e.run_cycle(false)
	var snapshot: Dictionary=e.snapshot()
	snapshot.services.T1.reason="corrupted";snapshot.journal.clear()
	return e.states.T1.reason!="corrupted" and not e.journal.is_empty()

func test_decision_log_is_bounded_and_monotonic():
	var w:=Traffic.build();var e=w.dispatcher()
	for i in 400:e._record(w,"operator","T1",str(i))
	return e.journal.size()==256 and e.journal[0].seq==145 and e.journal[-1].seq==400

func test_static_decisions_do_not_flood_journal():
	var w:=Traffic.build();var e=w.dispatcher();e.run_cycle(false)
	var count: int=e.journal.size()
	for i in 20:e.run_cycle(false)
	return e.journal.size()==count

func test_dependency_cycles_and_acyclic_queues():
	return Resources.cycles({A=["B"],B=["C"],C=[]}).is_empty() and Resources.cycles({A=["B"],B=["A"],C=[]})==[["A","B"]] and Resources.cycles({A=["B"],B=["C"],C=["A"]})==[["A","B","C"]]

func test_prediction_accounts_for_acceleration_and_speed():
	var standing:=Prediction.travel_seconds(2000,0,25,.5)
	var running:=Prediction.travel_seconds(2000,25,25,.5)
	return standing>running and is_equal_approx(running,80) and Prediction.travel_seconds(INF,0,25,.5)==INF and Prediction.travel_seconds(0,0,25,.5)==0

func test_forecast_marks_signal_wait_as_uncertain():
	var w:=Traffic.build();var forecast:=Prediction.next_call(w,w.trains.T1)
	return forecast.qualified and forecast.arrival>w.clock_seconds() and forecast.booked>0

func test_missed_call_is_not_blame_on_an_unrelated_occupied_road():
	var w:=Kerala.build_traffic();var t: Train=w.trains.K1
	t.timetable.index=1;t.timetable.at_stop=false;t.timetable.missed_stop=true
	w.dispatcher().run_cycle(false)
	return w.dispatcher().states.K1.status=="attention" and w.dispatcher().states.K1.reason.contains("Tirunettur") and w.dispatcher().states.K1.blockers.is_empty()

func test_occupied_platform_does_not_hide_free_kumbalam_alternative():
	var w:=Kerala.build_traffic();var t: Train=w.trains.K1
	t.timetable.index=2;t.timetable.at_stop=false
	w.place_train(t,"TNU_KUMM_M2",w.graph.edges.TNU_KUMM_M2.length-80,1)
	w.place_train(w.trains.K2,"KUMM_P1",400,-1)
	w.trains.erase("K3")
	var e=w.dispatcher();e.manual_service="K1";e.run_cycle(true)
	return e.states.K1.status=="cleared" and t.timetable.stops[2].block!="KUMM_P1" and e.states.K1.blockers.is_empty()

func test_platform_preference_rejects_unreachable_and_nonpassenger_roads():
	var w:=Kerala.build_traffic();var e=w.dispatcher()
	return not e.assign_platform("K1","KUMM_P1").ok and not e.assign_platform("K1","not_a_road").ok and e.platform_preferences.is_empty()

func test_full_receiving_station_prevents_single_line_entry():
	var w:=Kerala.build_traffic();var t: Train=w.trains.K1
	# Kumbalam is the next passing place beyond Tirunettur halt.
	for i in 3:
		var id:="PARKED"+str(i);var parked:=Train.new(id,100)
		w.place_train(parked,"KUMM_P"+str(i+1),500,-1)
	var planner:=Planner.new()
	var options:=w.route_options(w.next_signal(t).id)
	var found:=false
	for option in options:
		var result:=planner.admission_reason(w,t,option)
		if result.get("reason","").contains("Receiving roads at KUMM"):
			found=true
	return found

func test_stale_hold_identity_removed_after_service_replacement():
	var w:=Kerala.build_traffic()
	w.dispatch_holds.K1={other="REMOVED",station="KUMM",kind="crossing"}
	w.dispatcher().run_cycle(false)
	return not w.dispatch_holds.has("K1")

func test_auto_off_removes_discretionary_holds_without_revoking_routes():
	var w:=Traffic.build();var e=w.dispatcher();e.set_enabled(true)
	var count: int=w.signals["CPM-E1"].route.size()
	w.dispatch_holds.T1={other="T2",kind="crossing"}
	e.set_enabled(false)
	return w.dispatch_holds.is_empty() and w.signals["CPM-E1"].route.size()==count

func test_inspection_does_not_hide_or_remove_a_crossing_hold():
	var w:=Kerala.build_traffic();var e=w.dispatcher()
	w.dispatch_holds.K3={other="K2",station="KUMM",kind="crossing",chainage=w.stations[2].s}
	w.time=1200
	e.run_cycle(false)
	return w.dispatch_holds.has("K3") and e.states.K3.status=="held" and e.states.K3.reason.contains("K2")

func test_operator_hold_does_not_accumulate_traffic_priority():
	var w:=Traffic.build();var e=w.dispatcher()
	e.set_service_hold("T1",true);w.time=3600;e.run_cycle(false)
	return e.states.T1.effective_priority==w.trains.T1.dispatch_priority

func test_manual_route_request_honours_receiving_capacity():
	var w:=Kerala.build_traffic();var e=w.dispatcher()
	for i in 3:w.place_train(Train.new("PARKED"+str(i),100),"KUMM_P"+str(i+1),500,-1)
	var id: String=w.next_signal(w.trains.K1).id
	for option in w.route_options(id):
		var result: Dictionary=e.request_route(id,option.destination)
		if result.ok:return "Manual command bypassed receiving capacity"
	return w.signals[id].route.is_empty()

func test_footprint_forward_across_block_boundary_is_exact():
	var graph:=TrackGraph.new()
	for i in 3:graph.add_node(str(i),Vector3(i*1000,0,0))
	graph.add_edge("A","0","1");graph.add_edge("B","1","2")
	var t:=Train.new("LONG",240);t.path=[{edge="B",dir=1},{edge="A",dir=1}];t.head_s=80
	var intervals: Array=preload("res://sim/train_footprint.gd").intervals(graph,t)
	return intervals.size()==2 and intervals[0].length==80 and intervals[1].length==160 and intervals[1].to_s==840

func test_footprint_reverse_preserves_actual_head_tail_positions():
	var graph:=TrackGraph.new()
	for i in 3:graph.add_node(str(i),Vector3(i*1000,0,0))
	graph.add_edge("A","0","1");graph.add_edge("B","1","2")
	var t:=Train.new("LONG",240);t.path=[{edge="A",dir=-1},{edge="B",dir=-1}];t.head_s=920
	var intervals: Array=preload("res://sim/train_footprint.gd").intervals(graph,t)
	return intervals.size()==2 and intervals[0].to_s==1000 and intervals[1].to_s==160

func test_receiving_capacity_claim_counts_committed_following_train():
	var w:=Kerala.build_traffic();var t: Train=w.trains.K1
	# Two roads occupied; a leader is already in the section for the last berth.
	w.trains.erase("K3")
	w.place_train(Train.new("P1",100),"KUMM_P1",500,1)
	w.place_train(Train.new("P2",100),"KUMM_P2",500,1)
	w.place_train(Train.new("LEAD",100),"TNU_P1",600,1)
	var planner:=Planner.new()
	for option in w.route_options(w.next_signal(t).id):
		if planner.admission_reason(w,t,option).get("reason","").contains("Receiving capacity reserved"):return true
	return "Following train could consume the leader's only berth"

func test_advisory_cycle_releases_one_hold_and_prevents_immediate_recreation():
	var w:=Traffic.build();var e=w.dispatcher()
	w.dispatch_holds.T1={other="T2",kind="crossing",station="MRT"}
	w.dispatch_holds.T2={other="T1",kind="crossing",station="MRT"}
	e.states={T1={status="held",blockers=[{train="T2"}],wait_seconds=0},T2={status="held",blockers=[{train="T1"}],wait_seconds=0}}
	e._reconcile_waits(w,true)
	return w.dispatch_holds.size()==1 and e._advisory_release_until.size()==1 and e.journal[-1].kind=="replan"

func test_platform_request_survives_departure_call_index_change():
	var w:=Kerala.build_traffic();var t: Train=w.trains.K1;var e=w.dispatcher()
	if not e.assign_platform("K1","TNU_P1").ok:return "Valid next-call request refused"
	t.timetable.at_stop=false;t.timetable.index=1
	e.run_cycle(false)
	return e.platform_preferences.has("K1")

func test_end_call_rejects_nonpassenger_storage_road():
	var w:=Kerala.build_traffic();var t: Train=w.trains.K3
	t.timetable.index=t.timetable.stops.size()-1;t.timetable.at_stop=false
	t.timetable.stops[-1].block="NCJ_P6"
	w.place_train(t,"NJT_NCJ_D3",w.graph.edges.NJT_NCJ_D3.length-90,1)
	var ns: Dictionary=w.next_signal(t)
	var choices: Array=Planner.new().candidates(w,t,ns.id)
	return not choices.any(func(o):return o.available)
