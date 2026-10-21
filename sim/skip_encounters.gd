extends RefCounted
## Detect the START of a physical side-by-side pass, so the warning precedes the
## first coach rather than waiting for two long rakes' centres/tails to clear.
## Birth/depot/reversal and an already-overlapping pair never fabricate a pass.
const MapState := preload("res://sim/skip_map_state.gd")
var previous := {}

func sample(w: RailWorld, service: String) -> Array:
	var result:=[];var present:={}
	if not w.trains.has(service):previous.clear();return result
	var own: Train=w.trains[service]
	if own.lifecycle!="active" or own.service_complete:previous.clear();return result
	var a:=row(w,own)
	for other: Train in w.active_trains():
		if other.id==service or other.service_complete or not other.depot.is_empty():continue
		var b:=row(w,other);var key:=other.id;present[key]=true
		var gap:=separation(a,b)
		var old: Dictionary=previous.get(key,{})
		if not old.is_empty() and old.a.direction==a.direction and old.b.direction==b.direction and old.gap>0 and gap<=0:
			# Crossing the same longitudinal point on unrelated branches is not a
			# visible encounter. Our corridor/yard has nearby parallel roads.
			if absf(a.lateral-b.lateral)<=90 and not own.path.any(func(seg):return other.path.any(func(s):return s.edge==seg.edge)):
				var fraction:=clampf(old.gap/(old.gap-gap),0,1)
				var at:=lerpf(old.clock,w.clock_seconds(),fraction)
				var kind: String="crossing" if a.direction!=b.direction else ("overtaking" if (old.a.head-old.b.head)*a.direction<0 else "overtaken")
				result.append({kind=kind,other=other.id,name=other.service_name,time=at})
		previous[key]={a=a,b=b,gap=gap,clock=w.clock_seconds()}
	for key in previous.keys():
		if not present.has(key):previous.erase(key)
	return result

static func row(w: RailWorld, t: Train) -> Dictionary:
	var head:=MapState.point(w,t.path[0].edge,t.head_s)
	var tail: Dictionary=t.locate_behind(w.graph,t.length)
	var rear:=MapState.point(w,tail.edge,tail.s)
	var direction:=signf(head.x-rear.x)
	if direction==0:direction=t.path[0].dir
	return {head=head.x,tail=rear.x,lateral=head.y,direction=direction,lo=minf(head.x,rear.x),hi=maxf(head.x,rear.x)}

static func separation(a: Dictionary,b: Dictionary) -> float:
	return maxf(b.lo-a.hi,a.lo-b.hi)
