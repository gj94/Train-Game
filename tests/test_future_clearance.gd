extends RefCounted
const Fixture := preload("res://tests/test_receiving_capacity.gd")
const Future := preload("res://sim/future_clearance.gd")
const Planner := preload("res://sim/dispatch_planner.gd")

func _world() -> RailWorld:
	return Fixture.new().fixture()

func _activate(w):
	var e=w.dispatcher()
	e.future_clearances.enabled=true
	e.run_cycle(true)
	return e

func test_future_crossing_reserves_three_distinct_compatible_berths():
	var w:=_world();var e=_activate(w)
	if e.future_clearances.plans.size()!=1:return "No crossing plan"
	var p: Dictionary=e.future_clearances.plans[0]
	return p.incoming=="K1" and p.opponent=="K2" and p.vacater=="K3" and p.future_road=="KUMM_P3" and p.opponent_road=="KUMM_P2" and p.escape_road=="TUVR_P3"

func test_both_approaches_clear_but_occupied_vb_platform_stays_red():
	var w:=_world();var e=_activate(w)
	if w.aspect("ERS-S1")==RailWorld.Aspect.RED or w.aspect(w.next_signal(w.trains.K2).id)==RailWorld.Aspect.RED:return "Safe approach was not admitted"
	w.place_train(w.trains.K1,preload("res://tests/kerala_fixture.gd").kumbalam_approach(w),w.graph.edges[preload("res://tests/kerala_fixture.gd").kumbalam_approach(w)].length-80,1)
	w.trains.K1.timetable.index=2;w.trains.K1.timetable.at_stop=false
	e.run_cycle(true)
	return w.aspect(w.next_signal(w.trains.K1).id)==RailWorld.Aspect.RED and w.trains.K3.path[0].edge=="KUMM_P3"

func test_vacater_manual_or_unscheduled_cannot_promise_a_vacancy():
	var w:=_world();var e=w.dispatcher()
	w.trains.K3.automatic=false
	if not e.future_clearances.propose(w,e,w.trains.K1).is_empty():return "Manual departure was promised"
	w.trains.K3.automatic=true;w.trains.K3.timetable=null
	return e.future_clearances.propose(w,e,w.trains.K1).is_empty()

func test_operator_hold_or_red_on_vacater_refuses_plan():
	var w:=_world();var e=w.dispatcher()
	e.operator_holds.K3=true
	if not e.future_clearances.propose(w,e,w.trains.K1).is_empty():return "Held vacater was promised"
	e.operator_holds.clear();e.inhibited_signals["KUMM-S3"]=true
	return e.future_clearances.propose(w,e,w.trains.K1).is_empty()

func test_occupied_escape_berths_are_not_replaced_by_another_forecast():
	var w:=_world();var e=w.dispatcher()
	for road in ["TUVR_P1","TUVR_P3"]: # K2 already occupies P2
		w.place_train(Train.new("BLOCK_"+road,100),road,500,1)
	return e.future_clearances.propose(w,e,w.trains.K1).is_empty()

func test_vacater_must_escape_away_from_incoming_approach():
	var w:=_world();var e=w.dispatcher()
	w.trains.K3.path[0].dir=-1
	return e.future_clearances.propose(w,e,w.trains.K1).is_empty()

func test_incoming_section_cannot_already_contain_an_unrelated_service():
	var w:=_world();var e=w.dispatcher()
	w.place_train(Train.new("FOLLOWER",100),"ERS_TNU_M0",200,1)
	return e.future_clearances.propose(w,e,w.trains.K1).is_empty()

func test_far_future_departure_is_not_an_admission_promise():
	var w:=_world();var e=w.dispatcher()
	w.trains.K3.timetable.departure+=3600
	return e.future_clearances.propose(w,e,w.trains.K1).is_empty()

func test_wrong_length_or_platform_face_refuses_future_berth():
	var w:=_world();var e=w.dispatcher()
	w.trains.K1.length=w.graph.edges.KUMM_P3.length+1
	return e.future_clearances.propose(w,e,w.trains.K1).is_empty()

func test_new_plan_cannot_steal_an_existing_crossings_resources():
	var w:=_world();var e=_activate(w)
	return e.future_clearances.propose(w,e,w.trains.K1).is_empty() and e.future_clearances.owner("KUMM_P3")=="K1" and e.future_clearances.owner("TUVR_P3")=="K3"

func test_planned_opponent_stays_until_full_incoming_tail_arrives():
	var w:=_world();var e=_activate(w)
	w.place_train(w.trains.K2,"KUMM_P2",400,-1)
	w.trains.K1.path=[{edge="KUMM_P3",dir=1},{edge=preload("res://tests/kerala_fixture.gd").kumbalam_approach(w),dir=1}]
	e.future_clearances.update(w,e,false)
	if e.future_clearances.hold(w,w.trains.K2).is_empty():return "Released opponent before incoming tail cleared"
	w.trains.K1.path=[{edge="KUMM_P3",dir=1}]
	e.future_clearances.update(w,e,false)
	return e.future_clearances.hold(w,w.trains.K2).is_empty()

func test_late_vacater_does_not_time_out_and_release_a_reserved_platform():
	var w:=_world();var e=_activate(w)
	w.place_train(w.trains.K2,"KUMM_P2",400,-1)
	w.time=3600;w.trains.K3.emergency=true
	e.future_clearances.update(w,e,false)
	return e.future_clearances.owner("KUMM_P3")=="K1" and not e.future_clearances.hold(w,w.trains.K2).is_empty()

func test_unrelated_train_cannot_take_escape_corridor_or_berth():
	var w:=_world();var e=_activate(w)
	var other:=Train.new("OTHER",100)
	var section_option:={edges=[{edge="KUMM_AROR_M0",dir=1}]}
	var berth_option:={edges=[{edge="TUVR_P3",dir=1}]}
	return not e.future_clearances.section_reason(w,other,section_option).is_empty() and not e.future_clearances.section_reason(w,other,berth_option).is_empty()

func test_received_train_can_follow_vacater_under_normal_block_protection():
	var w:=_world();var e=_activate(w)
	e.future_clearances.plans[0].received=true
	return e.future_clearances.section_reason(w,w.trains.K1,{edges=[{edge="KUMM_AROR_M0",dir=1}]}).is_empty() and not e.future_clearances.admission(w.trains.K1,"KUMM_single")

func test_platform_preference_is_respected_before_planning():
	var w:=_world();var e=w.dispatcher()
	e.platform_preferences.K2={block="KUMM_P2"}
	return e.future_clearances.propose(w,e,w.trains.K1).is_empty()

func test_inspection_does_not_create_an_optimistic_plan():
	var w:=_world();var e=w.dispatcher();e.future_clearances.enabled=true
	e.run_cycle(false)
	return e.future_clearances.plans.is_empty() and w.signals["ERS-S1"].route.is_empty()

func test_manual_player_gets_approach_authority_without_losing_control():
	var w:=_world();var e=w.dispatcher()
	w.trains.K1.automatic=false;w.trains.K1.controller=-.8;e.manual_service="K1"
	e.future_clearances.enabled=true;e.run_cycle(true)
	return e.future_clearances.plans.size()==1 and w.aspect("ERS-S1")!=RailWorld.Aspect.RED and not w.trains.K1.automatic and w.trains.K1.controller==-.8

func test_plan_snapshot_is_isolated_from_ui_mutation():
	var w:=_world();var e=_activate(w)
	var snapshot: Dictionary=e.snapshot();snapshot.future_plans[0].received=true
	return not e.future_clearances.plans[0].received

func test_existing_home_authority_cannot_be_replaced_by_a_future_platform_promise():
	var f:=preload("res://tests/test_exit_capacity.gd").new()
	var w: RailWorld=f.fixture();var e=w.dispatcher()
	var t: Train=f.add(w,"I",["AMPA_P2","ALLP_P2","MAKM_P2"],-1)
	var v: Train=f.add(w,"V",["ALLP_P1","MAKM_P2","SRTL_P2"],-1)
	f.add(w,"O",["MAKM_P3","ALLP_P3","AMPA_P1"],1)
	v.timetable.departure+=300
	var home:={}
	for sig in w.signals.values():
		if sig.dir==-1 and w.route_options(sig.id).any(func(o):return o.edges[-1].edge=="ALLP_P2"):
			home=sig;break
	if home.is_empty():return "Fixture has no ALLP home"
	w.place_train(t,home.edge,home.s+80,-1);t.timetable.index=1;t.timetable.at_stop=false
	var option: Dictionary=w.route_options(home.id).filter(func(o):return o.edges[-1].edge=="ALLP_P2")[0]
	var granted: Dictionary=w.set_route(home.id,option.destination)
	if not granted.ok:return granted.reason
	# ALLP's depot access is still part of the approach section after the home.
	# A later promise of P1 would conflict with the committed arrival into P2.
	return e.future_clearances.propose(w,e,t).is_empty()

func test_future_crossing_order_overrides_an_existing_advisory_overtake():
	var w:=_world();var e=_activate(w)
	w.place_train(w.trains.K1,preload("res://tests/kerala_fixture.gd").kumbalam_approach(w),50,1)
	w.trains.K1.timetable.index=2;w.trains.K1.timetable.at_stop=false
	w.dispatch_holds.K3={kind="overtake",other="K1",station="KUMM",chainage=8000,direction=1,created=w.time,arrived=true}
	preload("res://sim/priority_dispatch.gd").update(w)
	return not w.dispatch_holds.has("K3") and not e.future_clearances.hold(w,w.trains.K3).is_empty()

func test_future_vacater_does_not_accept_a_new_advisory_overtake():
	var w:=_world();var e=_activate(w)
	w.trains.K1.dispatch_priority=100;w.trains.K3.dispatch_priority=10
	w.place_train(w.trains.K1,preload("res://tests/kerala_fixture.gd").kumbalam_approach(w),50,1)
	w.trains.K1.timetable.index=2;w.trains.K1.timetable.at_stop=false
	preload("res://sim/priority_dispatch.gd").update(w)
	return not w.dispatch_holds.has("K3")
