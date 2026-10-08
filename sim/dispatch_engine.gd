extends RefCounted
## World-owned traffic control. No scenes, input devices or rendering dependencies.
## Only the interlocking grants authority; planning cannot bypass safety checks.
const Policy := preload("res://sim/priority_dispatch.gd")
const Prediction := preload("res://sim/dispatch_prediction.gd")
const Resources := preload("res://sim/dispatch_resources.gd")
const Planner := preload("res://sim/dispatch_planner.gd")
const INTERVAL := .5
const JOURNAL_LIMIT := 256
var enabled := false
var manual_service := ""
var hold_maruthur := false
var operator_holds := {}
var inhibited_signals := {}
var platform_preferences := {}
var states := {}
var journal: Array = []
var alerts: Array = []
var revision := 0
var cycles := 0
var _world: WeakRef
var _planner := Planner.new()
var future_clearances := preload("res://sim/future_clearance.gd").new()
var _next_tick := 0.0
var _wait_since := {}
var _last_state := {}
var _advisory_release_until := {}
var _seq := 0
var _running := false

func _init(w) -> void:
	_world = weakref(w)

func advance() -> void:
	var w = _world.get_ref()
	if w == null or w.time + .000001 < _next_tick: return
	_next_tick = w.time + INTERVAL
	run_cycle(enabled)

func run_cycle(route_trains: bool = true) -> void:
	var w = _world.get_ref()
	if w == null or _running: return
	_running = true
	cycles += 1
	future_clearances.update(w,self,route_trains)
	for id in w.dispatch_holds.keys():
		if not w.trains.has(id) or not w.trains.has(w.dispatch_holds[id].get("other", "")): w.dispatch_holds.erase(id)
	if route_trains: Policy.update(w)
	for id in w.dispatch_holds.keys():
		var hold: Dictionary=w.dispatch_holds[id]
		var aged: bool=hold.get("kind","")=="overtake" and w.time-_wait_since.get(id,w.time)>900
		if route_trains and aged and not _advisory_release_until.has(id):
			_advisory_release_until[id]=w.time+120
			_record(w,"replan",id,"Long overtake wait: request a departure before accepting another advisory hold")
		if w.time<_advisory_release_until.get(id,-1):w.dispatch_holds.erase(id)
	for id in _advisory_release_until.keys():
		if w.time>=_advisory_release_until[id]:_advisory_release_until.erase(id)
	var services: Array = w.trains.values()
	services.sort_custom(func(a,b):
		var sa := _effective_priority(w, a); var sb := _effective_priority(w, b)
		return sa > sb if sa != sb else a.id < b.id)
	states.clear()
	for t: Train in services:
		if route_trains: _prepare_approach(w,t)
		var state := _evaluate(w, t, route_trains)
		state.planned_crossing=future_clearances.advice(w,t)
		if not state.planned_crossing.is_empty() and state.status in ["blocked","waiting"]:
			state.reason=state.planned_crossing+" · "+state.reason
		states[t.id] = state
		var waiting: bool = state.status in ["waiting", "held", "blocked"] and not operator_holds.has(t.id)
		if waiting and not _wait_since.has(t.id): _wait_since[t.id] = w.time
		elif not waiting: _wait_since.erase(t.id)
		state.wait_seconds = maxf(0, w.time - _wait_since.get(t.id, w.time))
		var signature: String = state.status + ":" + state.reason + ":" + state.get("destination", "")
		if signature != _last_state.get(t.id, ""):
			_last_state[t.id] = signature
			_record(w, "decision", t.id, state.reason if not state.reason.is_empty() else state.status.capitalize())
	_reconcile_waits(w, route_trains)
	w.dispatch_notices.clear()
	for id in states:
		var state: Dictionary = states[id]
		if state.status in ["waiting", "held", "blocked", "attention"]: w.dispatch_notices[id] = state.reason
	revision += 1
	_running = false

func _effective_priority(w, t: Train) -> float:
	# Aging acts only on uncommitted requests, never on route/direction locks.
	return t.dispatch_priority + minf(110, maxf(0, w.time - _wait_since.get(t.id, w.time)) / 20.0)

func _prepare_approach(w, t: Train) -> void:
	# Prepare the controlled entrance beyond a clear final automatic block.
	# Never look through a red block, another train or a booked intermediate stop.
	if not t.automatic and t.id!=manual_service:return
	var next: Dictionary=w.next_signal(t)
	if next.is_empty() or next.id not in w.automatic_signals:return
	if w.aspect(next.id)==RailWorld.Aspect.RED:return
	var automatic: Dictionary=w.signals[next.id]
	var home_id: String=automatic.destination
	if not w.signals.has(home_id) or home_id in w.automatic_signals:return
	var home: Dictionary=w.signals[home_id]
	if not home.route.is_empty():return
	var distance: float=next.distance
	for entry in automatic.route:
		distance+=absf((home.s if entry.edge==home.edge else w.graph.exit_s(entry.edge,entry.dir))-w.graph.entry_s(entry.edge,entry.dir))
	if distance>clampf(t.braking_distance()+500,1500,3500):return
	var call: Dictionary=t.timetable.stop_ahead() if t.timetable!=null else {}
	if not call.is_empty():
		var to_call: float=w._stop_distance(t.path[0].edge,t.path[0].dir,t.head_s,call,[])
		if to_call<distance:return
	var prepared:=_evaluate(w,t,true,{id=home_id,distance=distance})
	if prepared.status=="cleared":_record(w,"approach_route",t.id,"Prepared "+home_id+" ahead of "+next.id)

func _evaluate(w, t: Train, route_trains: bool, approach: Dictionary = {}) -> Dictionary:
	var ns: Dictionary = w.next_signal(t) if approach.is_empty() else approach
	var state := {id=t.id, name=t.service_name, priority=t.dispatch_priority,
		effective_priority=_effective_priority(w,t), status="running", reason="",
		signal_id=ns.get("id", ""), signal_distance=ns.get("distance", INF),
		destination="", blockers=[], alternatives=[], wait_seconds=0.0,
		call=Prediction.next_call(w,t), hold=w.dispatch_holds.get(t.id,{}).duplicate(true)}
	if t.service_complete:
		state.status="complete"; state.reason="Service complete; destination road remains occupied"; return state
	if t.emergency:
		state.status="attention"; state.reason="Emergency brake applied; release at a stand"; return state
	if t.timetable != null and t.timetable.missed_stop:
		state.status="attention"; state.reason="Missed stop: %s. Open PROGRESS / F12 to skip this call and continue." % t.timetable.stops[t.timetable.index].name; return state
	if operator_holds.has(t.id):
		state.status="held"; state.reason="Operator hold: no new controlled routes. Existing authority remains valid."; return state
	if t.timetable == null:
		state.status="manual"; state.reason="Unscheduled movement: select a signal and set a route"; return state
	if t.timetable.at_stop and w.clock_seconds() < t.timetable.release_time():
		state.status="dwell"; state.reason="Booked departure / dwell until " + preload("res://sim/world_clock.gd").format_time(t.timetable.release_time()); return state
	var future_hold: String=future_clearances.hold(w,t)
	if not future_hold.is_empty():
		state.status="held"; state.reason=future_hold; return state
	if ns.is_empty():
		state.status="attention"; state.reason="No forward signal; check the working and destination"; return state
	var sig: Dictionary = w.signals[ns.id]
	if not sig.route.is_empty():
		state.destination=sig.destination
		state.reason="Authority to " + sig.destination if sig.cleared else "Signal at red; route locked until safe release"
		state.status="cleared" if w.aspect(ns.id) != RailWorld.Aspect.RED else "waiting"
		if state.status=="waiting":
			state.blockers=Resources.blockers(w,ns.id,{edges=sig.route}).filter(func(b):return b.train!=t.id)
			if sig.cleared:state.reason="Waiting for occupied or conflicting authority ahead to clear"
			var names: Array[String]=[]
			for b in state.blockers:
				if w.trains.has(b.train) and b.train not in names:names.append(b.train)
			if not names.is_empty():state.reason+=" · "+", ".join(names.map(func(id):return w.trains[id].service_name+" ("+id+")"))
		return state
	if inhibited_signals.has(ns.id):
		state.status="held"; state.reason="Signal %s held at red by operator; release the signal hold to resume" % ns.id; return state
	var hold_reason: String = Policy.hold_reason(w,t)
	if not hold_reason.is_empty():
		state.status="held"; state.reason=hold_reason
		var held: Dictionary = w.dispatch_holds.get(t.id,{})
		if held.has("other"): state.blockers=[{train=held.other,kind="planned_"+held.kind,resource=held.station}]
		return state
	if hold_maruthur and ns.id.begins_with("MRT-") and ns.id not in ["MRT-HE","MRT-HW"]:
		state.status="held"; state.reason="Maruthur exercise: departures held"; return state
	if ns.id in w.automatic_signals:
		state.status="running" if w.aspect(ns.id) != RailWorld.Aspect.RED else "waiting"
		state.reason="Automatic block ahead" if state.status=="running" else "Waiting for automatic block clearance"
		if state.status=="waiting":
			for option in w.route_options(ns.id): state.blockers.append_array(Resources.blockers(w,ns.id,option))
		return state
	var requested: Dictionary = platform_preferences.get(t.id,{})
	var call_index: int=t.timetable.index+(1 if t.timetable.at_stop else 0)
	if not requested.is_empty() and requested.get("call_index",-1)!=call_index:
		platform_preferences.erase(t.id); requested={}
	var preference: String = requested.get("block","")
	var options: Array = _planner.candidates(w,t,ns.id,preference)
	state.alternatives=options
	var best := {}
	for option in options:
		if option.available: best=option; break
	if not best.is_empty():
		state.destination=best.destination
		state.status="ready"; state.reason="Route available to " + best.destination
		if not route_trains or (not t.automatic and t.id != manual_service): return state
		var result: Dictionary = w.set_route(ns.id,best.destination)
		if result.ok:
			if not best.stop.is_empty():
				var stop: Dictionary = t.timetable.stop_ahead()
				stop.block=best.stop.block; stop.s=best.stop.s
				platform_preferences.erase(t.id)
			if not best.hold.is_empty() and w.time>=_advisory_release_until.get(t.id,-1): w.dispatch_holds[t.id]=best.hold
			state.status="cleared"; state.reason="Route set to " + best.destination
			state.hold=w.dispatch_holds.get(t.id,{}).duplicate(true)
		else:
			state.status="waiting"; state.reason=result.reason
		return state
	state.status="blocked"
	var eligible: Array = options.filter(func(o): return o.eligible)
	if eligible.is_empty():
		state.status="attention"; state.reason="No reachable route to next call: " + t.timetable.stop_ahead().name
	else:
		state.reason=eligible[0].reason
		for option in eligible:
			for blocker in option.blockers:
				if blocker not in state.blockers: state.blockers.append(blocker)
		var names: Array[String] = []
		for blocker in state.blockers:
			if w.trains.has(blocker.train) and blocker.train not in names: names.append(blocker.train)
		if not names.is_empty(): state.reason += " · " + ", ".join(names.map(func(id):return w.trains[id].service_name+" ("+id+")"))
	return state

func _reconcile_waits(w, can_replan: bool) -> void:
	alerts.clear()
	var dependencies := {}
	for id in states:
		var state: Dictionary = states[id]
		if state.status not in ["blocked","waiting","held"]: continue
		var ids: Array = []
		for blocker in state.blockers:
			if not blocker.train.is_empty() and blocker.train != id and blocker.train not in ids: ids.append(blocker.train)
		dependencies[id]=ids
	for group in Resources.cycles(dependencies):
		var discretionary: Array = group.filter(func(id): return w.dispatch_holds.has(id))
		if can_replan and not discretionary.is_empty():
			discretionary.sort_custom(func(a,b): return _effective_priority(w,w.trains[a]) > _effective_priority(w,w.trains[b]))
			var release: String = discretionary[0]
			w.dispatch_holds.erase(release)
			_advisory_release_until[release]=w.time+120
			_record(w,"replan",release,"Circular advisory wait removed; interlocking will check the next route")
		alerts.append({kind="conflict", services=group, text="Circular dependency: "+", ".join(group)+(" · reconsidering advisory hold" if not discretionary.is_empty() else " · inspect occupied roads and alternative routes")})
	for id in states:
		var state: Dictionary = states[id]
		if state.status=="attention": alerts.append({kind="attention",services=[id],text=id+" · "+state.reason})
		elif state.wait_seconds > 180 and state.status=="blocked": alerts.append({kind="delay",services=[id],text=id+" · no route for "+str(roundi(state.wait_seconds/60))+" min · "+state.reason})

func _record(w, kind: String, train: String, text: String) -> void:
	_seq += 1
	journal.append({seq=_seq,time=w.clock_seconds(),kind=kind,train=train,text=text})
	if journal.size()>JOURNAL_LIMIT: journal.pop_front()

func set_enabled(value: bool) -> void:
	enabled=value
	var w = _world.get_ref()
	if w == null: return
	if not value: w.dispatch_holds.clear()
	_record(w,"operator","","Automatic dispatch " + ("enabled" if value else "disabled; existing authorities retained"))
	run_cycle(enabled)

func set_service_hold(id: String, value: bool) -> Dictionary:
	var w = _world.get_ref()
	if w == null or not w.trains.has(id): return {ok=false,reason="Unknown service"}
	if value: operator_holds[id]=true
	else: operator_holds.erase(id)
	_record(w,"operator",id,"Hold at next uncommitted controlled signal" if value else "Operator hold released")
	run_cycle(enabled)
	return {ok=true,reason=""}

func set_priority(id: String, value: int) -> Dictionary:
	var w = _world.get_ref()
	if w == null or not w.trains.has(id) or value<0 or value>100: return {ok=false,reason="Priority must be 0–100 for a known service"}
	w.trains[id].dispatch_priority=value
	_record(w,"operator",id,"Priority changed to "+str(value))
	run_cycle(enabled)
	return {ok=true,reason=""}

func assign_platform(id: String, block: String) -> Dictionary:
	var w = _world.get_ref()
	if w == null or not w.trains.has(id): return {ok=false,reason="Unknown service"}
	var t: Train = w.trains[id]
	if t.timetable==null or t.service_complete: return {ok=false,reason="No next call"}
	var stop: Dictionary = t.timetable.stop_ahead()
	var st: Dictionary = Policy.station(w,stop.block)
	if st.is_empty() or block not in st.get("platform_tracks",[]): return {ok=false,reason="Choose a road at the next scheduled station"}
	if st.get("platform_details",{}).get(block,{}).get("platform_width",1)<=0 or preload("res://sim/berth_clearance.gd").capacity(w,block)<t.length: return {ok=false,reason="Road cannot accommodate the full train clear of signals, points and platform ends"}
	var goal := {block=block,direction=stop.direction,s=preload("res://sim/berth_clearance.gd").marker(w,t,block,stop.direction)}
	if is_inf(w._stop_distance(t.path[0].edge,t.path[0].dir,t.head_s,goal,[])): return {ok=false,reason="Platform is not reachable in this direction"}
	var ns: Dictionary=w.next_signal(t)
	if not ns.is_empty() and w.signals[ns.id].route.any(func(r):return r.edge in st.platform_tracks): return {ok=false,reason="Station entry route already committed; platform cannot change until safe release"}
	goal.call_index=t.timetable.index+(1 if t.timetable.at_stop else 0)
	platform_preferences[id]=goal
	_record(w,"operator",id,"Requested next-call road "+block)
	run_cycle(enabled)
	return {ok=true,reason=""}

func request_route(source: String, destination: String) -> Dictionary:
	var w = _world.get_ref()
	if w == null: return {ok=false,reason="Simulation unavailable"}
	if source in w.automatic_signals: return {ok=false,reason="Automatic block signals are controlled by occupancy"}
	var preview:=route_preview(source,destination)
	if not preview.ok: return preview
	var result: Dictionary=w.set_route(source,destination)
	if result.ok:
		inhibited_signals.erase(source)
		if not preview.get("stop",{}).is_empty():
			var t: Train=w.trains[preview.train]
			var stop: Dictionary=t.timetable.stop_ahead()
			stop.block=preview.stop.block;stop.s=preview.stop.s
			platform_preferences.erase(t.id)
	_record(w,"operator","",("Set " if result.ok else "Refused ")+source+" → "+destination+("" if result.ok else ": "+result.reason))
	run_cycle(false)
	return result

func route_preview(source: String, destination: String) -> Dictionary:
	var w = _world.get_ref()
	if w == null: return {ok=false,reason="Simulation unavailable"}
	var reason: String=w.route_reason(source,destination)
	if not reason.is_empty():return {ok=false,reason=reason}
	for t: Train in w.trains.values():
		var ns: Dictionary=w.next_signal(t)
		if ns.get("id","")!=source or t.timetable==null:continue
		var planned_hold: String=future_clearances.hold(w,t)
		if not planned_hold.is_empty():return {ok=false,reason=planned_hold}
		for option in _planner.candidates(w,t,source):
			if option.destination==destination:
				return {ok=option.available,reason=option.reason,stop=option.stop,train=t.id}
	for option in w.route_options(source):
		if option.destination!=destination:continue
		for entry in option.edges:
			if not future_clearances.owner(entry.edge).is_empty():return {ok=false,reason="Platform reserved for a planned crossing"}
			for plan in future_clearances.plans:
				if w.single_line_sections.get(entry.edge,"") in [plan.approach_section,plan.escape_section]:return {ok=false,reason="Section reserved for a planned crossing"}
	return {ok=true,reason=""}

func put_to_red(source: String) -> Dictionary:
	var w = _world.get_ref()
	if w == null or source in w.automatic_signals: return {ok=false,reason="Select a controlled signal"}
	var result: Dictionary=w.set_signal(source,false)
	if result.ok:
		inhibited_signals[source]=true
		_record(w,"operator","",source+" held at red; approach and occupied route locks retained")
	run_cycle(false)
	return result

func release_signal(source: String) -> void:
	inhibited_signals.erase(source)
	var w = _world.get_ref()
	if w != null: _record(w,"operator","",source+" operator hold released")
	run_cycle(enabled)

func snapshot() -> Dictionary:
	return {revision=revision,enabled=enabled,services=states.duplicate(true),alerts=alerts.duplicate(true),journal=journal.duplicate(true),future_plans=future_clearances.plans.duplicate(true)}

func delete_service(id: String, protected_service: String="") -> Dictionary:
	var w = _world.get_ref()
	if w==null or not w.trains.has(id):return {ok=false,reason="Service no longer exists"}
	if id==manual_service or id==protected_service:return {ok=false,reason="Take control of another service before deleting your assigned train"}
	if w.trains.size()<=1:return {ok=false,reason="Keep at least one service in the scenario"}
	var t: Train=w.trains[id]
	var next: Dictionary=w.next_signal(t)
	var released: Array=[]
	for sig in w.signals.values():
		if sig.owner!=id and not (sig.owner.is_empty() and sig.id==next.get("id","")):continue
		sig.cleared=false;sig.route=[];sig.owner="";sig.destination="";sig.cancel_pending=false
		released.append(sig.id)
	w.trains.erase(id)
	w.dispatch_notices.erase(id)
	for held in w.dispatch_holds.keys():
		if held==id or w.dispatch_holds[held].get("other","")==id:w.dispatch_holds.erase(held)
	for state in [operator_holds,platform_preferences,states,_wait_since,_last_state,_advisory_release_until]:state.erase(id)
	for p in future_clearances.plans.duplicate():
		if id in [p.incoming,p.opponent,p.vacater]:
			future_clearances.plans.erase(p)
			_record(w,"crossing_cancelled",id,"Reassess planned crossing at "+p.station+": service deleted")
	_record(w,"service_deleted",id,"Deleted "+t.service_name+"; removed its train and released its own authority")
	run_cycle(enabled)
	return {ok=true,reason="",id=id,released_signals=released}
