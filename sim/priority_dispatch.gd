extends RefCounted
## Geographic dispatch decisions use actual progress, booked departure and priority.
## They only choose/withhold ordinary interlocked routes, never override protection.
const LOOKAHEAD_SECONDS := 240.0
const MAX_HOLD_ETA := 300.0

static func chainage(w: RailWorld,t: Train) -> float:
	var e: Dictionary=w.graph.edges[t.path[0].edge]
	return lerpf(e.get("chainage_start",0),e.get("chainage_end",0),t.head_s/e.length)

static func station(w: RailWorld,edge: String) -> Dictionary:
	if not edge.get_slice("_P",1).is_valid_int():return {}
	var code:=edge.get_slice("_P",0)
	for st in w.stations:
		if st.code==code:return st
	return {}

static func eta(w: RailWorld,t: Train,s: float) -> float:
	return preload("res://sim/dispatch_prediction.gd").arrival_seconds(w,t,s)

static func conflict(w: RailWorld,t: Train,st: Dictionary) -> Dictionary:
	if st.is_empty() or st.through_halt:return {}
	var direction: int=t.path[0].dir
	var own_eta:=eta(w,t,st.s)
	var at:=chainage(w,t)
	var best:={}
	var best_eta:=INF
	for other: Train in w.trains.values():
		if other==t or other.service_complete:continue
		var other_at:=chainage(w,other)
		var other_eta:=eta(w,other,st.s)
		if other_eta>best_eta:continue
		var opposing: bool=other.path[0].dir!=direction
		if opposing:
			# Honour the meet already chosen at the other end of a long section.
			# Otherwise both first arrivals can wait in different station loops.
			var existing: Dictionary=w.dispatch_holds.get(other.id,{})
			if existing.get("kind","")=="crossing" and existing.get("other","")==t.id:continue
			if other_eta>own_eta+_crossing_window(w,t,other,st):continue
			if own_eta>other_eta+10.0:continue # the first arrival takes the loop
			if w.dispatch_holds.get(other.id,{}).get("station","")==st.code:continue
			# Crossing applies only where the onward approach is single line.
			var sections: Array=w.scenery.route.sections
			var index: int=w.stations.find(st)+(0 if direction==1 else -1)
			if index<0 or index>=sections.size() or sections[index].tracks!=1:continue
			if (other_at-st.s)*direction<500:continue # already in/past this station
		else:
			if other_eta>own_eta+LOOKAHEAD_SECONDS:continue
			if other.dispatch_priority<=t.dispatch_priority or (at-other_at)*direction<0:continue
			if other.max_speed<=t.max_speed and not (t.timetable!=null and t.timetable.at_stop):continue
		best={other=other.id,station=st.code,chainage=st.s,kind="crossing" if opposing else "overtake",direction=direction}
		best_eta=other_eta
	return best

static func _crossing_window(w: RailWorld,t: Train,other: Train,st: Dictionary) -> float:
	# A single-line meet must be considered across the entire next section, not
	# just a four-minute radius. Otherwise the first arrival takes the main and
	# is trapped there when its opposing train has a long approach through halts.
	var index: int=w.stations.find(st)+t.path[0].dir
	while index>=0 and index<w.stations.size():
		var next: Dictionary=w.stations[index]
		if not next.get("through_halt",false):
			return maxf(LOOKAHEAD_SECONDS,absf(next.s-st.s)/minf(t.max_speed,other.max_speed)+120)
		index+=t.path[0].dir
	return LOOKAHEAD_SECONDS

static func update(w: RailWorld) -> void:
	if not w.scenery.get("geographic",false):return
	for id in w.dispatch_holds.keys():
		var hold: Dictionary=w.dispatch_holds[id]
		var t: Train=w.trains[id]
		var other: Train=w.trains[hold.other]
		var passed: bool=(chainage(w,other)-hold.chainage)*other.path[0].dir>other.length+500
		var withdrawn: bool=eta(w,other,hold.chainage)>MAX_HOLD_ETA
		if withdrawn and hold.kind=="crossing":
			var st: Dictionary=w.stations.filter(func(s):return s.code==hold.station)[0]
			withdrawn=conflict(w,t,st).get("other","")!=other.id
		if hold.kind=="crossing":
			var st: Dictionary=w.stations.filter(func(s):return s.code==hold.station)[0]
			if station(w,t.path[0].edge).get("code","")==st.code and not _passing_road_available(w,other,st,t.path[0].edge):withdrawn=true
		if passed or other.service_complete or withdrawn:
			if passed:
				w.dispatch_history.append({train=id,other=other.id,station=hold.station,kind=hold.kind,time=w.clock_seconds()})
				if w.dispatch_history.size()>128:w.dispatch_history.pop_front()
			w.dispatch_holds.erase(id)
	# A newly approaching express can also overtake a service already dwelling.
	for t: Train in w.trains.values():
		if t.service_complete or w.dispatch_holds.has(t.id) or t.timetable==null or not t.timetable.at_stop:continue
		var st:=station(w,t.path[0].edge)
		var decision:=conflict(w,t,st)
		if decision.is_empty() or decision.kind!="overtake":continue
		if st.platform_tracks.size()<3 and not _single_both(w,st):continue
		# A free opposite-line road is not necessarily reachable from this approach.
		if _passing_road_available(w,w.trains[decision.other],st,t.path[0].edge):
			w.dispatch_holds[t.id]=decision

static func _passing_road_available(w: RailWorld,other: Train,st: Dictionary,held_edge: String) -> bool:
	var occ:=w.occupancy()
	var direction: int=other.path[0].dir
	var approach: float=(st.s-chainage(w,other))*direction
	var free: Array=st.platform_tracks.filter(func(r):return r!=held_edge and not occ.has(r))
	var compatible:=preload("res://sim/receiving_berths.gd").roads(w,other,st,other.path[0].edge,direction,free)
	for road: String in compatible:
		var goal:={block=road,direction=direction,s=w.graph.edges[road].length*.5}
		var distance:=w._stop_distance(other.path[0].edge,direction,other.head_s,goal,[])
		if distance<maxf(0,approach)+2000:return true
	return false

static func _single_both(w: RailWorld,st: Dictionary) -> bool:
	var index: int=w.stations.find(st)
	var sections: Array=w.scenery.route.sections
	return (index==0 or sections[index-1].tracks==1) and (index==sections.size() or sections[index].tracks==1)

static func hold_reason(w: RailWorld,t: Train,approaching: bool=false) -> String:
	if approaching and t.timetable!=null and t.timetable.missed_stop:
		return "Missed stop: %s. Open PROGRESS / F12 to skip this call and continue." % t.timetable.stops[t.timetable.index].name
	if not w.dispatch_holds.has(t.id):return w.dispatch_notices.get(t.id,"") if approaching else ""
	var hold: Dictionary=w.dispatch_holds[t.id]
	if not approaching and station(w,t.path[0].edge).get("code","")!=hold.station:return ""
	var other: Train=w.trains[hold.other]
	var action: String="crosses" if hold.kind=="crossing" else "overtakes"
	return "Expect a wait at %s until %s (%s) %s" % [hold.station,other.service_name,other.id,action]

static func refresh_notices(w: RailWorld) -> void:
	if not w.scenery.get("geographic",false):return
	w.dispatch_notices.clear()
	var occ:=w.occupancy()
	for t: Train in w.trains.values():
		if t.service_complete or w.dispatch_holds.has(t.id):continue
		var ns:=w.next_signal(t)
		if ns.is_empty() or ns.distance>1500 or w.aspect(ns.id)!=RailWorld.Aspect.RED:continue
		var blocker: Train=null
		for option in w.route_options(ns.id):
			for entry in option.edges:
				var section: String=w.single_line_sections.get(entry.edge,"")
				for other: Train in w.trains.values():
					if other==t:continue
					if not section.is_empty() and other.path.any(func(p):return w.single_line_sections.get(p.edge,"")==section and p.dir!=entry.dir):
						blocker=other;break
				if blocker!=null:break
				if occ.has(entry.edge) and occ[entry.edge]!=t.id:blocker=w.trains[occ[entry.edge]];break
			if blocker!=null:break
		if blocker!=null:
			var action:="crosses" if blocker.path[0].dir!=t.path[0].dir else "clears the section"
			w.dispatch_notices[t.id]="Expect a wait here until %s (%s) %s" % [blocker.service_name,blocker.id,action]

static func choose_platform(w: RailWorld,t: Train,options: Array,stop: Dictionary) -> Dictionary:
	if not w.scenery.get("geographic",false) or options.is_empty():return {}
	var st:=station(w,options[0].edges[-1].edge)
	if st.is_empty() or st.through_halt:return {}
	var stopping: bool=station(w,stop.block).get("code","")==st.code
	# Finished services keep their allocated terminal road clear of the main.
	if stopping and t.timetable.index>=t.timetable.stops.size()-1:return {}
	var decision:=conflict(w,t,st)
	var primary:=1 if _single_both(w,st) or t.path[0].dir==1 else 2
	var best:={}
	var cost:=INF
	for option in options:
		var last: Dictionary=option.edges[-1]
		if station(w,last.edge).get("code","")!=st.code:continue
		var road: int=int(last.edge.get_slice("_P",1))
		if stopping and st.platform_details[last.edge].platform_width<=0:continue
		var is_loop: bool=road!=primary and (road>2 or _single_both(w,st))
		if w.route_reason(w.next_signal(t).id,option.destination)!="":continue
		var goal:=stop.duplicate()
		if stopping:goal.block=last.edge;goal.s=w.graph.edges[last.edge].length*.5+last.dir*t.length*.5
		var onward:=w._stop_distance(last.edge,last.dir,w.graph.entry_s(last.edge,last.dir),goal,[])
		if is_inf(onward):continue
		var score: float=option.cost*.001+(0 if road==primary else 20)
		if not decision.is_empty():score+=-100 if is_loop else 100
		if score<cost:
			cost=score
			var hold: Dictionary=decision if is_loop else {}
			if not hold.is_empty() and not _passing_road_available(w,w.trains[hold.other],st,last.edge):hold={}
			best={option=option,stop=goal if stopping else {},hold=hold}
	return best
