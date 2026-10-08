extends RefCounted
## A stopped train must fit between signals, fouling limits and platform ends.
## Shared by timetable validation, route admission, platform changes and walking.
const POINT_MARGIN := 5.0
const SIGNAL_MARGIN := 6.0
const PLATFORM_MARGIN := 5.0

static func platform_span(w, road: String) -> Vector2:
	var midpoint: float=w.graph.edges[road].length*.5
	var half:=maxf(0,minf(320,midpoint-200))
	return Vector2(midpoint-half,midpoint+half)

static func limits(w, road: String, passenger: bool=true) -> Vector2:
	var edge: Dictionary=w.graph.edges[road]
	var bounds:=Vector2(0,edge.length)
	if w.graph.switches.has(edge.a):bounds.x=w.graph.switches[edge.a].clearance+POINT_MARGIN
	if w.graph.switches.has(edge.b):bounds.y=edge.length-w.graph.switches[edge.b].clearance-POINT_MARGIN
	for direction in [-1,1]:
		for id in w._signals_on.get(w._key(road,direction),[]):
			var sig: Dictionary=w.signals[id]
			if direction==1:bounds.y=minf(bounds.y,sig.s-SIGNAL_MARGIN)
			else:bounds.x=maxf(bounds.x,sig.s+SIGNAL_MARGIN)
	if passenger and w.scenery.get("geographic",false):
		for station in w.stations:
			if road not in station.platform_tracks:continue
			if not station.get("passenger_open",true):return Vector2(1,0)
			if station.platform_details.get(road,{}).get("platform_width",0)<=0:return Vector2(1,0)
			var span:=platform_span(w,road)
			bounds.x=maxf(bounds.x,span.x+PLATFORM_MARGIN)
			bounds.y=minf(bounds.y,span.y-PLATFORM_MARGIN)
			break
	return bounds

static func capacity(w, road: String, passenger: bool=true) -> float:
	var bounds:=limits(w,road,passenger)
	return maxf(0,bounds.y-bounds.x)

static func marker(w, t: Train, road: String, direction: int, passenger: bool=true) -> float:
	var bounds:=limits(w,road,passenger)
	return (bounds.x+bounds.y)*.5+direction*t.length*.5

static func fits(w, t: Train, road: String, head: float, direction: int, passenger: bool=true) -> bool:
	var bounds:=limits(w,road,passenger)
	var tail:=head-direction*t.length
	return minf(head,tail)>=bounds.x-.001 and maxf(head,tail)<=bounds.y+.001

static func reason(w, t: Train, road: String, head: float, direction: int, passenger: bool=true) -> String:
	if fits(w,t,road,head,direction,passenger):return ""
	return "Full train (%.1f m) must fit within %.1f m clear of signals, points and platform ends on %s" % [t.length,capacity(w,road,passenger),road]
