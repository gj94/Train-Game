extends RefCounted
## Called only by the simulation owner. Worker input is detached scalar data;
## topology is immutable after construction and contains no engine resources.
const Berths:=preload("res://sim/berth_clearance.gd")

static func topology(w: RailWorld) -> Dictionary:
	var result:={edges={},stations=[]}
	for id: String in w.graph.edges:
		if w.depots.has(id):continue
		var e: Dictionary=w.graph.edges[id];var adjacent:={"1":[],"-1":[]}
		for direction in [1,-1]:
			var node: String=w.graph.exit_node(id,direction);var exits:=[]
			if w.graph.switches.has(node):
				var sw: Dictionary=w.graph.switches[node]
				exits=[sw.normal,sw.reverse] if id==sw.trunk else [sw.trunk]
			else:exits=w.graph.nodes[node].edges
			for other: String in exits:
				if other==id or w.depots.has(other):continue
				var dir:=1 if w.graph.edges[other].a==node else -1
				if w.graph.allows(other,dir):adjacent[str(direction)].append({edge=other,dir=dir})
		result.edges[id]={length=e.length,limit=e.speed_limit,start=e.get("chainage_start",0.0),end=e.get("chainage_end",0.0),next=adjacent,station=""}
	for st: Dictionary in w.stations:
		var roads:=[]
		for road: String in st.platform_tracks:
			if not result.edges.has(road):continue
			result.edges[road].station=st.code
			var details: Dictionary=st.platform_details[road]
			var bounds:=Berths.limits(w,road,false);var platform:=Berths.limits(w,road,true)
			roads.append({id=road,main=details.get("service","")=="main",lane=details.get("lane","M"),storage=details.get("storage",false),
				bounds=[bounds.x,bounds.y],platform=[platform.x,platform.y],passenger=details.get("platform_width",0)>0})
		result.stations.append({code=st.code,name=st.name,s=st.s,half=st.get("yard_half",500.0),halt=st.get("through_halt",false),roads=roads})
	return result

static func chainage(w: RailWorld,t: Train) -> float:
	var e: Dictionary=w.graph.edges[t.path[0].edge]
	return lerpf(e.get("chainage_start",0.0),e.get("chainage_end",0.0),t.head_s/e.length)

static func train(w: RailWorld,t: Train) -> Dictionary:
	var tt=t.timetable;var calls:=[]
	for i in range(tt.index+(1 if tt.at_stop else 0),tt.stops.size()):
		var stop: Dictionary=tt.stops[i];var e: Dictionary=w.graph.edges[stop.block]
		calls.append({code=str(stop.block).get_slice("_P",0),road=stop.block,s=stop.s,chainage=lerpf(e.get("chainage_start",0.0),e.get("chainage_end",0.0),stop.s/e.length),
			arrival=tt.planned_arrival(i),departure=tt.planned_departure(i),dwell=stop.dwell_minutes*60,final=i==tt.stops.size()-1})
	var tail:=[];var behind: float=t.head_s if t.path[0].dir==1 else w.graph.edges[t.path[0].edge].length-t.head_s
	for part: Dictionary in t.path.slice(1):
		tail.append({behind=behind,limit=w.graph.edges[part.edge].speed_limit});behind+=w.graph.edges[part.edge].length
	var current: Dictionary=tt.stops[tt.index]
	return {id=t.id,edge=t.path[0].edge,head_s=t.head_s,direction=t.path[0].dir,chainage=chainage(w,t),clock=w.clock_seconds(),
		speed=t.speed,length=t.length,max_speed=t.max_speed,accel=t.max_accel,power=t.max_power,mass=t.mass,decel=t.service_decel,
		calls=calls,tail_limits=tail,priority=t.dispatch_priority,at_stop=tt.at_stop,release=tt.release_time() if tt.at_stop else w.clock_seconds(),
		current_call={code=str(current.block).get_slice("_P",0),road=current.block,dwell=current.dwell_minutes*60,departure=tt.planned_departure(tt.index),final=tt.index==tt.stops.size()-1},
		departure_allowance=maxf(0,t.horn_ready_at-w.time) if t.horn_ready_at>=0 else 5.0,
		manual=not t.automatic,emergency=t.emergency,call_index=tt.index,missed=tt.missed_stop}

static func frame(w: RailWorld) -> Dictionary:
	var engine=w.dispatcher();var trains:=[];var occupied:=w.occupancy().duplicate()
	for t: Train in w.active_trains():
		if t.timetable==null or t.service_complete:continue
		var item:=train(w,t)
		item.operator_hold=engine.operator_holds.has(t.id)
		item.platform_override=engine.platform_preferences.has(t.id)
		item.crossing=engine.future_clearances.controls_order(t.id)
		item.advisory_held=w.dispatch_holds.has(t.id)
		var ahead_signal: Dictionary=w.next_signal(t)
		item.inhibited=not ahead_signal.is_empty() and engine.inhibited_signals.has(ahead_signal.id)
		trains.append(item)
	return {clock=w.clock_seconds(),time=w.time,trains=trains,occupied=occupied,claims=claims(w),holds=w.dispatch_holds.duplicate(true)}

static func claims(w: RailWorld) -> Dictionary:
	var engine=w.dispatcher();var result:={}
	var approaching:={}
	for t: Train in w.active_trains():
		if t.timetable==null or t.service_complete:continue
		for ahead: Dictionary in engine._planner.approach_signals(w,t):
			if not approaching.has(ahead.id) or ahead.distance<approaching[ahead.id].distance:approaching[ahead.id]={id=t.id,distance=ahead.distance}
	for sig: Dictionary in w.routed_signals():
		for part: Dictionary in sig.route:
			if part.edge.get_slice("_P",1).is_valid_int():result[part.edge]=sig.owner if not sig.owner.is_empty() else approaching.get(sig.id,{}).get("id","@committed")
	for st: Dictionary in w.stations:
		for road: String in st.platform_tracks:
			var owner: String=engine.future_clearances.owner(road)
			if not owner.is_empty():result[road]=owner
	return result
