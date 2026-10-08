extends RefCounted
const Kerala:=preload("res://sim/layouts/kerala_coast.gd")
const Faces:=preload("res://sim/platform_faces.gd")
const Berth:=preload("res://sim/berth_clearance.gd")

func test_every_csv_platform_count_matches_the_generated_world():
	var w:=Kerala.build()
	var file:=FileAccess.open("res://data/routes/kerala_coast/station-register.csv",FileAccess.READ)
	var header:=file.get_csv_line()
	var count:=0
	while not file.eof_reached():
		var row:=file.get_csv_line()
		if row.size()!=header.size():continue
		var code: String=row[header.find("station_code")]
		var id: String={"PNPR":"PUPR","TVCS":"NEM"}.get(code,code)
		var found:=w.stations.filter(func(s):return s.code==id)
		if found.size()!=1:return "Unmatched register station "+code
		var target:=int(row[header.find("iri_reported_platforms" if code=="VELI" else "reported_platform_count")])
		if Faces.entries(found[0]).size()!=target:return "Platform inventory mismatch "+code
		if found[0].name!=row[header.find("station_name")]:return "Name mismatch "+code
		count+=1
	return count==56

func test_closed_tirunettur_is_preserved_geographically_but_not_bookable():
	var w:=Kerala.build_traffic()
	var t: Train=w.trains.K1
	if w.stations.filter(func(s):return s.code=="TNU" and not s.passenger_open).size()!=1:return "Closure lost"
	if t.timetable.stops.size()!=55 or t.timetable.stops.any(func(s):return str(s.block).begins_with("TNU_")):return "Closed halt remains booked"
	return Berth.capacity(w,"TNU_P1")==0 and Berth.capacity(w,"TNU_P1",false)>t.length

func test_two_reported_platforms_do_not_invent_a_dhanuvachapuram_passing_loop():
	var w:=Kerala.build()
	var station: Dictionary=w.stations.filter(func(s):return s.code=="DAVM")[0]
	var nav=preload("res://game/platform_navigation.gd")
	return station.platform_tracks.size()==1 and Faces.entries(station).size()==2 and not nav.new(w,"DAVM_P1",-1).edge.is_empty() and not nav.new(w,"DAVM_P1",1).edge.is_empty()

func test_one_platform_crossing_can_forecast_vb_departure_without_admitting_to_occupied_road():
	var w:=Kerala.build_traffic()
	for id in w.trains.keys():
		if id not in ["K1","K2","K3"]:w.trains.erase(id)
	var e=w.dispatcher();e.manual_service="K1"
	w.trains.K1.automatic=false;w.trains.K1.controller=-.8
	e.run_cycle(true)
	if e.future_clearances.plans.size()!=1:return "No one-platform future crossing"
	var p: Dictionary=e.future_clearances.plans[0]
	if p.future_road!="KUMM_P3" or p.opponent_road==p.future_road:return "Sharing occupied berth"
	if w.aspect("ERS-S1")==RailWorld.Aspect.RED:return "Safe approach not admitted"
	var approach:=preload("res://tests/kerala_fixture.gd").kumbalam_approach(w)
	w.place_train(w.trains.K1,approach,w.graph.edges[approach].length-80,1)
	w.trains.K1.timetable.index=1;w.trains.K1.timetable.at_stop=false
	e.run_cycle(true)
	return w.aspect(w.next_signal(w.trains.K1).id)==RailWorld.Aspect.RED and not w.trains.K1.automatic and w.trains.K1.controller==-.8

func test_storage_track_does_not_become_a_third_karunagappalli_passing_loop():
	var w:=Kerala.build()
	var storage: Dictionary=w.graph.edges.KPY_P5
	if w.graph.nodes[storage.a].edges.size()!=1 or w.graph.nodes[storage.b].edges.size()!=1:return "Unverified storage connection invented"
	return not w.signals.has("KPY-S5") and not w.signals.has("KPY-N5")

func test_register_source_hash_is_pinned():
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/routes/kerala_coast/operations.json"))
	return FileAccess.get_sha256("res://data/routes/kerala_coast/station-register.csv")==data.station_register.sha256
