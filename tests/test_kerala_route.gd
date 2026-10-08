extends RefCounted
const Kerala := preload("res://sim/layouts/kerala_coast.gd")

func test_dispatcher_reserves_a_route_containing_an_unsignalled_halt():
	var world:=RailWorld.new()
	for i in 4: world.graph.add_node(str(i),Vector3(i*1000,0,0))
	for i in 3: world.graph.add_edge("E"+str(i),str(i),str(i+1))
	world.add_signal("START","E0",1,100)
	world.add_signal("EXIT","E2",1,100)
	var train:=Train.new("LOCAL",100)
	world.place_train(train,"E0",780,1)
	world.set_timetable("LOCAL",{departure="08:00",stops=[
		{block="E0",direction=1,minutes_from_origin=0,position_m=780},
		{block="E1",direction=1,minutes_from_origin=3,position_m=700}]})
	train.automatic=true
	preload("res://sim/dispatch_plan.gd").update(world)
	return world.signals.START.cleared and world.signals.START.destination=="EXIT"

func test_halt_departure_uses_existing_section_authority_with_next_signal_red():
	var world:=RailWorld.new()
	for i in 4: world.graph.add_node(str(i),Vector3(i*1000,0,0))
	for i in 3: world.graph.add_edge("E"+str(i),str(i),str(i+1))
	world.add_signal("START","E0",1,100)
	world.add_signal("EXIT","E2",1,100)
	var train:=Train.new("LOCAL",100)
	world.place_train(train,"E0",780,1)
	world.set_timetable("LOCAL",{departure="08:00",stops=[
		{block="E0",direction=1,minutes_from_origin=0,position_m=780},
		{block="E1",direction=1,minutes_from_origin=3,position_m=700,dwell_minutes=0},
		{block="E2",direction=1,minutes_from_origin=6,position_m=750}]})
	world.set_route("START","EXIT")
	world.signals.START.owner="LOCAL"
	world.place_train(train,"E1",700,1)
	train.timetable.index=1
	train.timetable.at_stop=true
	train.timetable.actual_arrivals[1]=world.clock_start+180
	world.time=181
	train.automatic=true
	world._drive_automatic(train)
	return train.controller>0 and world.aspect("EXIT")==RailWorld.Aspect.RED

func test_coastal_route_is_full_scale_and_follows_the_requested_junctions():
	var source := Kerala.source()
	if source.stations.size()!=56: return "Lost a mapped station"
	var codes := []
	for station in source.stations: codes.append(station.code)
	if codes[0]!="ERS" or codes[-1]!="NCJ": return "Wrong route endpoints"
	if not (codes.find("ALLP")<codes.find("QLN") and codes.find("QLN")<codes.find("TVC")): return "Wrong coastal route order"
	if "KTYM" in codes: return "Inland route substituted"
	var length: float = source.stations[-1].s-source.stations[0].s
	return length>275000 and length<280000 and source.elevation_tiles.size()>400

func test_geographic_operational_graph_and_booked_services_are_reachable():
	var world := Kerala.build_traffic()
	if world.trains.size()!=32: return "Expected 32 mixed services"
	for node in world.graph.nodes:
		var count: int = world.graph.nodes[node].edges.size()
		if count>3 or (count==3 and not world.graph.switches.has(node)): return "Uncontrolled junction: "+node
	for train in world.trains.values():
		if train.path.size()!=1: return "Train does not fit its origin platform"
		for i in range(1,train.timetable.stops.size()):
			var previous: Dictionary = train.timetable.stops[i-1]
			var stop: Dictionary = train.timetable.stops[i]
			if is_inf(world._stop_distance(previous.block,previous.direction,previous.s,stop,[])):
				return train.id+": unreachable "+stop.name
	return true

func test_automatic_sections_stop_at_controlled_station_homes():
	var world:=Kerala.build()
	for id in world.automatic_signals:
		var options:=world.route_options(id)
		if options.size()!=1: return "Ambiguous automatic block: "+id
		if options[0].edges.any(func(r): return r.switch!=""):
			return "Automatic signal would operate a station point: "+id
	return true

func test_large_stopping_scenario_has_separate_origins_and_terminal_roads():
	var world:=Kerala.build_traffic()
	var origins:={}
	var termini:={}
	var stocks:={}
	var north:=0
	var south:=0
	for t in world.trains.values():
		var first: Dictionary=t.timetable.stops[0]
		var last: Dictionary=t.timetable.stops[-1]
		if origins.has(first.block): return "Overlapping origin: "+first.block
		if termini.has(last.block): return "Completed services share a terminal: "+last.block
		for block in [first.block,last.block]:
			var st: Dictionary=preload("res://sim/priority_dispatch.gd").station(world,block)
			if st.platform_details[block].platform_width<=0: return "Passenger origin/terminus lacks a platform: "+block
		origins[first.block]=true
		termini[last.block]=true
		stocks[t.stock_kind]=true
		if first.direction>0: south+=1
		else: north+=1
	return stocks.size()==4 and north>=12 and south>=12 and world.trains.K1.timetable.stops.size()==55 and world.trains.K1.dispatch_priority==20

func test_kerala_services_export_and_import_preserve_placement():
	var pack=preload("res://sim/service_pack.gd")
	var data: Dictionary=pack.defaults("kerala_coast")
	var result: Dictionary=pack.decode(JSON.stringify(data),"kerala_coast")
	if not result.ok: return result.reason
	if result.world.trains.size()!=32: return "Service import lost trains"
	for t in result.world.trains.values():
		if t.path.size()!=1 or absf(t.head_s-t.timetable.stops[0].s)>.01: return "Placement changed"
	return true

func test_mapped_halts_do_not_invent_passing_loops():
	var world:=Kerala.build()
	for st in world.stations:
		if not st.through_halt: continue
		if world.signals.has(st.code+"-S1"): return "Fictitious halt starter: "+st.code
		for node in world.graph.nodes:
			if node.begins_with(st.code+"_") and world.graph.nodes[node].edges.size()>2:
				return "Invented halt passing loop: "+node
	return true
