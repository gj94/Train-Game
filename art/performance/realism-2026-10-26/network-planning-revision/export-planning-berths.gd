extends SceneTree
## Static unoccupied receiving compatibility only; never live route admission.
const Pack=preload("res://sim/service_pack.gd")
const Berths=preload("res://sim/receiving_berths.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/timetables/kerala-coast-network.json"))
	var decoded: Dictionary=Pack.build(data)
	if not decoded.ok:printerr(decoded.reason);quit(1);return
	var w: RailWorld=decoded.world
	var platform_edges:={}
	for station: Dictionary in w.stations:
		for road: String in station.platform_tracks:platform_edges[road]=true
	var grouped:={}
	for s in data.services:
		var key:=JSON.stringify([s.stock,s.rake,s.stops])
		if not grouped.has(key):grouped[key]=[]
		grouped[key].append(s)
	var result:={kind="Static empty-yard receiving-road compatibility; not live admission or traffic acceptance",profiles=[],sources=preload("res://persistence/prepared_sources.gd").collect()}
	for rows: Array in grouped.values():
		var s: Dictionary=rows[0]
		var t: Train=w.trains[s.id]
		var direction: int=s.stops[0].direction
		var tt=t.timetable
		var first_s:=_call_s(w,tt.stops[0]);var last_s:=_call_s(w,tt.stops[-1])
		var stations:=[]
		for st: Dictionary in w.stations:
			if st.through_halt or st.s<minf(first_s,last_s)-st.yard_half or st.s>maxf(first_s,last_s)+st.yard_half:continue
			# Origins have depot-supply semantics; record only intermediate yards.
			if str(tt.stops[0].block).get_slice("_P",0)==st.code:continue
			var call_index:=0
			while call_index<tt.stops.size()-1 and (_call_s(w,tt.stops[call_index])-st.s)*direction < -st.yard_half:call_index+=1
			tt.index=call_index;tt.at_stop=false
			var stopping: bool=str(tt.stops[call_index].block).get_slice("_P",0)==st.code
			var inbound:="";var nearest:=INF
			var boundary: float=st.s-direction*(st.yard_half+200.0)
			for edge: String in w.graph.edges:
				var e: Dictionary=w.graph.edges[edge]
				if w.depots.has(edge) or edge.contains("DEPOT") or platform_edges.has(edge) or not w.graph.allows(edge,direction):continue
				var midpoint: float=(e.get("chainage_start",0.0)+e.get("chainage_end",0.0))*.5
				var distance: float=(boundary-midpoint)*direction
				if distance<0 or distance>5000:continue
				if distance<nearest:nearest=distance;inbound=edge
			if inbound.is_empty():printerr("No inbound edge ",s.id," ",st.code);quit(1);return
			var roads: Array=Berths.roads(w,t,st,inbound,direction,st.platform_tracks)
			if roads.is_empty():printerr("No compatible road ",s.id," ",st.code," from ",inbound," next ",tt.stops[call_index].block);quit(1);return
			stations.append({code=st.code,inbound=inbound,direction=direction,stopping=stopping,next_call=tt.stops[call_index].block,roads=roads})
		result.profiles.append({ids=rows.map(func(row):return row.id),length=t.length,stock=s.stock,direction=direction,stations=stations})
		print("BERTH PROFILE ",s.id," yards=",stations.size())
	FileAccess.open("res://.local/realism-2026-10-26/planning-berths.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("BERTH PROFILES ",result.profiles.size());quit()
func _call_s(w: RailWorld,call: Dictionary) -> float:
	var edge: Dictionary=w.graph.edges[call.block]
	return lerpf(edge.get("chainage_start",0.0),edge.get("chainage_end",0.0),call.s/edge.length)
