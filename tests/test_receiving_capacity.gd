extends RefCounted
const Kerala:=preload("res://sim/layouts/kerala_coast.gd")
const Planner:=preload("res://sim/dispatch_planner.gd")

func fixture() -> RailWorld:
	var w:=preload("res://tests/kerala_fixture.gd").historical_crossing()
	w.dispatcher().future_clearances.enabled=false # exercise the conservative fallback separately
	for id in w.trains.keys():
		if id not in ["K1","K2","K3"]: w.trains.erase(id)
	return w

func test_nonplatform_main_is_not_spare_capacity_for_stopping_train():
	var w:=fixture()
	w.place_train(w.trains.K2,"KUMM_P2",400,-1)
	var t: Train=w.trains.K1
	for option in w.route_options(w.next_signal(t).id):
		if Planner.new().admission_reason(w,t,option).is_empty(): return "Booked Kumbalam call admitted with only nonplatform P1 free"
	return true

func test_opposing_claim_from_the_other_section_prevents_kumbalam_deadlock():
	var w:=fixture()
	var e=w.dispatcher()
	e.manual_service="K1"
	w.trains.K1.automatic=false
	w.trains.K1.controller=.7
	e.run_cycle(true)
	if w.signals[w.next_signal(w.trains.K2).id].route.is_empty(): return "Higher priority northbound train did not depart"
	if not w.signals["ERS-S1"].route.is_empty(): return "Both approaches were granted the same remaining passenger platform"
	return w.trains.K1.controller==.7 and e.states.K1.blockers.any(func(b):return b.train=="K2")

func test_early_manual_passenger_claim_is_respected_when_opponent_replans():
	var w:=fixture()
	var t: Train=w.trains.K1
	w.place_train(t,preload("res://tests/kerala_fixture.gd").kumbalam_approach(w),w.graph.edges[preload("res://tests/kerala_fixture.gd").kumbalam_approach(w)].length-100,1)
	t.timetable.index=2;t.timetable.at_stop=false;t.automatic=false
	var e=w.dispatcher();e.manual_service="K1"
	e.run_cycle(true)
	return w.signals[w.next_signal(w.trains.K2).id].route.is_empty() and not w.signals[w.next_signal(t).id].route.is_empty()

func test_departed_vb_releases_a_second_passenger_berth_for_opposing_claims():
	var w:=fixture()
	w.trains.erase("K3")
	w.dispatcher().run_cycle(true)
	return not w.signals["ERS-S1"].route.is_empty() and not w.signals[w.next_signal(w.trains.K2).id].route.is_empty()

func test_typed_berths_use_matching_instead_of_counting_all_roads():
	return Planner._can_berth([{id="express",roads=["P1","P2"]},{id="local",roads=["P1"]}]) and not Planner._can_berth([{id="A",roads=["P2"]},{id="B",roads=["P2"]}])

func test_arrival_road_must_allow_departure_toward_the_following_call():
	var w:=Kerala.build_traffic()
	var t: Train=w.trains.K1
	for i in t.timetable.stops.size():
		if str(t.timetable.stops[i].block).begins_with("AMPA_"):t.timetable.index=i
	t.timetable.at_stop=false
	w.place_train(t,"PUPR_AMPA_M3",w.graph.edges.PUPR_AMPA_M3.length-90,1)
	var choices:=Planner.new().candidates(w,t,w.next_signal(t).id)
	var wrong:=choices.filter(func(o):return o.option.edges[-1].edge=="AMPA_P2")
	return wrong.size()==1 and not wrong[0].available and wrong[0].reason.begins_with("Road cannot reach following call")

func test_early_arrival_does_not_wait_for_opponent_without_a_usable_platform():
	var w:=fixture()
	var t: Train=w.trains.K1
	w.place_train(t,preload("res://tests/kerala_fixture.gd").kumbalam_approach(w),w.graph.edges[preload("res://tests/kerala_fixture.gd").kumbalam_approach(w)].length-100,1)
	t.timetable.index=2;t.timetable.at_stop=false
	w.dispatcher().run_cycle(true)
	return not w.dispatch_holds.has("K1") and not w.signals[w.next_signal(t).id].route.is_empty()

func test_crossing_hold_is_withdrawn_if_opponents_only_platform_becomes_unusable():
	var w:=fixture()
	w.place_train(w.trains.K1,"KUMM_P2",580,1)
	w.dispatch_holds.K1={kind="crossing",other="K2",station="KUMM",chainage=8000,direction=1}
	preload("res://sim/priority_dispatch.gd").update(w)
	return not w.dispatch_holds.has("K1")

func test_nonstop_train_cannot_claim_roads_without_an_exit_to_its_next_call():
	var w:=Kerala.build_traffic()
	var t: Train=w.trains.K1
	for i in t.timetable.stops.size():
		if str(t.timetable.stops[i].block).begins_with("KYJ_"):t.timetable.index=i;break
	t.timetable.at_stop=false
	w.place_train(t,"PUPR_AMPA_M3",w.graph.edges.PUPR_AMPA_M3.length-90,1)
	var st: Dictionary=w.stations.filter(func(s):return s.code=="AMPA")[0]
	var roads: Array=preload("res://sim/receiving_berths.gd").roads(w,t,st,"PUPR_AMPA_M3",1,st.platform_tracks)
	return true if roads==["AMPA_P1"] else "Non-stop next-call reachability ignored: "+str(roads)

func test_following_mail_cannot_consume_the_only_exit_road_of_an_admitted_nonstop_train():
	var decoded: Dictionary=preload("res://sim/service_pack.gd").decode(FileAccess.get_file_as_string("res://art/timetables/kerala-coast-network.json"))
	if not decoded.ok:return decoded.reason
	var w: RailWorld=decoded.world
	w.dispatcher().future_clearances.enabled=false
	for id in w.trains.keys():
		if id not in ["S001","M001","S002"]:w.trains.erase(id)
	for row in [["S001","PUPR_AMPA_M3",1,"KYJ",false],["M001","ALLP_P1",1,"ALLP",true],["S002","AMPA_P2",-1,"ALLP",false]]:
		var t: Train=w.trains[row[0]];t.lifecycle="active"
		for i in t.timetable.stops.size():
			if str(t.timetable.stops[i].block).get_slice("_P",0)==row[3]:t.timetable.index=i;break
		t.timetable.at_stop=row[4]
		w.place_train(t,row[1],w.graph.edges[row[1]].length-90 if row[2]>0 else 90,row[2])
	var follower: Train=w.trains.M001
	var option: Dictionary=w.route_options("ALLP-S1").filter(func(o):return o.destination=="ALLP_PUPR_M0-SA")[0]
	var result:=Planner.new().admission_reason(w,follower,option)
	return true if not result.is_empty() else "Admitted a second P1-only train behind the non-stop leader"
