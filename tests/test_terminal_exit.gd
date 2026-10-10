extends RefCounted
const Kerala := preload("res://sim/layouts/kerala_coast.gd")
const Planner := preload("res://sim/dispatch_planner.gd")
const Receiving := preload("res://sim/receiving_berths.gd")
const Depot := preload("res://sim/depot_workings.gd")

func fixture() -> Dictionary:
	var w:=Kerala.build()
	var t:=Train.new("TERMINATING",180)
	t.timetable=preload("res://sim/timetable.gd").new()
	t.timetable.departure=w.clock_seconds()
	t.timetable.stops=[{block="NEM_P2",name="Previous",direction=-1,s=250.0,minutes_from_origin=0.0,dwell_minutes=0.0},{block="TVC_P4",name="TVC",direction=-1,s=250.0,minutes_from_origin=1.0,dwell_minutes=0.0}]
	t.timetable.index=1;t.timetable.at_stop=false
	t.timetable.actual_arrivals.assign([-1.0,-1.0]);t.timetable.actual_departures.assign([w.clock_seconds(),-1.0])
	t.automatic=true
	var home:={}
	for sig in w.signals.values():
		if sig.dir==-1 and w.route_options(sig.id).any(func(o):return o.edges[-1].edge=="TVC_P4"):
			home=sig;break
	assert(not home.is_empty())
	w.place_train(t,home.edge,home.s+150,-1)
	var st: Dictionary=w.stations.filter(func(s):return s.code=="TVC")[0]
	return {world=w,train=t,home=home,station=st}

func test_terminal_candidates_preserve_the_outbound_running_line():
	var f:=fixture();var w: RailWorld=f.world
	var options: Array=Planner.new().candidates(w,f.train,f.home.id)
	if not options.any(func(o):return o.available and o.stop.get("block","")=="TVC_P4"):return "Lost the booked northbound terminal face"
	return not options.any(func(o):return o.available and f.station.platform_details[o.option.edges[-1].edge].lane=="D")

func test_receiving_capacity_does_not_count_an_opposite_line_terminal_face():
	var f:=fixture()
	var wrong: Array=Receiving.roads(f.world,f.train,f.station,f.home.edge,-1,["TVC_P1"])
	var right: Array=Receiving.roads(f.world,f.train,f.station,f.home.edge,-1,["TVC_P2","TVC_P4"])
	return wrong.is_empty() and right.size()==2

func test_occupied_booked_terminal_can_still_use_compatible_alternative():
	var f:=fixture();var w: RailWorld=f.world
	var parked:=Train.new("PARKED",180);w.place_train(parked,"TVC_P4",300,-1)
	var options: Array=Planner.new().candidates(w,f.train,f.home.id)
	return options.any(func(o):return o.available and o.stop.get("block","")=="TVC_P2") and not options.any(func(o):return o.available and o.stop.get("block","")=="TVC_P1")

func test_northbound_terminal_and_southbound_arrival_both_clear_to_depot():
	var f:=fixture();var w: RailWorld=f.world
	var south:=Train.new("SOUTH",180)
	south.timetable=preload("res://sim/timetable.gd").new()
	south.timetable.departure=w.clock_seconds()
	south.timetable.stops=[{block="TVP_P1",name="Previous",direction=1,s=500.0,minutes_from_origin=0.0,dwell_minutes=0.0},{block="TVC_P3",name="TVC",direction=1,s=800.0,minutes_from_origin=1.0,dwell_minutes=0.0}]
	south.timetable.index=1;south.timetable.at_stop=false
	south.timetable.actual_arrivals.assign([-1.0,-1.0]);south.timetable.actual_departures.assign([w.clock_seconds(),-1.0])
	south.automatic=true
	var sig: Dictionary=w.signals["TVP_TVC_D1-H"]
	w.place_train(south,sig.edge,sig.s-150,1)
	w.dispatcher().enabled=true
	for i in 600:
		w.step(2.0)
		if not w.events.is_empty():return str(w.events)
		if Depot.finished(w,f.train) and Depot.finished(w,south):return true
	return "Terminal/depot conflict: "+f.train.status+" / "+south.status
