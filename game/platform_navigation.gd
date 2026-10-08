extends RefCounted
## Metre-space pedestrian surface matching the geographic platform renderer.
## Position is (distance along the road, distance outward from the track centre).
const RADIUS := .20
var graph: TrackGraph
var edge := ""
var side := 1.0
var width := 0.0
var start := 0.0
var end := 0.0
var obstacles: Array[Rect2] = []

func _init(w: RailWorld, road: String="",requested_side: int=0) -> void:
	graph=w.graph
	if road.is_empty(): return
	var station:=preload("res://sim/priority_dispatch.gd").station(w,road)
	if station.is_empty(): return
	var detail: Dictionary=station.get("platform_details",{}).get(road,{})
	if detail.get("platform_width",0)<=0: return
	if requested_side!=0 and not detail.get("platform_sides",[detail.platform_side]).any(func(value):return is_equal_approx(float(value),float(requested_side))):return
	edge=road;side=detail.platform_side if requested_side==0 else requested_side;width=detail.platform_width
	var midpoint: float=graph.edges[edge].length*.5
	var span:=preload("res://sim/berth_clearance.gd").platform_span(w,road)
	var half: float=(span.y-span.x)*.5
	start=span.x;end=span.y
	var centre:=2.02+width*.5
	var shelter:=48.0 if station.get("through_halt",false) else 180.0
	for s in range(ceili(midpoint-shelter),floori(midpoint+shelter),12):
		obstacles.append(Rect2(s-.08,centre-.08,.16,.16).grow(RADIUS))
		if posmod(s,36)<12: obstacles.append(Rect2(s-.24,centre-1.05,.48,2.1).grow(RADIUS))
	for s in [midpoint-maxf(0,half-28),midpoint+maxf(0,half-28)]:
		for offset in [-2.4,2.4]: obstacles.append(Rect2(s+offset-.07,2.02+width-.57,.14,.14).grow(RADIUS))
	if station.get("through_halt",false): return
	var rng:=RandomNumberGenerator.new();rng.seed=hash(station.code)
	for eid in station.platform_tracks:
		var d: Dictionary=station.platform_details[eid]
		if d.platform_width<=0: continue
		for i in (34 if station.major else 12):
			var s: float=graph.edges[eid].length*.5+rng.randf_range(-240,240)
			var lateral:=rng.randf_range(2.4,2.02+d.platform_width-.3)
			rng.randf() # visual passenger's facing consumes the same draw
			if eid==edge: obstacles.append(Rect2(s-.18,lateral-.18,.36,.36).grow(RADIUS))
	if width>=3:
		# Body, serving counter and crate from scenery_props.py:tea_kiosk.
		var kiosk:=Vector2(midpoint-110,2.02+width*.6)
		obstacles.append(Rect2(kiosk+Vector2(-1.07,-1.85),Vector2(2.4,3.7)).grow(RADIUS))
		obstacles.append(Rect2(kiosk+Vector2(-1.605,-1.775),Vector2(.57,3.55)).grow(RADIUS))
		obstacles.append(Rect2(kiosk+Vector2(-2.41,-side*1.32-.35),Vector2(.62,.7)).grow(RADIUS))

func point(position: Vector2,origin: Vector3=Vector3.ZERO) -> Vector3:
	var right:=graph.tangent(edge,position.x,1).cross(Vector3.UP)
	return graph.position_relative(edge,position.x,origin)+right*side*position.y+Vector3.UP*1.26

func allowed(position: Vector2) -> bool:
	if edge.is_empty() or position.x<start+RADIUS or position.x>end-RADIUS: return false
	if position.y<2.02+RADIUS or position.y>2.02+width-RADIUS: return false
	return not obstacles.any(func(r):return r.has_point(position))

func landing(s: float) -> Dictionary:
	for lateral in [2.6,2.9,3.2]:
		for offset in [0.0,.3,-.3,.6,-.6]:
			var p:=Vector2(s+offset,lateral)
			if allowed(p): return {point=p}
	return {}

func move(position: Vector2,displacement: Vector2) -> Vector2:
	var count:=maxi(1,ceili(displacement.length()/.08))
	var step:=displacement/float(count)
	var p:=position
	for i in count:
		if allowed(p+step): p+=step
		else:
			if allowed(p+Vector2(step.x,0)):p.x+=step.x
			if allowed(p+Vector2(0,step.y)):p.y+=step.y
	return p
