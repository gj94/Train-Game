extends RefCounted
## Short, in-memory rollback only. No layout reconstruction or presentation rebinding.
## Called exclusively by the simulation owner BETWEEN complete world.step batches.
const Snapshot := preload("res://sim/world_snapshot.gd")
const EXTRA := ["_next_service_entry","_point_revision"]
var _passenger_cache := {}

func capture(w: RailWorld) -> Dictionary:
	assert(not w._within_step)
	var trains:={};var switches:={}
	for t: Train in w.trains.values():
		var keys: Array=Snapshot.TRAIN.duplicate();keys.erase("passengers")
		var data:=Snapshot.fields(t,keys+Snapshot.ARRIVAL)
		# Passenger seats/events are large and immutable between exchanges. Share
		# OUR detached copy until the exchange state changes; never share live data.
		var p: Dictionary=t.passengers
		var stamp: Array=[p.get("revision",-1),p.get("elapsed",-1),p.get("phase",""),p.get("visit",-1)]
		if not _passenger_cache.has(t.id) or _passenger_cache[t.id].stamp!=stamp:
			_passenger_cache[t.id]={stamp=stamp,value=p.duplicate(true)}
		data.passengers=_passenger_cache[t.id].value
		data.tables=[]
		for tt in [t.timetable,t.completed_timetable]:
			data.tables.append({object=tt,state=Snapshot.fields(tt,Snapshot.TIMETABLE)} if tt!=null else {})
		trains[t.id]=data
	for id in w.graph.switches:switches[id]=w.graph.switches[id].reversed
	return {clock=w.clock_seconds(),world=Snapshot.fields(w,Snapshot.WORLD+EXTRA),trains=trains,switches=switches,
		dispatch=Snapshot.fields(w.dispatcher(),Snapshot.DISPATCH),future=Snapshot.fields(w.dispatcher().future_clearances,Snapshot.FUTURE),
		predictive=w.dispatcher().predictive.checkpoint()}

func restore(w: RailWorld, state: Dictionary) -> void:
	assert(not w._within_step and w.trains.size()==state.trains.size())
	Snapshot.apply(w,state.world.duplicate(true),Snapshot.WORLD+EXTRA)
	for id in state.trains:
		var t: Train=w.trains[id];var data: Dictionary=state.trains[id]
		Snapshot.apply(t,data.duplicate(true),Snapshot.TRAIN+Snapshot.ARRIVAL)
		for i in 2:
			var table: Dictionary=data.tables[i]
			var tt=table.get("object")
			t.set("timetable" if i==0 else "completed_timetable",tt)
			if tt!=null:Snapshot.apply(tt,table.state.duplicate(true),Snapshot.TIMETABLE)
	for id in state.switches:w.graph.switches[id].reversed=state.switches[id]
	Snapshot.apply(w.dispatcher(),state.dispatch.duplicate(true),Snapshot.DISPATCH)
	Snapshot.apply(w.dispatcher().future_clearances,state.future.duplicate(true),Snapshot.FUTURE)
	var predictive_issue: String=w.dispatcher().predictive.restore(w,state.predictive)
	assert(predictive_issue.is_empty(),predictive_issue)
	# Retain topology-only caches, discard everything containing future occupancy,
	# claims or mutable signal references. These are rebuilt by ordinary queries.
	w._cache_occupancy=false;w._cached_occupancy.clear();w._active_trains.clear()
	w._route_signals.clear();w._claims_dirty=true;w._step_route_directions.clear()
	w._auto_direction_snapshot.clear();w._updating_automatic=false
	for sig in w.signals.values():
		if not sig.route.is_empty():w._route_signals[sig.id]=sig
	w.dispatcher()._planner._claim_cache.clear();w.dispatcher()._planner._approach_cache.clear()
	w.dispatcher().future_clearances._planner._claim_cache.clear()
	w.dispatcher().future_clearances._planner._approach_cache.clear()
	_passenger_cache.clear()
