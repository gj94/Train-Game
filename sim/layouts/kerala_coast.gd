extends RefCounted
## Real OSM coastal alignment; operational loops/signals are a reconstruction.
## Pure data/simulation: no scene nodes, GPU resources or view state.
const ROOT := "res://data/routes/kerala_coast/"
const Stock := preload("res://sim/stock/ported_stock.gd")
const SERVICE_COUNT := 32
static var _source := {}
var data: Dictionary
var distance := PackedFloat64Array()
var operations: Dictionary

static func source() -> Dictionary:
	if _source.is_empty(): _source = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"route.json"))
	return _source

static func build() -> RailWorld:
	var builder = load("res://sim/layouts/kerala_coast.gd").new()
	return builder._build()

func point(s: float, offset: float = 0.0) -> Array:
	var index := clampi(distance.bsearch(clampf(s,0,distance[-1]))-1,0,distance.size()-2)
	var weight := clampf((s-distance[index])/(distance[index+1]-distance[index]),0,1)
	var a: Array = data.alignment[index]
	var b: Array = data.alignment[index+1]
	var dx: float = b[0]-a[0]
	var dz: float = b[2]-a[2]
	var length := sqrt(dx*dx+dz*dz)
	return [lerpf(a[0],b[0],weight)-dz/length*offset,lerpf(a[1],b[1],weight),lerpf(a[2],b[2],weight)+dx/length*offset]

func _node(w: RailWorld, id: String, s: float, offset: float) -> void:
	w.graph.add_metric_node(id,point(s,offset))
	w.graph.nodes[id].chainage = s
	w.graph.nodes[id].lateral = offset

func _edge(w: RailWorld, id: String, a: String, b: String, speed: float = 80, direction: int = 0, middle_offset: float = INF) -> void:
	var sa: float = w.graph.nodes[a].chainage
	var sb: float = w.graph.nodes[b].chainage
	var oa: float = w.graph.nodes[a].lateral
	var ob: float = w.graph.nodes[b].lateral
	var middle := []
	for s in range(ceili(sa/5)*5,floori(sb/5)*5+1,5):
		if s<=sa+.001 or s>=sb-.001: continue
		var off := lerpf(oa,ob,smoothstep(sa,sb,s))
		if not is_inf(middle_offset):
			off = lerpf(oa,middle_offset,smoothstep(sa,sa+195,s)) if s<(sa+sb)*.5 else lerpf(middle_offset,ob,smoothstep(sb-195,sb,s))
		middle.append(point(s,off))
	w.graph.add_metric_edge(id,a,b,middle,speed/3.6,direction)
	w.graph.edges[id].chainage_start = sa
	w.graph.edges[id].chainage_end = sb
	w.graph.edges[id].lateral = middle_offset if not is_inf(middle_offset) else (oa+ob)*.5

func _build() -> RailWorld:
	data = source()
	operations=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"operations.json"))
	var signs: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"station-signs.json"))
	data=data.duplicate(false)
	data.sections=operations.sections
	distance = PackedFloat64Array(data.chainage)
	var w := RailWorld.new()
	w.scenery = {geographic=true,layout_id="kerala_coast",route=data,route_root=ROOT,
		corridor=false,x_min=-2000.0,x_max=130000.0}
	for i in data.stations.size():
		var st: Dictionary = data.stations[i].duplicate(true)
		st.merge(signs.get(st.code,{}),true)
		var p := point(st.s)
		st.origin = Vector3(p[0],p[1],p[2])
		st.platforms = []
		st.platform_tracks = []
		st.track_z = []
		st.building = st.origin
		# Real station names/locations; road numbering here belongs to the game.
		st.operating_roads=operations.stations[i].roads
		st.passenger_open=operations.stations[i].get("passenger_open",true)
		st.name=operations.stations[i].get("register_name",st.name)
		st.official_km=operations.stations[i].get("register_km",null)
		st.through_halt=operations.stations[i].through
		st.roads=st.operating_roads.size()
		# Extra ladder turnouts need extra throat length, not progressively shorter
		# passenger roads. Retain a full 1 km road beyond the innermost turnouts.
		var per_lane:=maxi(st.operating_roads.filter(func(r):return r.lane=="D" and not r.get("storage",false)).size(),st.operating_roads.filter(func(r):return r.lane=="U" and not r.get("storage",false)).size())
		st.yard_half=520.0+maxi(0,per_lane-2)*22.0
		st.platform_details={}
		w.stations.append(st)
		_station(w,st,i)
	for i in data.sections.size():
		_section(w,data.sections[i],i)
	_single_line_groups(w)
	# End approaches terminate outside the station platform ends.
	for i in [0,data.stations.size()-1]:
		var st: Dictionary = w.stations[i]
		for lane in ["D","U"]:
			var station_node: String = st.code+"_"+("L" if i==0 else "R")+lane
			var buffer: String = st.code+"_BUFFER_"+lane
			_node(w,buffer,0 if i==0 else distance[-1],st.operating_roads[0 if lane=="D" else 1].offset)
			_edge(w,st.code+"_END_"+lane,buffer if i==0 else station_node,station_node if i==0 else buffer,30)
	# Register all 3-edge station forks after connecting the adjacent sections.
	for id in w.graph.nodes:
		var roads: Array = w.graph.nodes[id].edges
		if roads.size()!=3: continue
		var forward := []
		var backward := []
		for eid in roads:
			if w.graph.edges[eid].a==id: forward.append(eid)
			else: backward.append(eid)
		var trunk: String = forward[0] if forward.size()==1 else backward[0]
		var branches: Array = backward if forward.size()==1 else forward
		branches.sort_custom(func(a,b): return absf(w.graph.edges[a].lateral)<absf(w.graph.edges[b].lateral))
		w.graph.add_switch(id,trunk,branches[0],branches[1],195)
	w._update_automatic_blocks()
	return w

func _station(w: RailWorld, st: Dictionary, index: int) -> void:
	var c: String = st.code
	var s: float = st.s
	if st.through_halt:
		for p in range(1,st.roads+1):
			var lane: String="M" if st.roads==1 else ("D" if p==1 else "U")
			var offset: float=st.operating_roads[p-1].offset
			_node(w,c+"_L"+lane,s-500,offset)
			_node(w,c+"_R"+lane,s+500,offset)
			var id: String="%s_P%d" % [c,p]
			_edge(w,id,c+"_L"+lane,c+"_R"+lane,90,0 if st.roads==1 else (1 if p==1 else -1))
			st.platform_tracks.append(id)
			st.track_z.append(offset)
			st.platform_details[id]=st.operating_roads[p-1]
		return
	for end in ["L","R"]:
		var signum := -1 if end=="L" else 1
		var adjacent := index-1 if end=="L" else index
		var single: bool = adjacent>=0 and adjacent<data.sections.size() and data.sections[adjacent].tracks==1
		for lane in ["D","U"]:
			_node(w,c+"_"+end+lane,s+signum*st.yard_half,st.operating_roads[0 if lane=="D" else 1].offset)
		if single:
			_node(w,c+"_"+end+"M",s+signum*(st.yard_half+200),0)
			for lane in ["D","U"]:
				var a: String = c+"_"+end+"M" if end=="L" else c+"_"+end+lane
				var b: String = c+"_"+end+lane if end=="L" else c+"_"+end+"M"
				_edge(w,c+"_"+end+"LEAD_"+lane,a,b,60)
	for lane in ["D","U"]:
		var roads: Array=st.operating_roads.filter(func(r):return r.lane==lane and not r.get("storage",false))
		var left: String=c+"_L"+lane
		var right: String=c+"_R"+lane
		for j in roads.size():
			var road: Dictionary=roads[j]
			var id: String="%s_P%d" % [c,road.road]
			_edge(w,id,left,right,90 if road.road<=2 else 35,0,road.offset)
			st.platform_tracks.append(id)
			st.track_z.append(road.offset)
			st.platform_details[id]=road
			# Keep a train waiting at its starter inside the 195 m fouling limit.
			w.add_signal(c+"-S"+str(int(road.road)),id,1,210)
			w.add_signal(c+"-N"+str(int(road.road)),id,-1,210)
			if j<roads.size()-2:
				var next_left: String=c+"_L"+lane+str(j)
				var next_right: String=c+"_R"+lane+str(j)
				_node(w,next_left,s-st.yard_half+(j+1)*22,roads[j+1].offset)
				_node(w,next_right,s+st.yard_half-(j+1)*22,roads[j+1].offset)
				_edge(w,c+"_LADDER_L"+lane+str(j),left,next_left,25)
				_edge(w,c+"_LADDER_R"+lane+str(j),next_right,right,25)
				left=next_left;right=next_right
	for road in st.operating_roads:
		if not road.get("storage",false):continue
		var id: String="%s_P%d" % [c,road.road]
		_node(w,id+"_STORAGE_A",s-350,road.offset)
		_node(w,id+"_STORAGE_B",s+350,road.offset)
		_edge(w,id,id+"_STORAGE_A",id+"_STORAGE_B",15)
		st.platform_tracks.append(id);st.track_z.append(road.offset);st.platform_details[id]=road
	st.platform_tracks.sort_custom(func(a,b):return int(a.split("_P")[1])<int(b.split("_P")[1]))

func _section(w: RailWorld, section: Dictionary, index: int) -> void:
	var a: Dictionary = w.stations[index]
	var b: Dictionary = w.stations[index+1]
	if section.tracks==1:
		var start: String=a.code+"_RM"
		var end: String=b.code+"_LM"
		var sa: float=w.graph.nodes[start].chainage
		var sb: float=w.graph.nodes[end].chainage
		var blocks:=maxi(1,ceili((sb-sa)/1000))
		var previous:=start
		for block in blocks:
			var node: String=end if block==blocks-1 else "%s_%s_M%d" % [a.code,b.code,block]
			if node!=end:_node(w,node,lerpf(sa,sb,(block+1)/float(blocks)),0)
			var id: String="%s_%s_M%d" % [a.code,b.code,block]
			_edge(w,id,previous,node,90)
			for direction in [1,-1]:
				var destination: Dictionary=b if direction==1 else a
				var automatic: bool=(block<blocks-1 if direction==1 else block>0) or destination.through_halt
				var sid:=id+("-S" if direction==1 else "-N")+("A" if automatic else "H")
				w.add_signal(sid,id,direction,60)
				if automatic:w.automatic_signals.append(sid)
			previous=node
		return
	for lane in ["D","U"]:
		var start: String = a.code+"_R"+lane
		var end: String = b.code+"_L"+lane
		var sa: float = w.graph.nodes[start].chainage
		var sb: float = w.graph.nodes[end].chainage
		var blocks := maxi(1,ceili((sb-sa)/1000))
		var previous := start
		for block in blocks:
			var node := end if block==blocks-1 else "%s_%s_%d_%s" % [a.code,b.code,block,lane]
			if node!=end: _node(w,node,lerpf(sa,sb,(block+1)/float(blocks)),0 if lane=="D" else section.parallel_offset)
			var id := "%s_%s_%s%d" % [a.code,b.code,lane,block]
			var direction := 1 if lane=="D" else -1
			_edge(w,id,previous,node,100,direction)
			# Final block has its exit at the next station starter; all other
			# blocks get an automatic signal, with no fictitious signal at halts.
			var destination: Dictionary=b if direction==1 else a
			if (direction==1 and block<blocks-1) or (direction==-1 and block>0) or destination.through_halt:
				w.add_signal(id+"-A",id,direction,60)
				w.automatic_signals.append(id+"-A")
			else:
				# The last plain-line block ends at a controlled station home.
				# Its onward route can select a platform through entry points;
				# the preceding automatic signal never operates those points.
				w.add_signal(id+"-H",id,direction,60)
			previous = node

func _single_line_groups(w: RailWorld) -> void:
	var group:=""
	for i in data.sections.size():
		if data.sections[i].tracks!=1:
			group=""
			continue
		var st: Dictionary=w.stations[i]
		if group.is_empty() or not st.through_halt:group=st.code+"_single"
		var prefix: String=st.code+"_"+w.stations[i+1].code+"_M"
		for eid in w.graph.edges:
			if eid.begins_with(prefix):w.single_line_sections[eid]=group
		if st.through_halt:w.single_line_sections[st.platform_tracks[0]]=group

static func build_traffic() -> RailWorld:
	var w := build()
	var calls: Array=w.stations.filter(func(s):return s.passenger_open).map(func(s):return s.code)
	var definitions := [
		["K1","Coastal Stopping Passenger · Ernakulam to Nagercoil","icf",1,calls,1,1],
		["K2","Northbound Morning LHB","lhb",-1,["TUVR","ERS"],3,4],
		["K3","Coastal Vande Bharat · 8 cars","vb8",1,["KUMM","TUVR","ALLP","KYJ","QLN","TVC","NCJ"],3,5],
		["K4","Northbound Backwater ICF","icf",-1,["AMPA","ALLP","MAKM","SRTL","TUVR","KUMM","ERS"],2,5],
		["K5","Cape Vande Bharat · 16 cars","vb16",1,["SRTL","ALLP","KYJ","QLN","TVC","NCJ"],3,4],
		["K6","Priority Kollam LHB Express","lhb",1,["KYJ","KPY","QLN"],4,5],
		["K7","Northbound Cape LHB","lhb",-1,["ERL","KZT","PASA","NYY","TVC"],2,4]]
	var stations := {}
	for station in w.stations: stations[station.code] = station
	var departures:={"K1":"08:00","K2":"08:00","K3":"08:18","K4":"08:45","K5":"09:08","K6":"10:58","K7":"13:30"}
	var priorities:={"K1":20,"K2":70,"K3":95,"K4":40,"K5":100,"K6":80,"K7":65}
	# Fictional regional workings spread encounters across the full stopping run.
	# Unique origin and terminating loop roads keep through mains available.
	var regional: Array=JSON.parse_string(FileAccess.get_file_as_string("res://sim/timetables/kerala_regional.json"))
	for row in regional:
		definitions.append(row.slice(0,7))
		departures[row[0]]=row[7]
		priorities[row[0]]=int(row[8])
	for d in definitions:
		var t := Train.new(d[0],1)
		Stock.configure(t,d[2],"passenger" if d[0]=="K1" else "")
		t.service_name=d[1]
		t.dispatch_priority=priorities[t.id]
		if t.id=="K1":t.max_speed=65.0/3.6
		var stops := []
		var minutes := 0.0
		for i in d[4].size():
			var station: Dictionary = stations[d[4][i]]
			var road: int = d[5] if i==0 else (d[6] if i==d[4].size()-1 else (1 if d[3]==1 else 2))
			if t.id=="K1":road=1
			if t.id=="K2" and station.code=="KUMM":road=1
			if t.id=="K4" and station.code=="MAKM":road=1
			if t.id=="K7" and station.code=="NYY":road=1
			if i>0 and i<d[4].size()-1 and not w.graph.edges.has("%s_P%d" % [station.code,road]):road=1
			var block := "%s_P%d" % [station.code,road]
			# Book an actual passenger face, rather than relying on the dispatcher
			# to repair a placeholder through-road stop after the service starts.
			if station.platform_details[block].platform_width<=0:
				for candidate in station.platform_tracks:
					if station.platform_details[candidate].platform_width<=0:continue
					var goal:={block=candidate,direction=d[3],s=preload("res://sim/berth_clearance.gd").marker(w,t,candidate,d[3])}
					if not stops.is_empty() and is_inf(w._stop_distance(stops[-1].block,d[3],stops[-1].position_m,goal,[])):continue
					block=candidate;break
				assert(station.platform_details[block].platform_width>0,"No reachable passenger face at "+station.code)
			if i>0: minutes += absf(station.s-stations[d[4][i-1]].s)/1000.0/(45.0 if t.id=="K1" else 75.0)*60.0+1.8
			stops.append({name=station.name,block=block,direction=d[3],minutes_from_origin=snappedf(minutes,.1),
				dwell_minutes=1.0 if t.id=="K1" else .5,position_m=preload("res://sim/berth_clearance.gd").marker(w,t,block,d[3])})
		t.path = [{edge=stops[0].block,dir=d[3]}]
		w.trains[t.id] = t
		var result := w.set_timetable(t.id,{name=d[1],departure=departures[t.id],day=1,stops=stops})
		assert(result.ok,str(result))
		w.place_train(t,stops[0].block,stops[0].position_m,d[3])
		t.automatic = true
		t.controller = -1.0
	return w
