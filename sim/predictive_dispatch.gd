extends RefCounted
## Simulation-owner gate for detached forecasts. Plans are advice, never authority.
## A stale/missing proposal falls back to Classic; existing interlocking still
## checks every route, receiving berth, opposing movement and full-tail release.
const InputData:=preload("res://sim/dispatch_forecast_input.gd")
const Worker:=preload("res://sim/dispatch_forecast_worker.gd")
const REFRESH_SECONDS:=5.0
const MAX_AGE:=15.0
var enabled:=false
var asynchronous:=true
var worker_count:=4
var offline_workers:=0
var plans: Dictionary={}
var metrics: Dictionary={}
var _worker
var _next_refresh: float=-INF
var _road_owners: Dictionary={}
var _claims_dirty:=true
var _generation:=0

func configure(value: bool,async_work: bool=true) -> void:
	if enabled==value and asynchronous==async_work:return
	if _worker!=null:_worker.close()
	enabled=value;asynchronous=async_work;_generation+=1
	plans.clear();_road_owners.clear();_next_refresh=-INF;_claims_dirty=true

func execution(async_work: bool,parallel_workers: int=0) -> void:
	if asynchronous==async_work and offline_workers==parallel_workers:return
	if plans.is_empty() or (_worker!=null and _worker.busy()):_next_refresh=-INF
	if _worker!=null:_worker.close()
	asynchronous=async_work;offline_workers=clampi(parallel_workers,0,4)

func update(w: RailWorld,engine) -> void:
	if not enabled or not w.scenery.get("geographic",false):return
	_claims_dirty=true
	if _worker==null:_worker=Worker.new(InputData.topology(w))
	if asynchronous:
		var completed: Dictionary=_worker.take()
		if not completed.is_empty():accept(w,engine,completed)
	for id: String in plans.keys():
		if not valid(w,engine,plans[id]):plans.erase(id)
	if w.time+0.000001<_next_refresh or _worker.busy():return
	_next_refresh=w.time+REFRESH_SECONDS
	var began:=Time.get_ticks_usec();var frame:=InputData.frame(w)
	frame.generation=_generation
	metrics.capture_usec=Time.get_ticks_usec()-began
	if asynchronous:_worker.submit(frame,worker_count)
	else:accept(w,engine,_worker.parallel_complete(frame,offline_workers) if offline_workers>0 else _worker.synchronous(frame))

func accept(w: RailWorld,engine,result: Dictionary) -> void:
	if not enabled or result.get("generation",-1)!=_generation:return
	var age: float=w.time-result.time
	if age<0 or age>MAX_AGE:
		metrics.discarded_stale=metrics.get("discarded_stale",0)+1;return
	var inputs: Dictionary={}
	for item: Dictionary in result.inputs:inputs[item.id]=item
	var accepted: Dictionary={}
	var candidates: Array=result.plans.duplicate()
	candidates.sort_custom(func(a,b):return a.fast_entry<b.fast_entry if a.fast_entry!=b.fast_entry else a.train<b.train)
	for candidate: Dictionary in candidates:
		var p:=candidate.duplicate(true)
		p.time=result.time;p.generation=_generation
		if not inputs.has(p.train) or not inputs.has(p.other):continue
		var participants: Array=p.get("participants",[p.other])
		var changed:=false
		for id: String in [p.train]+participants:
			if not inputs.has(id) or not matches_input(w,engine,id,inputs[id],age):changed=true;break
		if changed:continue
		p.inputs={}
		for id: String in [p.train]+participants:
			var item: Dictionary=inputs[id]
			p.inputs[id]={priority=item.priority,manual=item.manual,length=item.length,speed=item.speed,call_index=item.call_index}
		p.owners={}
		for road: String in [p.road,p.passing_road]:
			p.owners[road]=[result.get("occupied",{}).get(road,""),result.get("claims",{}).get(road,"")]
		if not valid(w,engine,p):continue
		# Two separately computed plans cannot promise the same road over the
		# same time interval. Earlier committed traffic keeps precedence.
		if accepted.values().any(func(other):return overlap(p,other)):continue
		accepted[p.train]=p
		var previous: Dictionary=plans.get(p.train,{})
		if previous.get("station","")!=p.station or previous.get("other","")!=p.other or previous.get("action","")!=p.get("action","pass"):
			var text: String="Retain following order for "+p.other if p.get("action","pass")=="follow" else "Plan "+p.other+" to overtake at "+p.station+"; receiving road "+p.road+", through road "+p.passing_road
			if p.has("order"):text+="; projected priority delay saved %.0fs at %s" % [p.order.saved,p.order.checkpoint]
			engine._record(w,"prediction",p.train,text)
	plans=accepted
	metrics.last_age=age;metrics.accepted=plans.size();metrics.worker_threads=result.get("worker_threads",[])
	metrics.cpu_usec=result.get("cpu_usec",0);metrics.wall_usec=result.get("wall_usec",0)

static func matches_input(w: RailWorld,engine,id: String,input: Dictionary,age: float) -> bool:
	var t: Train=w.trains.get(id)
	if t==null or t.lifecycle!="active" or t.service_complete or t.timetable==null:return false
	if t.emergency or t.timetable.missed_stop or engine.operator_holds.has(id) or engine.platform_preferences.has(id):return false
	if engine.future_clearances.controls_order(id):return false
	if t.path[0].dir!=input.direction or t.dispatch_priority!=input.priority or t.automatic==input.manual:return false
	if t.timetable.index!=input.call_index:return false
	# A moved/replaced train or abrupt manual slowdown invalidates the result;
	# ordinary motion within the captured interval is expected.
	if absf(InputData.chainage(w,t)-input.chainage)>t.max_speed*age+30:return false
	if absf(t.speed-input.speed)>maxf(3,age*maxf(t.max_accel,t.service_decel)+1):return false
	if not is_equal_approx(t.length,input.length) or not is_equal_approx(t.max_speed,input.max_speed):return false
	var sig: Dictionary=w.next_signal(t)
	return sig.is_empty() or not engine.inhibited_signals.has(sig.id)

func valid(w: RailWorld,engine,p: Dictionary) -> bool:
	if not enabled or p.get("generation",-1)!=_generation or w.time-p.get("time",-INF)>MAX_AGE:return false
	var slow: Train=w.trains.get(p.train);var fast: Train=w.trains.get(p.other)
	if slow==null or fast==null:return false
	for t: Train in [slow,fast]:
		if t.lifecycle!="active" or t.service_complete or t.emergency or t.timetable==null or t.timetable.missed_stop:return false
		if t.path[0].dir!=p.direction or engine.operator_holds.has(t.id) or engine.platform_preferences.has(t.id):return false
		if engine.future_clearances.controls_order(t.id) or w.time<engine._advisory_release_until.get(t.id,-1):return false
		if engine.inhibited_signals.has(w.next_signal(t).get("id","")):return false
		var input: Dictionary=p.get("inputs",{}).get(t.id,{})
		if not input.is_empty() and (t.dispatch_priority!=input.priority or t.automatic==input.manual or not is_equal_approx(t.length,input.length)):return false
		if not input.is_empty() and input.manual and t.speed<input.speed-3:return false
	if fast.dispatch_priority<=slow.dispatch_priority:return false
	if (InputData.chainage(w,slow)-p.chainage)*p.direction>600:return false
	if (InputData.chainage(w,fast)-p.chainage)*p.direction>fast.length+500:return false
	var occ: Dictionary=w.occupancy()
	if _claims_dirty:
		_road_owners=InputData.claims(w);_claims_dirty=false
	for road: String in [p.road,p.passing_road]:
		if not w.graph.edges.has(road):return false
		var owners: Array=p.get("owners",{}).get(road,[])
		var current: String=occ.get(road,"")
		if current not in ["",p.train,p.other] and current not in owners:return false
		if current not in ["",p.train,p.other]:
			var occupant: Train=w.trains.get(current)
			if occupant==null or occupant.emergency or not occupant.automatic or engine.operator_holds.has(current) or w.dispatch_holds.has(current):return false
		var promised: String=engine.future_clearances.owner(road)
		if promised not in ["",p.train,p.other]:return false
		var claimant: String=_road_owners.get(road,"")
		if claimant not in ["",p.train,p.other] and claimant not in owners:return false
	return true

func routes_changed() -> void:_claims_dirty=true

static func overlap(a: Dictionary,b: Dictionary) -> bool:
	if a.get("action","pass")=="follow" or b.get("action","pass")=="follow":return false
	if a.station!=b.station:return false
	if maxf(a.slow_clear,b.slow_clear)>minf(a.fast_clear,b.fast_clear)+60:return false
	for road: String in [a.road,a.passing_road]:
		if road in [b.road,b.passing_road]:return true
	return false

func plan(w: RailWorld,t: Train) -> Dictionary:
	var p: Dictionary=plans.get(t.id,{})
	return p if not p.is_empty() and valid(w,w.dispatcher(),p) else {}

func choice(w: RailWorld,t: Train,other: Train,st: Dictionary) -> int:
	# -1 Classic fallback; 0 do not detain here; 1 planned pass here.
	var p:=plan(w,t)
	if p.is_empty() or other.id not in p.get("participants",[p.other]):return -1
	if p.get("action","pass")=="follow" and (p.chainage-st.s)*p.direction>=0:return 0
	if st.code==p.station:return 1 if other.id==p.other else 0
	if (p.chainage-st.s)*p.direction>0:return 0
	return -1

func can_defer(w: RailWorld,t: Train,hold: Dictionary) -> bool:
	var p:=plan(w,t)
	if p.is_empty() or hold.get("kind","")!="overtake" or hold.get("arrived",false):return false
	if hold.other not in p.get("participants",[p.other]):return false
	var onward: float=(p.chainage-hold.chainage)*p.direction
	if onward<0 or (onward==0 and p.get("action","pass")!="follow"):return false
	var fast: Train=w.trains[hold.other]
	if fast.path.any(func(part):return part.edge.begins_with(hold.station+"_P")):return false
	# A committed arrival for the express fixes this pass's order. Never
	# cancel its route or let the slower train race it out of the station.
	var committed: Array=w.dispatcher()._planner._committed_routes(w,fast)
	if committed.any(func(part):return part.edge.begins_with(hold.station+"_P")):return false
	return true

func maintains(w: RailWorld,t: Train,hold: Dictionary) -> bool:
	var p:=plan(w,t)
	return not p.is_empty() and p.get("action","pass")=="pass" and p.station==hold.station and p.other==hold.other

func road(w: RailWorld,t: Train,station: String) -> String:
	var p:=plan(w,t)
	if not p.is_empty() and p.get("action","pass")=="pass" and p.station==station:return p.road
	for candidate: Dictionary in plans.values():
		if candidate.get("action","pass")=="pass" and candidate.other==t.id and candidate.station==station and valid(w,w.dispatcher(),candidate):return candidate.passing_road
	return ""

func advice(w: RailWorld,t: Train) -> String:
	var p:=plan(w,t)
	if p.is_empty():return ""
	if p.get("action","pass")=="follow":return "Following order retained · no predicted punctuality benefit from an overtake by "+p.other
	return "Planned overtake by %s at %s · %s / %s" % [p.other,p.station,p.road,p.passing_road]

func checkpoint() -> Dictionary:
	var saved:=plans.duplicate(true)
	for p: Dictionary in saved.values():p.erase("generation")
	return {version=1,enabled=enabled,plans=saved,next_refresh=_next_refresh if is_finite(_next_refresh) else 0.0}

func restore(w: RailWorld,data) -> String:
	if not data is Dictionary or data.get("version")!=1 or not data.get("enabled") is bool:return "Invalid predictive dispatcher version or mode"
	if not data.get("plans") is Dictionary or data.plans.size()>256 or not data.get("next_refresh") is float or not is_finite(data.next_refresh):return "Invalid predictive dispatcher state"
	for id in data.plans:
		var p=data.plans[id]
		if not p is Dictionary or id!=p.get("train","") or not w.trains.has(id) or not w.trains.has(p.get("other","")):return "Missing predictive dispatcher participant"
		if p.get("action","") not in ["pass","follow"] or p.get("direction",0) not in [-1,1]:return "Invalid predictive dispatcher order"
		for key in ["road","passing_road"]:
			if not p.get(key) is String or not w.graph.edges.has(p[key]) or p[key].get_slice("_P",0)!=p.get("station",""):return "Invalid predictive receiving road"
		for key in ["time","chainage","slow_clear","fast_entry","fast_clear","margin","wait","cost","created"]:
			if not p.get(key) is float or not is_finite(p[key]):return "Invalid predictive timing"
		if not p.get("inputs") is Dictionary or not p.get("owners") is Dictionary or not p.get("participants") is Array:return "Invalid predictive validation data"
		for actor in p.inputs:
			var input=p.inputs[actor]
			if not w.trains.has(actor) or not input is Dictionary:return "Invalid predictive train input"
			if not input.get("priority") is int or not input.get("manual") is bool or not input.get("length") is float or not input.get("speed") is float:return "Invalid predictive train input"
		for actor in p.participants:
			if not actor is String or not w.trains.has(actor):return "Invalid predictive contender"
		for road_id in p.owners:
			if not w.graph.edges.has(road_id) or not p.owners[road_id] is Array:return "Invalid predictive road owner"
			for owner in p.owners[road_id]:
				if not owner is String:return "Invalid predictive road owner"
	if _worker!=null:_worker.close()
	configure(data.enabled,asynchronous);_generation+=1;_claims_dirty=true
	plans=data.plans.duplicate(true);_next_refresh=data.next_refresh
	for p: Dictionary in plans.values():p.generation=_generation
	return ""
