extends RefCounted
const Priority := preload("res://sim/priority_dispatch.gd")
const Kerala := preload("res://sim/layouts/kerala_coast.gd")

func line() -> RailWorld:
	var w:=RailWorld.new()
	for i in 6:w.graph.add_node(str(i),Vector3(i*1000,0,0))
	for i in 5:
		var id:="E"+str(i)
		w.graph.add_edge(id,str(i),str(i+1))
		w.graph.edges[id].chainage_start=i*1000.0
		w.graph.edges[id].chainage_end=(i+1)*1000.0
		w.add_signal("S"+str(i),id,1,100)
		w.add_signal("N"+str(i),id,-1,100)
		if i in [1,2,3]:
			w.single_line_sections[id]="single"
			w.automatic_signals.append("S"+str(i))
			w.automatic_signals.append("N"+str(i))
	return w

func test_single_line_allows_following_but_blocks_opposing_entry():
	var w:=line()
	w.place_train(Train.new("LEAD",100),"E2",500,1)
	w.place_train(Train.new("FOLLOW",100),"E0",800,1)
	w.place_train(Train.new("OPPOSING",100),"E4",200,-1)
	if not w.route_reason("N4","N3").contains("opposing traffic"):return "Opposing train could enter a different block of the same single line"
	return w.set_route("S0","S1").ok

func test_idle_automatic_routes_do_not_keep_single_line_locked():
	var w:=line()
	var t:=Train.new("LEAD",100)
	w.place_train(t,"E2",500,1)
	w._update_automatic_blocks()
	if w.signals.S2.route.is_empty():return "Expected following automatic authority"
	w.place_train(t,"E4",500,1)
	w.time=1
	w._update_automatic_blocks()
	return w.single_line_directions().is_empty() and w.route_reason("N4","N3").is_empty()

func test_red_single_line_advice_names_opposing_train_without_creating_a_hold():
	var w:=line()
	w.scenery={geographic=true}
	var lead:=Train.new("LEAD",100);lead.service_name="Coast express"
	w.place_train(lead,"E2",500,1)
	var waiting:=Train.new("WAIT",100)
	w.place_train(waiting,"E4",200,-1)
	Priority.refresh_notices(w)
	return Priority.hold_reason(w,waiting,true).contains("Coast express (LEAD) crosses") and Priority.hold_reason(w,waiting).is_empty() and w.dispatch_holds.is_empty()

func test_section_name_containing_station_prefix_is_not_a_platform():
	var w:=line()
	w.stations=[{code="ALLP"},{code="PUPR"}]
	return Priority.station(w,"ALLP_PUPR_M0").is_empty() and Priority.station(w,"PUPR_P1").code=="PUPR"

func test_priority_and_actual_progress_determine_overtake_request():
	var w:=line()
	var slow:=Train.new("LOCAL",100)
	var express:=Train.new("EXPRESS",100)
	w.place_train(slow,"E2",800,1)
	w.place_train(express,"E2",200,1)
	slow.max_speed=15;slow.dispatch_priority=20
	express.max_speed=30;express.dispatch_priority=90
	var st:={code="LOOP",s=3100.0,through_halt=false}
	var decision:=Priority.conflict(w,slow,st)
	if decision.get("other","")!="EXPRESS" or decision.kind!="overtake":return "No priority overtake"
	express.dispatch_priority=10
	if not Priority.conflict(w,slow,st).is_empty():return "Lower priority forced an overtake"
	express.dispatch_priority=90
	w.place_train(express,"E3",500,1)
	return Priority.conflict(w,slow,st).is_empty() # player delayed behind the express

func test_first_arrival_takes_crossing_loop_and_expectation_expires():
	var w:=line()
	var first:=Train.new("FIRST",100)
	var second:=Train.new("SECOND",100)
	first.service_name="Stopping passenger";second.service_name="Cape express"
	w.place_train(first,"E2",900,1)
	w.place_train(second,"E3",800,-1)
	var st:={code="LOOP",s=3000.0,through_halt=false}
	w.stations=[st];w.scenery={geographic=true,route={sections=[{tracks=1}]}}
	var decision:=Priority.conflict(w,first,st)
	if decision.get("kind","")!="crossing":return "First arrival did not yield"
	if not Priority.conflict(w,second,st).is_empty():return "Both arrivals were told to loop"
	w.dispatch_holds[first.id]=decision
	if not Priority.hold_reason(w,first,true).contains("Cape express (SECOND) crosses"):return "Missing named live expectation"
	w.place_train(second,"E1",500,-1)
	Priority.update(w)
	return Priority.hold_reason(w,first,true).is_empty() and w.dispatch_history.size()==1

func test_free_opposite_line_loop_cannot_be_used_for_a_same_direction_overtake():
	var w:=Kerala.build()
	var st: Dictionary=w.stations.filter(func(s):return s.code=="OCR")[0]
	var train:=Train.new("EXPRESS",100)
	w.place_train(train,"KYJ_OCR_D4",500,1)
	return not Priority._passing_road_available(w,train,st,"OCR_P1")

func test_first_arrival_uses_loop_when_opposing_train_is_on_a_long_single_section():
	var w:=Kerala.build()
	var st: Dictionary=w.stations.filter(func(s):return s.code=="NYY")[0]
	var first:=Train.new("FIRST",188)
	var later:=Train.new("LATER",176)
	first.max_speed=140.0/3.6;later.max_speed=65.0/3.6
	w.place_train(first,"NYY_AMVA_M0",300,-1)
	w.place_train(later,"NEM_P1",600,1)
	var decision:=Priority.conflict(w,first,st)
	if decision.get("kind","")!="crossing":return "Long opposing approach was ignored"
	var stop:={block="NYY_P1",direction=-1,s=400.0}
	# Treat this as a through working, avoiding timetable mutation in this fixture.
	stop.block="BRAM_P1"
	var ns:=w.next_signal(first)
	var chosen:=Priority.choose_platform(w,first,w.route_options(ns.id),stop)
	if chosen.is_empty() or chosen.option.edges[-1].edge!="NYY_P2" or chosen.hold.other!="LATER":return "First arrival did not use the loop"
	w.dispatch_holds[first.id]=chosen.hold
	var nem: Dictionary=w.stations.filter(func(s):return s.code=="NEM")[0]
	return Priority.conflict(w,later,nem).is_empty() # must proceed to the agreed meet at NYY
