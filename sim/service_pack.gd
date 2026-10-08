extends RefCounted
## Portable definitions. Validate in a fresh world; never mutate the live run.
const Corridor := preload("res://sim/layouts/southern_corridor.gd")
const Kerala := preload("res://sim/layouts/kerala_coast.gd")
const FirstLine := preload("res://sim/layouts/first_line.gd")
const Traffic := preload("res://sim/layouts/traffic_service.gd")
const Stock := preload("res://sim/stock/ported_stock.gd")
const Clock := preload("res://sim/world_clock.gd")
const MAX_SERVICES := 64
const MAX_BYTES := 262144

static func layout_id(world: RailWorld) -> String:
	if world.scenery.get("geographic",false): return "kerala_coast"
	return "southern_corridor" if world.scenery.get("corridor", false) else "first_line"

static func blank(layout: String) -> RailWorld:
	if layout == "kerala_coast": return Kerala.build()
	if layout == "southern_corridor": return Corridor.build()
	if layout == "first_line":
		var world := FirstLine.build()
		world.trains.clear()
		return world
	return null

static func signature(world: RailWorld) -> String:
	# Bind the file to track geometry, points, signalling and running directions.
	var parts: Array[String] = []
	var keys := world.graph.edges.keys()
	keys.sort()
	for id in keys:
		var edge: Dictionary = world.graph.edges[id]
		parts.append("%s|%s|%s|%d|%.4f" % [id,edge.a,edge.b,edge.allowed_dir,edge.speed_limit])
		for point in edge.points: parts.append("%.3f,%.3f,%.3f" % [point.x,point.y,point.z])
	keys = world.graph.switches.keys()
	keys.sort()
	for id in keys:
		var sw: Dictionary = world.graph.switches[id]
		parts.append("%s|%s|%s|%s" % [id,sw.trunk,sw.normal,sw.reverse])
	keys = world.signals.keys()
	keys.sort()
	for id in keys:
		var sig: Dictionary = world.signals[id]
		parts.append("%s|%s|%d|%.3f" % [id,sig.edge,sig.dir,sig.s])
	return "\n".join(parts).sha256_text()

static func defaults(layout: String = "southern_corridor") -> Dictionary:
	var world := Kerala.build_traffic() if layout == "kerala_coast" else (Traffic.build() if layout == "southern_corridor" else FirstLine.build_dispatch())
	var services: Array = []
	for train in world.trains.values():
		if not train.stock_kind.begins_with("ported:"):
			var name_before: String=train.service_name
			Stock.configure(train,"lhb")
			train.service_name=name_before
		var schedule = train.timetable
		var stops: Array = []
		for stop in schedule.stops:
			stops.append({name=stop.name,block=stop.block,direction=stop.direction,
				minutes_from_origin=stop.minutes_from_origin,dwell_minutes=stop.dwell_minutes})
			stops[-1].position_m=stop.s
		services.append({id=train.id,name=train.service_name,
			stock=train.stock_kind.trim_prefix("ported:"),
			rake=train.rake_profile,
			speed_limit_kmh=train.max_speed*3.6,
			priority=train.dispatch_priority,
			departure=Clock.format_time(schedule.departure),day=Clock.day(schedule.departure),stops=stops})
	return {format="train-game-services",version=1,layout=layout,
		layout_signature=signature(world),name="My Kerala Coast services" if layout=="kerala_coast" else "My Southern services",
		world_start=Clock.format_time(world.clock_start),day=Clock.day(world.clock_start),services=services}

static func decode(text: String, expected_layout: String = "") -> Dictionary:
	if text.to_utf8_buffer().size() > MAX_BYTES: return _error("Service file exceeds 256 KiB")
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return _error("JSON line %d: %s" % [parser.get_error_line()+1,parser.get_error_message()])
	return build(parser.data,expected_layout)

static func build(data, expected_layout: String = "") -> Dictionary:
	if not data is Dictionary: return _error("The service file must contain an object")
	if data.get("format") != "train-game-services" or data.get("version") != 1:
		return _error("Unsupported format/version; expected train-game-services version 1")
	var layout = data.get("layout","")
	if not layout is String or layout not in ["southern_corridor","first_line","kerala_coast"]:
		return _error("Unknown track layout")
	if expected_layout != "" and layout != expected_layout: return _error("This file belongs to a different track layout")
	var world := blank(layout)
	if data.get("layout_signature","") != signature(world):
		return _error("Track layout has changed; this file's track/signals do not match this layout")
	if not _text(data.get("name",""),100): return _error("Give the timetable a name (1–100 characters)")
	var start = data.get("world_start","")
	if not start is String or Clock.parse_time(start) < 0 or not _day(data.get("day",1)):
		return _error("World start needs HH:MM[:SS] and a day from 1 to 365")
	world.clock_start = (int(data.get("day",1))-1)*Clock.DAY + Clock.parse_time(start)
	var entries = data.get("services",[])
	if not entries is Array or entries.is_empty() or entries.size() > MAX_SERVICES:
		return _error("Create between 1 and %d services" % MAX_SERVICES)
	var occupied := {}
	for definition in entries:
		if not definition is Dictionary: return _error("Every service must be an object")
		var id = definition.get("id","")
		if not _identifier(id): return _error("Service IDs need 1–24 letters, digits, _ or -")
		if world.trains.has(id): return _error("Duplicate service ID: " + id)
		if not _text(definition.get("name",""),100): return _error(id + ": enter a service name")
		var stock = definition.get("stock","")
		if not stock is String or stock not in Stock.CHOICES: return _error(id + ": choose WAP-7 + LHB, WAP-7 + ICF or Vande Bharat 8/16")
		var profile = definition.get("rake", "")
		if not profile is String or Stock.resolve_profile(stock, profile) not in Stock.profiles(stock):
			return _error(id + ": invalid rake for this coach family")
		var stops = definition.get("stops",[])
		if not stops is Array or stops.size() < 2 or stops.size() > 64: return _error(id + ": use 2–64 stops, including origin and destination")
		if layout=="kerala_coast" and stops[0] is Dictionary:
			for station in world.stations:
				if station.get("through_halt",false) and stops[0].get("block","") in station.platform_tracks:
					return _error(id+": start at a station with a departure signal; unsignalled halts can be intermediate stops")
		for stop in stops:
			if not stop is Dictionary: return _error(id + ": each stop must be an object")
			if not _text(stop.get("name",stop.get("block","")),100): return _error(id + ": invalid stop name")
			var block = stop.get("block","")
			if not block is String or not world.graph.edges.has(block): return _error(id + ": unknown stop block " + str(block))
			var direction = stop.get("direction",0)
			if not _number(direction) or float(direction) not in [-1.0,1.0]: return _error(id + ": stop direction must be +1 or -1")
			if not world.graph.allows(block,int(direction)): return _error(id + ": wrong-way stop on " + block)
		if not _day(definition.get("day",1)): return _error(id + ": invalid departure day")
		var train := Train.new(id,1)
		Stock.configure(train,stock,profile)
		var speed=definition.get("speed_limit_kmh",train.max_speed*3.6)
		if not _number(speed) or speed<5 or speed>train.max_speed*3.6+.001:return _error(id+": speed cap must be between 5 km/h and this stock's maximum")
		train.max_speed=float(speed)/3.6
		var priority=definition.get("priority",50)
		if not _number(priority) or priority<1 or priority>100 or priority!=floorf(priority):return _error(id+": priority must be an integer from 1 to 100 (higher runs first)")
		train.dispatch_priority=int(priority)
		# Timetable validates full-length markers before any placement.
		train.path = [{edge=stops[0].block,dir=int(stops[0].direction)}]
		world.trains[id] = train
		var result := world.set_timetable(id,definition)
		if not result.ok: return _error(id + ": " + result.reason)
		var schedule = train.timetable
		for stop in schedule.stops:
			for sig in world.signals.values():
				if sig.edge == stop.block and sig.dir == stop.direction and (sig.s-stop.s)*sig.dir < 1.0:
					return _error(id + ": stop marker must be at least 1 m before " + sig.id)
		if schedule.departure < world.clock_start or schedule.departure > world.clock_start + Clock.DAY:
			return _error(id + ": departure must fall in the 24 hours after world start; adjust its day for midnight")
		if schedule.planned_arrival(schedule.stops.size()-1) > world.clock_start + 2*Clock.DAY:
			return _error(id + ": timetable must finish within 48 hours of world start")
		for i in range(1,schedule.stops.size()):
			var before: Dictionary = schedule.stops[i-1]
			var after: Dictionary = schedule.stops[i]
			if before.block == after.block or not is_finite(world._stop_distance(before.block,before.direction,before.s,after,[])):
				return _error(id + ": no forward route from " + before.block + " to " + after.block + "; automatic reversals are not supported")
		var origin: Dictionary = schedule.stops[0]
		if occupied.has(origin.block): return _error(id + ": origin " + origin.block + " is already occupied by " + occupied[origin.block])
		occupied[origin.block] = id
		world.place_train(train,origin.block,origin.s,origin.direction)
		train.service_name = definition.name
		train.automatic = true
		train.controller = -1.0
		train.status = "Awaiting booked departure and route"
	var normalized: Dictionary = data.duplicate(true)
	normalized.day = int(data.get("day",1))
	for definition in normalized.services:
		definition.rake = world.trains[definition.id].rake_profile
		definition.day = int(definition.get("day",1))
		for i in definition.stops.size():
			var stop: Dictionary = definition.stops[i]
			stop.name = stop.get("name",stop.block)
			stop.dwell_minutes = stop.get("dwell_minutes",1.0 if i>0 and i<definition.stops.size()-1 else 0.0)
	return {ok=true,reason="",world=world,data=normalized}

static func _number(value) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _day(value) -> bool:
	return _number(value) and float(value) == floorf(float(value)) and float(value) >= 1 and float(value) <= 365

static func _text(value, limit: int) -> bool:
	return value is String and not value.strip_edges().is_empty() and value.length() <= limit and not "\n" in value and not "\r" in value and not "[" in value and not "]" in value

static func _identifier(value) -> bool:
	if not _text(value,24): return false
	for character in value:
		if not character in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-": return false
	return true

static func _error(reason: String) -> Dictionary:
	return {ok=false,reason=reason}
