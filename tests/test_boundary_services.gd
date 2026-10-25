extends RefCounted
const Kerala := preload("res://sim/layouts/kerala_coast.gd")
const Pack := preload("res://sim/service_pack.gd")
const Boundary := preload("res://sim/boundary_services.gd")
const Snapshot := preload("res://sim/world_snapshot.gd")
const Life := preload("res://sim/service_lifecycle.gd")
const Berth := preload("res://sim/berth_clearance.gd")

func definition(w, north: bool, entering: bool) -> Dictionary:
	var direction:=1 if north==entering else -1
	var code:="ERS" if north else "NCJ"
	var road:=code+"_PORTAL_"+("D" if direction>0 else "U")
	var station:=code+"_P"+("1" if direction>0 else "2")
	if code=="NCJ" and direction<0:station="NCJ_P4"
	var portal:={block=road,name="Boundary",boundary="entry" if entering else "exit",direction=direction,dwell_minutes=0.0,minutes_from_origin=0.0 if entering else 10.0}
	var call:={block=station,name=code,direction=direction,dwell_minutes=0.0,minutes_from_origin=10.0 if entering else 0.0}
	return {format="train-game-services",version=1,layout="kerala_coast",boundary_network=true,layout_signature=Pack.signature(w),name="Boundary test",world_start="23:55",day=1,services=[{id="THROUGH",name="Long distance working",stock="lhb",rake="express",scheduled_entry=true,departure="23:55",day=1,journey={origin="Mangaluru" if north else "Madurai",destination="Thiruvananthapuram",category="mail"},stops=[portal,call] if entering else [call,portal]}]}

func test_legacy_layout_is_unchanged_and_extended_lanes_are_directional():
	var original:=Kerala.build();var extended:=Kerala.build(true)
	if Pack.signature(original)==Pack.signature(extended):return "Boundary geometry must have a distinct signature"
	if Boundary.portals(original).size()!=0 or Boundary.portals(extended).size()!=4:return false
	for road in Boundary.portals(extended):
		var p: Dictionary=Boundary.portals(extended)[road]
		if not extended.graph.allows(road,p.direction) or extended.graph.allows(road,-p.direction):return "Wrong directional portal "+road
	for station in original.stations:
		var other: Dictionary=extended.stations.filter(func(s):return s.code==station.code)[0]
		if station.platform_tracks!=other.platform_tracks or station.platform_details!=other.platform_details:return "Changed station roads"
	return true

func test_pack_rejects_forged_wrong_way_or_intermediate_boundary_points():
	var w:=Kerala.build(true);var data:=definition(w,true,true)
	if not Pack.build(data).ok:return "Valid boundary pack rejected"
	for change in ["missing","kind","dwell","layout","direction"]:
		var bad: Dictionary=data.duplicate(true)
		match change:
			"missing":bad.services[0].stops[0].erase("boundary")
			"kind":bad.services[0].stops[1].boundary="entry"
			"dwell":bad.services[0].stops[0].dwell_minutes=1.0
			"layout":bad.boundary_network=false
			"direction":bad.services[0].stops[0].direction=-1
		if Pack.build(bad).ok:return "Accepted invalid "+change
	return true

func test_entry_cannot_spawn_into_occupied_or_reserved_portal():
	var w:=Kerala.build(true);var built:=Pack.build(definition(w,true,true))
	if not built.ok:return built.reason
	w=built.world;var t: Train=w.trains.THROUGH;t.lifecycle="scheduled"
	var blocker:=Train.new("BLOCKER",120);w.place_train(blocker,t.path[0].edge,t.head_s,1)
	if Life.can_enter(w,t):return "Occupied entry accepted"
	blocker.lifecycle="stored"
	var sig: Dictionary=w.signals[t.path[0].edge+"-E"]
	sig.route=[{edge=t.path[0].edge,dir=1}]
	if Life.can_enter(w,t):return "Reserved entry accepted"
	sig.route=[]
	return Life.can_enter(w,t)

func test_real_both_boundary_entries_run_through_signals_and_acknowledge_station():
	for north in [true,false]:
		var w:=Kerala.build(true);var built:=Pack.build(definition(w,north,true))
		if not built.ok:return built.reason
		w=built.world;var t: Train=w.trains.THROUGH
		w.dispatcher().enabled=true
		for i in 550:
			w.step(2.0)
			if not w.events.is_empty():return str(w.events)
			if t.service_complete:break
		if not t.service_complete:return "Entry failed: "+t.status
		var tt=t.completed_timetable if t.completed_timetable!=null else t.timetable
		if tt.actual_departures[0]<0 or tt.actual_arrivals[1]<0:return "Missing actual timing point"
	return true

func test_real_outward_workings_clear_tail_and_retain_onward_identity():
	for north in [true,false]:
		var w:=Kerala.build(true);var built:=Pack.build(definition(w,north,false))
		if not built.ok:return built.reason
		w=built.world;var t: Train=w.trains.THROUGH
		w.dispatcher().enabled=true
		for i in 550:
			w.step(2.0)
			if not w.events.is_empty():return str(w.events)
			if t.lifecycle=="exited":break
		if t.lifecycle!="exited":return "Exit failed: "+t.status
		if not preload("res://sim/depot_workings.gd").finished(w,t) or not t.depot.is_empty() or not w.occupancy().is_empty():return "Exit falsely counted as depot or retained occupation"
		var saved:=Snapshot.restore(Snapshot.capture(w))
		if not saved.ok:return saved.reason
		if saved.world.trains.THROUGH.journey!=t.journey or saved.world.trains.THROUGH.lifecycle!="exited":return "Lost off-map identity"
	return true

func test_head_only_exit_and_forged_saved_exit_are_rejected():
	var w:=Kerala.build(true);var built:=Pack.build(definition(w,true,false))
	if not built.ok:return built.reason
	w=built.world;var t: Train=w.trains.THROUGH
	var stop: Dictionary=t.timetable.stops[-1]
	t.timetable.index=1;t.timetable.at_stop=true;t.service_complete=true
	w.place_train(t,stop.block,w.graph.entry_s(stop.block,-1)-20,-1)
	if Boundary.retire(w,t):return "Retired with tail still on approach"
	t.lifecycle="exited"
	if Snapshot.restore(Snapshot.capture(w)).ok:return "Loaded forged incomplete tail exit"
	return true
