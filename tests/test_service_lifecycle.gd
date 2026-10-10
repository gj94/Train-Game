extends RefCounted
const Life := preload("res://sim/service_lifecycle.gd")
const Kerala := preload("res://sim/layouts/kerala_coast.gd")
const Pack := preload("res://sim/service_pack.gd")

func fixture() -> RailWorld:
	var w:=RailWorld.new()
	w.graph.add_node("A",Vector3.ZERO);w.graph.add_node("B",Vector3(1200,0,0));w.graph.add_node("C",Vector3(2400,0,0))
	w.graph.add_edge("P","A","B");w.graph.add_edge("E","B","C")
	w.add_signal("S","P",1,10)
	for id in ["A","B"]:
		var t:=Train.new(id,100);w.place_train(t,"P",800,1)
		w.set_timetable(id,{departure="08:10",stops=[{block="P",direction=1,position_m=800,minutes_from_origin=0},{block="E",direction=1,position_m=800,minutes_from_origin=5}]})
		t.lifecycle="scheduled";t.automatic=true
	return w

func test_scheduled_services_have_no_occupancy_or_route_claims():
	var w:=fixture();w.step(2)
	return w.occupancy().is_empty() and w.active_trains().is_empty() and w.trains.A.odometer==0

func test_entry_waits_until_preparation_and_admits_only_one_train():
	var w:=fixture();w.time=479;Life.update(w)
	if not w.active_trains().is_empty():return "Entered early"
	w.time=480;Life.update(w)
	return w.active_trains().size()==1 and w.trains.A.lifecycle=="active" and w.trains.B.lifecycle=="scheduled"

func test_occupied_and_reserved_origin_block_entry():
	var w:=fixture();w.time=480
	w.signals.S.route=[{edge="P",dir=1}]
	Life.update(w)
	if not w.active_trains().is_empty():return "Spawned inside authority"
	w.signals.S.route=[];w.trains.A.lifecycle="active";Life.update(w)
	return w.trains.B.lifecycle=="scheduled"

func test_step_refreshes_newly_entered_occupancy():
	var w:=fixture();w.time=479.95;w.step(.1)
	return w.occupancy().get("P","")=="A" and w.trains.B.lifecycle=="scheduled"

func test_stored_trains_have_no_occupancy_but_retain_results():
	var w:=fixture();var t: Train=w.trains.A
	t.lifecycle="active";t.service_complete=true;t.depot={phase="stabled",stabled_at=w.clock_seconds()-601}
	w.depots.P={};w.depot_reservations.P=t.id
	Life.update(w)
	return t.lifecycle=="stored" and w.occupancy().is_empty() and t.service_complete and not w.depot_reservations.has("P")

func test_player_stock_is_not_stored_under_the_camera():
	var w:=fixture();var t: Train=w.trains.A
	t.lifecycle="active";t.service_complete=true;t.depot={phase="stabled",stabled_at=w.clock_seconds()-601}
	w.depots.P={};w.dispatcher().manual_service="A";Life.update(w)
	return t.lifecycle=="active"

func test_busy_day_has_100_reachable_full_rakes_and_no_initial_overlap():
	var w:=Kerala.build_traffic(true)
	if w.trains.size()!=100:return "Need exactly 100 workings"
	var roads:={}
	for t: Train in w.active_trains():
		for seg in t.path:
			if roads.has(seg.edge):return "Initial overlap on "+seg.edge
			roads[seg.edge]=t.id
	for t: Train in w.trains.values():
		for i in range(1,t.timetable.stops.size()):
			var a: Dictionary=t.timetable.stops[i-1];var b: Dictionary=t.timetable.stops[i]
			if is_inf(w._stop_distance(a.block,a.direction,a.s,b,[])):return t.id+" cannot reach "+b.block
	return w.trains.K1.timetable.stops.size()==55 and w.active_trains().size()<10

func test_busy_pack_round_trip_keeps_scheduled_services_and_depots():
	var data:=Pack.defaults("kerala_coast",true)
	var result:=Pack.decode(JSON.stringify(data))
	if not result.ok:return result.reason
	return result.world.trains.size()==100 and result.world.trains.B020.lifecycle=="scheduled" and result.world.active_trains().size()<10

func test_busy_save_round_trip_preserves_lifecycle():
	var w:=Kerala.build_traffic(true)
	var save=preload("res://sim/world_snapshot.gd")
	var result: Dictionary=save.restore(save.capture(w))
	if not result.ok:return result.reason
	return result.world.trains.B020.lifecycle=="scheduled" and result.world.occupancy()==w.occupancy()

func test_current_dictionary_session_does_not_break_legacy_speed_migration():
	var save=preload("res://sim/world_snapshot.gd")
	var w:=Kerala.build_traffic(true)
	w.trains.K1.max_speed=65.0/3.6
	var checkpoint: Dictionary=save.capture(w,{authored_pack={},meta={}})
	var result: Dictionary=save.restore(checkpoint)
	if not result.ok or not is_equal_approx(result.world.trains.K1.max_speed,110.0/3.6):return "Built-in session dictionary did not migrate"
	checkpoint.session.authored_pack={name="Custom working"}
	result=save.restore(checkpoint)
	return result.ok and is_equal_approx(result.world.trains.K1.max_speed,65.0/3.6)

func test_inactive_dispatch_states_are_inspectable_without_authority():
	var w:=fixture();w.dispatcher().run_cycle(true)
	return w.dispatcher().states.A.status=="scheduled" and w.dispatcher().alerts.is_empty() and w.signals.S.route.is_empty()

func test_removing_future_service_does_not_cancel_active_departure():
	var w:=fixture();w.trains.A.lifecycle="active"
	w.set_route("S","BUFFER:C")
	var result: Dictionary=w.dispatcher().delete_service("B","A")
	return result.ok and w.signals.S.cleared and not w.signals.S.route.is_empty()

func test_route_direction_index_survives_multiple_physics_slices():
	var w:=fixture();w.trains.A.lifecycle="active"
	w.set_route("S","BUFFER:C")
	w.step(.15)
	# Clearing the per-slice reference must not erase the shared direction map.
	return w._direction_claims.get("E",0)==1

func test_entry_preserves_sole_passenger_face_for_incoming_train():
	var w:=Kerala.build()
	var station: Dictionary=w.stations.filter(func(st):return st.code=="KUMM")[0]
	var face: String=station.platform_tracks.filter(func(r):return station.platform_details[r].platform_width>0)[0]
	var pending:=Train.new("NEW",180)
	var marker: float=preload("res://sim/berth_clearance.gd").marker(w,pending,face,1)
	w.place_train(pending,face,marker,1);pending.lifecycle="scheduled"
	if not Life.can_enter(w,pending):return "Empty receiving station should allow entry"
	var incoming:=Train.new("IN",180)
	var road: String=w.single_line_sections.keys().filter(func(r):return r.begins_with("TNU_KUMM"))[0]
	w.place_train(incoming,road,400,1)
	incoming.timetable=preload("res://sim/timetable.gd").new()
	incoming.timetable.stops=[{block="TNU_P1",direction=1,s=800.0},{block=face,direction=1,s=marker}]
	incoming.timetable.index=1;incoming.timetable.at_stop=false
	return not Life.can_enter(w,pending)

func test_stall_detector_exempts_future_departures():
	var w:=fixture()
	var trial:=preload("res://sim/service_trial.gd").new(w)
	w.time=500
	if trial._stalled():return "Mistook a booked wait for a deadlock"
	w.time=850
	return trial._stalled()

func test_terminal_arrival_can_use_another_compatible_platform():
	var w:=Kerala.build_traffic(true)
	var t: Train=w.trains.B012 # full-route northbound service terminates at ERS
	w.trains.clear()
	t.lifecycle="active";t.timetable.index=t.timetable.stops.size()-1;t.timetable.at_stop=false
	var home:={}
	for sig in w.signals.values():
		if sig.dir==-1 and w.route_options(sig.id).any(func(o):return o.edges[-1].edge=="ERS_P3"):
			home=sig;break
	if home.is_empty():return "Missing terminal approach"
	w.place_train(t,home.edge,home.s+150,-1)
	var parked:=Train.new("PARKED",180);w.place_train(parked,"ERS_P3",250,-1);parked.service_complete=true
	var station: Dictionary=w.stations[0]
	var free: Array=station.platform_tracks.filter(func(r):return r!="ERS_P3")
	var roads: Array=preload("res://sim/receiving_berths.gd").roads(w,t,station,home.edge,-1,free)
	if roads.is_empty():return "Fixed destination blocked spare platforms"
	var candidates: Array=preload("res://sim/dispatch_planner.gd").new().candidates(w,t,home.id)
	return candidates.any(func(o):return o.available and not o.stop.is_empty() and o.stop.block!="ERS_P3")

func _short_approach() -> RailWorld:
	# Preserve the old TVC short-block defect independently of changing map IDs.
	var w:=RailWorld.new()
	for item in [["A",-500,0],["B",0,0],["P",400,0],["C",800,0],["D",800,15]]:
		w.graph.add_node(item[0],Vector3(item[1],0,item[2]))
	w.graph.add_edge("PREVIOUS","A","B",[],25,1)
	w.graph.add_edge("APPROACH","B","P",[],25,1)
	w.graph.add_edge("MAIN","P","C",[],25,1)
	w.graph.add_edge("LOOP","P","D",[],25,1)
	w.graph.add_switch("P","APPROACH","MAIN","LOOP",195)
	w.add_signal("HOME","APPROACH",1,15)
	w.add_signal("MAIN_EXIT","MAIN",1,300)
	w.add_signal("LOOP_EXIT","LOOP",1,300)
	return w

func test_long_rake_on_short_tvc_approach_does_not_block_its_own_point():
	var w:=_short_approach()
	var sig: Dictionary=w.signals.HOME
	var t:=Train.new("LONG",610)
	w.place_train(t,sig.edge,sig.s-12,1)
	# place_train cannot trace backwards through a one-way running block;
	# supply the tail path that normal forward travel creates here.
	t.path.append({edge="PREVIOUS",dir=1})
	if t.path.size()<2:return "Fixture must span multiple approach blocks"
	var option: Dictionary=w.route_options(sig.id)[0]
	if not w._train_near_switch(t,option.edges[0].switch):return "Fixture must occupy the approach clearance zone"
	var blockers: Array=preload("res://sim/dispatch_resources.gd").blockers(w,sig.id,option)
	if not blockers.is_empty():return blockers
	return w.set_route(sig.id,option.destination).ok

func test_tail_on_point_branch_still_blocks_route_alignment():
	var w:=_short_approach()
	var sig: Dictionary=w.signals.HOME
	var option: Dictionary=w.route_options(sig.id)[0]
	var point: String=option.edges[0].switch
	var branch: String=w.graph.switches[point].reverse
	var t:=Train.new("FOULING",100)
	var dir: int=1 if w.graph.edges[branch].a==point else -1
	w.place_train(t,branch,w.graph.entry_s(branch,dir)+dir*120,dir)
	return w.route_reason(sig.id,option.destination).contains("Point clearance") and not w.set_route(sig.id,option.destination).ok
