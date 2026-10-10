extends RefCounted
const Kerala := preload("res://sim/layouts/kerala_coast.gd")
const Planner := preload("res://sim/dispatch_planner.gd")
const Berth := preload("res://sim/berth_clearance.gd")

func add(w, id: String, roads: Array, direction: int) -> Train:
	var t:=Train.new(id,180)
	preload("res://sim/stock/ported_stock.gd").configure(t,"icf","passenger")
	w.place_train(t,roads[0],Berth.marker(w,t,roads[0],direction),direction)
	var stops:=[]
	for road in roads:
		stops.append({name=road,block=road,direction=direction,position_m=Berth.marker(w,t,road,direction),minutes_from_origin=stops.size(),dwell_minutes=0})
	assert(w.set_timetable(id,{departure="08:00",stops=stops}).ok)
	t.automatic=true
	return t

func fixture() -> RailWorld:
	var w:=Kerala.build()
	w.dispatcher().future_clearances.enabled=false
	return w

func rejection(w,t: Train,station: String) -> Dictionary:
	var options: Array=w.route_options(w.next_signal(t).id)
	assert(not options.is_empty())
	for option in options:
		if w.depots.has(option.edges[-1].edge):continue
		var result: Dictionary=Planner.new().admission_reason(w,t,option)
		if result.is_empty():return {}
		if not str(result.reason).contains(station):return {unexpected=result}
	return {blocked=true}

func test_last_turavur_face_cannot_trap_opposing_kumbalam_passenger():
	var w:=fixture()
	add(w,"S",["KUMM_P3","TUVR_P2","SRTL_P1"],1)
	add(w,"N1",["TUVR_P3","KUMM_P3","ERS_P4"],-1)
	var t:=add(w,"N2",["SRTL_P2","TUVR_P2","KUMM_P3","ERS_P6"],-1)
	return rejection(w,t,"Kumbalam").get("blocked",false)

func test_kumbalam_admission_preserves_escape_for_two_turavur_locals():
	var w:=fixture()
	add(w,"N1",["TUVR_P3","KUMM_P3","ERS_P4"],-1)
	add(w,"N2",["TUVR_P2","KUMM_P3","ERS_P6"],-1)
	var t:=add(w,"S",["ERS_P1","KUMM_P3","TUVR_P2","SRTL_P1"],1)
	return rejection(w,t,"Turavur").get("blocked",false)

func test_nonstopping_opponent_can_escape_via_nonplatform_main():
	var w:=fixture()
	add(w,"N1",["TUVR_P3","ERS_P4"],-1)
	add(w,"N2",["TUVR_P2","KUMM_P3","ERS_P6"],-1)
	var t:=add(w,"S",["ERS_P1","KUMM_P3","TUVR_P2","SRTL_P1"],1)
	return rejection(w,t,"").is_empty()

func test_spare_compatible_kumbalam_face_allows_crossing():
	var w:=fixture()
	for st in w.stations:
		if st.code=="KUMM":st.platform_details.KUMM_P2.platform_width=3.43
	add(w,"N1",["TUVR_P3","KUMM_P3","ERS_P4"],-1)
	add(w,"N2",["TUVR_P2","KUMM_P3","ERS_P6"],-1)
	var t:=add(w,"S",["ERS_P1","KUMM_P3","TUVR_P2","SRTL_P1"],1)
	return rejection(w,t,"").is_empty()

func test_home_platform_selection_cannot_consume_the_escape_face():
	var w:=fixture()
	add(w,"N1",["TUVR_P3","KUMM_P3","ERS_P4"],-1)
	add(w,"N2",["TUVR_P2","KUMM_P3","ERS_P6"],-1)
	var t:=add(w,"S",["ERS_P1","KUMM_P3","TUVR_P2","SRTL_P1"],1)
	var approach: String=preload("res://tests/kerala_fixture.gd").kumbalam_approach(w)
	w.place_train(t,approach,w.graph.edges[approach].length-100,1)
	t.timetable.index=1;t.timetable.at_stop=false
	var choices: Array=Planner.new().candidates(w,t,w.next_signal(t).id)
	return choices.any(func(o):return o.option.edges[-1].edge=="KUMM_P3" and o.reason.contains("preserve a crossing")) and not choices.any(func(o):return o.available)

func test_committed_kumbalam_arrival_protects_last_turavur_face():
	var w:=fixture()
	var south:=add(w,"S",["ERS_P1","KUMM_P3","TUVR_P2","SRTL_P1"],1)
	var approach: String=preload("res://tests/kerala_fixture.gd").kumbalam_approach(w)
	w.place_train(south,approach,w.graph.edges[approach].length-100,1)
	south.timetable.index=1;south.timetable.at_stop=false
	var home: String=w.next_signal(south).id
	var options: Array=w.route_options(home)
	var option: Dictionary=options.filter(func(o):return o.edges[-1].edge=="KUMM_P3")[0]
	assert(w.set_route(home,option.destination).ok)
	add(w,"N1",["TUVR_P3","KUMM_P3","ERS_P4"],-1)
	var t:=add(w,"N2",["SRTL_P2","TUVR_P2","KUMM_P3","ERS_P6"],-1)
	return rejection(w,t,"Kumbalam").get("blocked",false)

func test_three_full_rakes_complete_the_crossing_without_a_cycle():
	var w:=fixture()
	var south:=add(w,"S",["KUMM_P3","TUVR_P2","SRTL_P1"],1)
	var north1:=add(w,"N1",["TUVR_P3","KUMM_P3","ERS_P4"],-1)
	var north2:=add(w,"N2",["SRTL_P2","TUVR_P2","KUMM_P3","ERS_P6"],-1)
	w.dispatcher().enabled=true
	for i in 2700:
		w.step(2.0)
		if not w.events.is_empty():return str(w.events)
		if [south,north1,north2].all(func(t):return t.service_complete):return true
	return "Crossing did not drain: "+south.status+" / "+north1.status+" / "+north2.status

func test_approaching_local_counts_before_its_home_route_is_reserved():
	var w:=fixture()
	add(w,"N1",["TUVR_P3","KUMM_P3","ERS_P4"],-1)
	var north:=add(w,"N2",["SRTL_P2","TUVR_P2","KUMM_P3","ERS_P6"],-1)
	var home:={}
	for sig in w.signals.values():
		if sig.dir==-1 and w.route_options(sig.id).any(func(o):return o.edges[-1].edge=="TUVR_P2"):
			home=sig;break
	assert(not home.is_empty())
	w.place_train(north,home.edge,home.s+100,-1)
	north.timetable.index=1;north.timetable.at_stop=false
	var south:=add(w,"S",["ERS_P1","KUMM_P3","TUVR_P2","SRTL_P1"],1)
	return rejection(w,south,"Turavur").get("blocked",false)
