extends RefCounted
## Physical timing probes, not playable or accepted timetables.
## Remove inherited timetable holds without changing calls, dwell or equipment.

static func identity(service: Dictionary) -> String:
	var stops: Array = service.stops.duplicate(true)
	for stop in stops:
		stop.erase("minutes_from_origin")
	return JSON.stringify([service.stock, service.rake, stops]).sha256_text()

static func probe(service: Dictionary) -> Dictionary:
	var result: Dictionary = service.duplicate(true)
	result.departure = "00:03:00"
	result.day = 1
	var offset := 0.0
	for i in result.stops.size():
		if i > 0:
			# A legal, deliberately early timing target prevents the old schedule
			# from holding this measurement train at an otherwise clear station.
			offset += float(result.stops[i-1].dwell_minutes) + 1.0/60.0
		result.stops[i].minutes_from_origin = offset
	return result

static func groups(services: Array) -> Array:
	var by_key: Dictionary = {}
	for service in services:
		var key := identity(service)
		if not by_key.has(key):
			by_key[key] = {key=key, service=service.duplicate(true), ids=[]}
		by_key[key].ids.append(service.id)
	var result: Array = by_key.values()
	var first := ["K1", "S007", "V001", "M013"]
	result.sort_custom(func(a,b):
		var ai: int = first.find(a.service.id)
		var bi: int = first.find(b.service.id)
		for id in first:
			if id in a.ids:ai=first.find(id);break
		for id in first:
			if id in b.ids:bi=first.find(id);break
		return (ai if ai>=0 else 1000)<(bi if bi>=0 else 1000) if ai!=bi else a.service.id<b.service.id)
	return result
