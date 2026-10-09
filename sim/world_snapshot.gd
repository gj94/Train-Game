extends RefCounted
## Versioned, data-only railway checkpoints. Loading constructs an isolated world.
const Pack := preload("res://sim/service_pack.gd")
const Timetable := preload("res://sim/timetable.gd")
const VERSION := 1
const WORLD := ["time","clock_start","protection","signals","depot_reservations","dispatch_notices","dispatch_holds","dispatch_history","events","_event_seq","_next_auto_update"]
const TRAIN := ["id","length","path","head_s","speed","odometer","controller","emergency","automatic","service_name","stock_kind","rake_profile","cab_end","can_change_ends","destination","service_complete","status","depot","passengers","dispatch_priority","mass","max_power","max_accel","max_speed","service_decel","emergency_decel"]
const TIMETABLE := ["departure","stops","index","at_stop","actual_arrivals","actual_departures","missed_stop","passenger_release"]
const DISPATCH := ["enabled","manual_service","hold_maruthur","operator_holds","inhibited_signals","platform_preferences","states","journal","alerts","revision","cycles","_next_tick","_wait_since","_last_state","_advisory_release_until","_seq"]
const FUTURE := ["enabled","plans","_next_search"]

static func signature(w: RailWorld) -> String:
	# Platform faces/clearance and depot inventory affect valid saved movements too.
	var platforms:=[]
	for station in w.stations:
		var row:={}
		for key in ["code","passenger_open","through_halt","platform_tracks","platform_details"]:row[key]=station.get(key)
		platforms.append(row)
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256)
	hash.update(var_to_bytes([Pack.signature(w),platforms,w.depots,w.single_line_sections,w.automatic_signals]))
	return hash.finish().hex_encode()

static func fields(object, names: Array) -> Dictionary:
	var result:={}
	for key in names:result[key]=object.get(key)
	return result.duplicate(true)

static func apply(object, data: Dictionary, names: Array) -> void:
	for key in names:object.set(key,data[key])

static func capture(w: RailWorld, session: Dictionary = {}) -> Dictionary:
	var trains:=[];var switches:={}
	for t: Train in w.trains.values():
		var data:=fields(t,TRAIN)
		data.timetable=fields(t.timetable,TIMETABLE) if t.timetable!=null else null
		data.completed_timetable=fields(t.completed_timetable,TIMETABLE) if t.completed_timetable!=null else null
		data.shared_timetable=t.timetable!=null and t.timetable==t.completed_timetable
		trains.append(data)
	for id in w.graph.switches:switches[id]=w.graph.switches[id].reversed
	return {format="train-game-save",version=VERSION,layout=Pack.layout_id(w),layout_signature=signature(w),
		world=fields(w,WORLD),trains=trains,switches=switches,dispatcher=fields(w.dispatcher(),DISPATCH),
		future=fields(w.dispatcher().future_clearances,FUTURE),session=session.duplicate(true)}

static func restore(data) -> Dictionary:
	if not data is Dictionary or data.get("format")!="train-game-save":return error("This is not a Train Game save")
	if data.get("version")!=VERSION:return error("This save uses an unsupported version")
	if not data.get("layout") is String or data.layout not in ["kerala_coast","southern_corridor","first_line"]:return error("Unknown saved railway")
	if not data.get("world") is Dictionary or not data.get("dispatcher") is Dictionary or not data.get("future") is Dictionary or not data.get("switches") is Dictionary or not data.get("session") is Dictionary:return error("Incomplete save")
	if not data.get("trains") is Array or data.trains.is_empty() or data.trains.size()>64:return error("Invalid saved service list")
	data=data.duplicate(true) # Restoring/stepping must never mutate the checkpoint.
	var w:=Pack.blank(data.layout)
	if data.get("layout_signature")!=signature(w):return error("The track, platforms or signalling layout has changed; this save cannot be resumed in this build")
	if not matches(w,data.world,WORLD) or not matches(w.dispatcher(),data.dispatcher,DISPATCH) or not matches(w.dispatcher().future_clearances,data.future,FUTURE):return error("Invalid railway state")
	if not is_finite(data.world.time) or data.world.time<0 or not is_finite(data.world.clock_start):return error("Invalid saved clock")
	if data.switches.size()!=w.graph.switches.size() or data.world.signals.size()!=w.signals.size():return error("Incomplete points or signals")
	for id in data.switches:
		if not w.graph.switches.has(id) or not data.switches[id] is bool:return error("Invalid saved points")
		w.graph.switches[id].reversed=data.switches[id]
	w.trains.clear()
	for entry in data.trains:
		if not entry is Dictionary or not entry.get("id") is String or entry.id.is_empty() or w.trains.has(entry.id):return error("Invalid or duplicate train")
		var t:=Train.new(entry.id,1)
		if not matches(t,entry,TRAIN):return error("Incomplete train "+entry.id)
		for key in ["length","head_s","speed","odometer","controller","mass","max_power","max_accel","max_speed","service_decel","emergency_decel"]:
			if not is_finite(entry[key]):return error("Invalid train physics")
		if entry.length<=0 or entry.mass<=0 or entry.max_speed<=0 or entry.service_decel<=0 or entry.emergency_decel<=0 or entry.speed<0 or absf(entry.controller)>1:return error("Invalid train controls")
		if not valid_path(w,entry.path) or entry.head_s<0 or entry.head_s>w.graph.edges[entry.path[0].edge].length+.001:return error("Invalid occupied track for "+entry.id)
		if not entry.stock_kind.begins_with("ported:") or entry.stock_kind.trim_prefix("ported:") not in preload("res://sim/stock/ported_stock.gd").CHOICES:return error("Unsupported saved rolling stock")
		var stock=preload("res://sim/stock/ported_stock.gd")
		if stock.resolve_profile(entry.stock_kind.trim_prefix("ported:"),entry.rake_profile) not in stock.profiles(entry.stock_kind.trim_prefix("ported:")):return error("Invalid saved rake")
		apply(t,entry,TRAIN)
		# R20 and earlier built-in K1 saves retain the retired scenario cap.
		# Authored packs (including deliberately slower services) remain untouched.
		if _legacy_passenger_cap(data,t):t.max_speed=110.0/3.6
		for key in ["timetable","completed_timetable"]:
			if not entry.has(key):return error("Missing saved timetable")
			if entry[key]==null:continue
			var tt:=Timetable.new()
			if not valid_timetable(w,entry[key],tt):return error("Invalid timetable for "+t.id)
			apply(tt,entry[key],TIMETABLE);t.set(key,tt)
		if entry.get("shared_timetable",false):t.completed_timetable=t.timetable
		w.trains[t.id]=t
	for id in data.world.signals:
		if not w.signals.has(id) or not data.world.signals[id] is Dictionary:return error("Unknown saved signal")
		var saved: Dictionary=data.world.signals[id];var original: Dictionary=w.signals[id]
		for key in original:
			if not saved.has(key) or typeof(saved[key])!=typeof(original[key]):return error("Invalid signal state")
		for key in ["id","edge","dir","s"]:
			if saved[key]!=original[key]:return error("Signal geometry differs")
		if not saved.owner.is_empty() and not w.trains.has(saved.owner):return error("Missing route owner")
		if not saved.destination.is_empty() and not w.signals.has(saved.destination) and not (saved.destination.begins_with("BUFFER:") and w.graph.nodes.has(saved.destination.trim_prefix("BUFFER:"))):return error("Unknown route destination")
		if not saved.route.is_empty() and not valid_path(w,saved.route):return error("Invalid locked route")
	for id in data.world.dispatch_holds:
		var hold=data.world.dispatch_holds[id]
		if not w.trains.has(id) or not hold is Dictionary or not w.trains.has(hold.get("other","")) or hold.get("kind","") not in ["crossing","overtake"]:return error("Invalid dispatch commitment")
	for road in data.world.depot_reservations:
		if not w.depots.has(road) or not w.trains.has(data.world.depot_reservations[road]):return error("Invalid depot reservation")
	for plan in data.future.plans:
		if not plan is Dictionary:return error("Invalid future clearance")
		for key in ["incoming","opponent","vacater"]:
			if not w.trains.has(plan.get(key,"")):return error("Missing future-clearance participant")
		for key in ["future_road","opponent_road","escape_road"]:
			if not w.graph.edges.has(plan.get(key,"")):return error("Missing future-clearance road")
	apply(w,data.world,WORLD)
	apply(w.dispatcher(),data.dispatcher,DISPATCH)
	apply(w.dispatcher().future_clearances,data.future,FUTURE)
	return {ok=true,reason="",world=w,session=data.session.duplicate(true)}

static func matches(object, data: Dictionary, names: Array) -> bool:
	for key in names:
		if not data.has(key) or typeof(data[key])!=typeof(object.get(key)):return false
	return true

static func _legacy_passenger_cap(data: Dictionary, t: Train) -> bool:
	var session: Dictionary=data.session
	if session.get("authored_pack",true)!=false:return false
	var meta=session.get("meta",{})
	if not meta is Dictionary or meta.has("service_pack"):return false
	return data.layout=="kerala_coast" and t.id=="K1" and t.stock_kind=="ported:icf" and t.rake_profile=="passenger" and is_equal_approx(t.max_speed,65.0/3.6)

static func valid_path(w: RailWorld, path) -> bool:
	if not path is Array or path.is_empty() or path.size()>w.graph.edges.size():return false
	for seg in path:
		if not seg is Dictionary or not w.graph.edges.has(seg.get("edge","")) or seg.get("dir",0) not in [-1,1]:return false
	return true

static func valid_timetable(w: RailWorld, data, tt) -> bool:
	if not data is Dictionary or not matches(tt,data,TIMETABLE):return false
	if data.stops.size()<2 or data.stops.size()>64 or data.index<0 or data.index>=data.stops.size():return false
	if data.actual_arrivals.size()!=data.stops.size() or data.actual_departures.size()!=data.stops.size():return false
	for stop in data.stops:
		if not stop is Dictionary or not w.graph.edges.has(stop.get("block","")) or stop.get("direction",0) not in [-1,1]:return false
		if not stop.get("name") is String:return false
		for key in ["s","minutes_from_origin","dwell_minutes"]:
			if not (stop.get(key) is float or stop.get(key) is int) or not is_finite(float(stop[key])) or stop[key]<0:return false
	return true

static func error(reason: String) -> Dictionary:
	return {ok=false,reason=reason}
