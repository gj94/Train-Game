extends RefCounted
const Berth:=preload("res://sim/berth_clearance.gd")
const Kerala:=preload("res://sim/layouts/kerala_coast.gd")
const Stock:=preload("res://sim/stock/ported_stock.gd")
const Pack:=preload("res://sim/service_pack.gd")

func test_every_kerala_platform_and_siding_holds_full_express_clear_of_both_throats():
	var w:=Kerala.build()
	var t:=Train.new("long",1);Stock.configure(t,"lhb")
	for st in w.stations:
		for road in st.platform_tracks:
			var passenger: bool=st.passenger_open and st.platform_details[road].platform_width>0
			if Berth.capacity(w,road,passenger)<t.length+10:return "short road "+road
			for direction in [-1,1]:
				var head:=Berth.marker(w,t,road,direction,passenger)
				if not Berth.fits(w,t,road,head,direction,passenger):return "unsafe marker "+road
				w.place_train(t,road,head,direction)
				if t.path.size()!=1:return "tail behind entrance "+road
				var e: Dictionary=w.graph.edges[road]
				for node in [e.a,e.b]:
					if w.graph.switches.has(node) and w._train_near_switch(t,node):return "parked train fouls points "+road
				for sig in w.signals.values():
					if sig.edge!=road or sig.dir!=direction:continue
					w.place_train(t,road,sig.s-direction*6,direction)
					for node in [e.a,e.b]:
						if w.graph.switches.has(node) and w._train_near_switch(t,node):return "starter lets waiting train foul throat "+road
	for e in w.graph.edges.values():
		if e.get("chainage_end",1)<=e.get("chainage_start",0):return "extended yards overlap: "+e.id
	return true

func test_short_road_and_unusable_stop_marker_rejected_even_if_edge_is_long():
	var w:=RailWorld.new()
	w.graph.add_node("a",Vector3.ZERO);w.graph.add_node("b",Vector3(1000,0,0));w.graph.add_edge("loop","a","b")
	# 1 km edge but only 488 m between the protecting signals.
	w.add_signal("N","loop",-1,250);w.add_signal("S","loop",1,250)
	var t:=Train.new("long",1);Stock.configure(t,"lhb")
	if Berth.capacity(w,"loop")!=488:return "signal limits ignored"
	if Berth.fits(w,t,"loop",Berth.marker(w,t,"loop",1),1):return "overlength rake admitted"
	w.signals.N.s=100;w.signals.S.s=900
	if not Berth.fits(w,t,"loop",Berth.marker(w,t,"loop",-1),-1):return "valid northbound berth rejected"
	return not Berth.fits(w,t,"loop",550,1) and not Berth.fits(w,t,"loop",450,-1)

func test_all_default_calls_and_manual_arrival_tolerance_keep_rear_clear():
	var w:=Kerala.build_traffic()
	for t in w.trains.values():
		for stop in t.timetable.stops:
			if not Berth.fits(w,t,stop.block,stop.s,stop.direction):return "unsafe scheduled call "+t.id+"/"+stop.block
	var t: Train=w.trains.K1
	t.automatic=false
	var stop: Dictionary=t.timetable.stops[0]
	var tolerance:=w._arrival_tolerance(t)
	return Berth.fits(w,t,stop.block,stop.s+tolerance,stop.direction) and Berth.fits(w,t,stop.block,stop.s-tolerance,stop.direction)

func test_import_and_operator_platform_assignment_reject_short_clearance():
	var data:=Pack.defaults("kerala_coast")
	data.services[0].stops[0].position_m=500
	if Pack.build(data).ok:return "import accepted tail inside entrance points/platform end"
	var w:=Kerala.build_traffic()
	w.trains.K1.timetable.index=preload("res://tests/kerala_fixture.gd").kumbalam_call(w);w.trains.K1.timetable.at_stop=false
	var road: String=w.trains.K1.timetable.stop_ahead().block
	# A future layout can place a protecting signal farther inside a long road.
	for sig in w.signals.values():
		if sig.edge==road and sig.dir==1:sig.s=450
	return not w.dispatcher().assign_platform("K1",road).ok
