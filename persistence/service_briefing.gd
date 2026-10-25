extends RefCounted
## Read-only menu metadata. Distances follow railway topology between booked markers.
const Clock:=preload("res://sim/world_clock.gd")

static func describe(w: RailWorld,t: Train) -> Dictionary:
	var tt=t.timetable
	var calls:=[];var distance:=0.0
	for i in tt.stops.size():
		var stop: Dictionary=tt.stops[i]
		if i>0:
			var before: Dictionary=tt.stops[i-1]
			var leg:=w._stop_distance(before.block,before.direction,before.s,stop,[])
			if not is_finite(leg) or leg<0:return {}
			distance+=leg
		calls.append({name=stop.name,arrival=tt.planned_arrival(i),departure=tt.planned_departure(i),distance_m=distance})
		if stop.has("boundary"):calls[-1].boundary=stop.boundary
	var duration: float=tt.planned_arrival(tt.stops.size()-1)-tt.departure
	if duration<=0:return {}
	var advice: String=preload("res://sim/priority_dispatch.gd").hold_reason(w,t,true)
	var result:={calls=calls,distance_m=distance,average_kmh=distance/duration*3.6,departure_advice=advice}
	if not t.journey.is_empty():
		result.journey=t.journey.duplicate(true)
		result.passenger_calls=calls.filter(func(c):return not c.has("boundary")).size()
	return result

static func time_text(seconds: float) -> String:
	var day:=floori(seconds/86400)+1
	return Clock.format_time(seconds).left(5)+( " · day %d" % day if day>1 else "")

static func ordered(rows: Array,mode: int) -> Array:
	var result:=rows.duplicate()
	result.sort_custom(func(a,b):
		if mode in [1,2] and a.average_kmh!=b.average_kmh:
			return a.average_kmh>b.average_kmh if mode==1 else a.average_kmh<b.average_kmh
		if mode==3 and a.name!=b.name:return a.name.naturalnocasecmp_to(b.name)<0
		return a.departure<b.departure if a.departure!=b.departure else a.id.naturalnocasecmp_to(b.id)<0)
	return result
