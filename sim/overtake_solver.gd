extends RefCounted
## Worker-owned rolling-horizon proposals. These never grant movement authority.
const Forecast:=preload("res://sim/dispatch_forecast.gd")
const CLEARANCE_MARGIN:=45.0
const MAX_AHEAD:=30000.0
const MAX_STATIONS:=4
var forecast

func _init(topology: Dictionary) -> void:forecast=Forecast.new(topology)

func solve(frame: Dictionary) -> Dictionary:
	var plans:=[];var trains: Array=frame.trains.duplicate()
	trains.sort_custom(func(a,b):return a.id<b.id)
	for slow: Dictionary in trains:
		var plan:=for_train(frame,slow)
		if not plan.is_empty():plans.append(plan)
	return {clock=frame.clock,time=frame.time,plans=plans}

func for_train(frame: Dictionary,slow: Dictionary) -> Dictionary:
	if slow.emergency or slow.missed or slow.operator_hold or slow.crossing or slow.platform_override:return {}
	var contenders: Array=frame.trains.filter(func(fast):return fast.id!=slow.id and fast.direction==slow.direction and fast.priority>slow.priority and not fast.emergency and not fast.operator_hold and not fast.crossing and not fast.missed and (slow.chainage-fast.chainage)*slow.direction>=0 and (slow.chainage-fast.chainage)*slow.direction<MAX_AHEAD)
	contenders.sort_custom(func(a,b):return a.chainage>b.chainage if slow.direction==1 else a.chainage<b.chainage)
	var alternatives:=[]
	var unresolved:=[]
	# A slower service must be able to get clear before EVERY nearby higher
	# priority follower, not just the most convenient one in the list.
	for fast: Dictionary in contenders:
		var choice:=pair(frame,slow,fast)
		if not choice.is_empty():alternatives.append(choice)
		else:unresolved.append(fast.id)
	if alternatives.is_empty():return {}
	alternatives.sort_custom(func(a,b):return a.chainage*slow.direction<b.chainage*slow.direction if a.chainage!=b.chainage else a.fast_entry<b.fast_entry)
	var best: Dictionary=alternatives[0];best.participants=contenders.map(func(t):return t.id)
	# Do not certify onward progress around an unmodelled higher-priority
	# follower. The owner keeps its conservative current policy in that case.
	if not unresolved.is_empty() and not best.at_station:return {}
	return best

func pair(frame: Dictionary,slow: Dictionary,fast: Dictionary) -> Dictionary:
	var stations: Array=forecast.topology.stations.filter(func(st):return not st.halt and (st.s-slow.chainage)*slow.direction>=-st.half and (st.s-slow.chainage)*slow.direction<MAX_AHEAD)
	stations.sort_custom(func(a,b):return a.s<b.s if slow.direction==1 else a.s>b.s)
	var choices:=[];var checked:=0
	for station: Dictionary in stations:
		if checked>=MAX_STATIONS:break
		checked+=1
		var stop:=stop_for(slow,station.code);var express_stop:=stop_for(fast,station.code)
		if stop.get("final",false):break
		var slow_roads:=roads(frame,slow,station,not stop.is_empty())
		var fast_roads:=roads(frame,fast,station,not express_stop.is_empty())
		for slow_road: Dictionary in slow_roads:
			# A train already berthed cannot be teleported to another road. For a
			# future pass choose a loop, preserving the directional main for speed.
			var here: bool=slow.edge in station.roads.map(func(r):return r.id)
			if here and slow_road.id!=slow.edge:continue
			if not here and slow_road.main:continue
			for fast_road: Dictionary in fast_roads:
				if fast_road.id==slow_road.id:continue
				var candidate:=evaluate(slow,fast,station,slow_road,fast_road,stop,express_stop,here)
				if candidate.is_empty():continue
				if not free_by(frame,slow_road.id,slow.id,candidate.slow_clear-CLEARANCE_MARGIN):continue
				if not free_by(frame,fast_road.id,fast.id,candidate.fast_entry-CLEARANCE_MARGIN):continue
				choices.append(candidate)
	if choices.is_empty():return {}
	choices.sort_custom(func(a,b):return a.cost<b.cost if not is_equal_approx(a.cost,b.cost) else a.chainage*slow.direction>b.chainage*slow.direction)
	var best: Dictionary=choices[0]
	best.alternatives=choices.map(func(c):return {station=c.station,road=c.road,passing_road=c.passing_road,cost=c.cost,margin=c.margin,wait=c.wait,slow_clear=c.slow_clear,fast_entry=c.fast_entry})
	return best

func evaluate(slow: Dictionary,fast: Dictionary,station: Dictionary,loop: Dictionary,main: Dictionary,stop: Dictionary,express_stop: Dictionary,here: bool) -> Dictionary:
	var mark:=marker(loop,slow,not stop.is_empty())
	var own: Dictionary={ok=true,arrival=slow.clock,seconds=0.0} if here and slow.at_stop else forecast.arrival(slow,loop.id,mark,true,true)
	var main_edge: Dictionary=forecast.topology.edges[main.id]
	var enter_s: float=0.0 if fast.direction==1 else main_edge.length
	var incoming: Dictionary=forecast.arrival(fast,main.id,enter_s,false,false)
	if not own.ok or not incoming.ok or incoming.seconds>1800:return {}
	# Projection uncertainty grows with running time and manual driving. Stopped
	# train's actual clearance is already known; future ones must fit with margin.
	var uncertainty: float=maxf(15,own.seconds*.10)+(30 if slow.manual else 0)
	var margin: float=incoming.arrival-own.arrival-CLEARANCE_MARGIN-uncertainty
	if not here and margin<0:return {}
	var ready: float=slow.release if here and slow.at_stop else maxf(own.arrival+stop.get("dwell",0),stop.get("departure",0))
	var passed: float=incoming.arrival+(main_edge.length+fast.length)/maxf(5,minf(main_edge.limit,fast.max_speed)-.4)
	if not express_stop.is_empty():
		var fast_stop: Dictionary=forecast.arrival(fast,main.id,marker(main,fast,true),true,false)
		if not fast_stop.ok:return {}
		passed=maxf(fast_stop.arrival+express_stop.dwell,express_stop.departure)+5+(main_edge.length*.5+fast.length)/8.0
	var wait:=maxf(0,passed+15-ready)
	if wait>1800:return {} # no newly invented half-hour-plus optional hold
	# Calls are already included in ready: a natural platform dwell absorbs the
	# pass instead of adding an unnecessary new stop. Main-line passes avoid a
	# speed penalty for the priority service. Small distance tie-break prefers
	# making useful progress when costs are otherwise indistinguishable.
	var penalty:=0.0 if main.main else (25.0 if not express_stop.is_empty() else 90.0)
	var cost:=wait+penalty*3+(45.0 if stop.is_empty() else 0.0)-absf(station.s-slow.chainage)*.001
	return {train=slow.id,other=fast.id,station=station.code,chainage=station.s,direction=slow.direction,road=loop.id,passing_road=main.id,
		slow_clear=own.arrival,fast_entry=incoming.arrival,fast_clear=passed,margin=margin,wait=wait,cost=cost,at_station=here,
		stop=not stop.is_empty(),express_stop=not express_stop.is_empty(),created=slow.clock,origin_edge=slow.edge,call_index=slow.call_index}

static func marker(road: Dictionary,t: Dictionary,passenger: bool) -> float:
	var bounds: Array=road.platform if passenger else road.bounds
	return (bounds[0]+bounds[1])*.5+t.direction*t.length*.5

static func stop_for(t: Dictionary,code: String) -> Dictionary:
	if t.at_stop and t.current_call.code==code:return t.current_call
	for stop: Dictionary in t.calls:
		if stop.code==code:return stop
	return {}

func free_by(frame: Dictionary,road: String,requester: String,deadline: float) -> bool:
	for owner: String in [frame.occupied.get(road,""),frame.claims.get(road,"")]:
		if owner in ["",requester]:continue
		var matches: Array=frame.trains.filter(func(t):return t.id==owner)
		if matches.is_empty():return false
		var t: Dictionary=matches[0]
		if t.emergency or t.operator_hold or t.crossing or t.get("advisory_held",false) or t.get("inhibited",false) or t.manual:return false
		var edge: Dictionary=forecast.topology.edges[road]
		var end: float=edge.end if t.direction==1 else edge.start
		var past: float=(t.chainage-end)*t.direction
		if past>0:
			if t.speed<2 or frame.clock+maxf(0,t.length-past)/t.speed+30>deadline:return false
		else:
			var exit: Dictionary=forecast.arrival(t,road,edge.length if t.direction==1 else 0.0,false,true)
			if not exit.ok:return false
			var stop:=stop_for(t,edge.station)
			var clear: float=exit.arrival+t.length/maxf(3,exit.speed)+30
			if not stop.is_empty() and not (t.at_stop and t.edge==road):clear+=stop.dwell+60
			if clear>deadline:return false
	return true

static func roads(_frame: Dictionary,t: Dictionary,station: Dictionary,passenger: bool) -> Array:
	return station.roads.filter(func(r):
		var bounds: Array=r.platform if passenger else r.bounds
		return not r.storage and (not passenger or r.passenger) and bounds[1]-bounds[0]>=t.length and r.lane in ["M","D" if t.direction==1 else "U"])
