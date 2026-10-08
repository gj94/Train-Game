extends RefCounted
## Platform queues and disembarked people remain in railway coordinates on rebases.
const Surface:=preload("res://game/platform_navigation.gd")
var surfaces:={}
var departures:={}


func landing(world, road: String, s: float, side: int, seed_value: int) -> Dictionary:
	var key:=road+"/"+str(side)
	if not surfaces.has(key):surfaces[key]=Surface.new(world,road,side)
	var nav=surfaces[key]
	var entry: Dictionary=nav.landing(s)
	if entry.is_empty():return {}
	var queue: Vector2=entry.point
	for i in 24:
		var candidate:=Vector2(s+float(posmod(seed_value+i,11)-5)*.70,2.9+float(posmod(seed_value+i,3))*.37)
		if nav.allowed(candidate):queue=candidate;break
	return {nav=nav,entry=entry.point,queue=queue}

func remember(key: String, seed_value: int, berth: Dictionary, completed: float, now: float) -> void:
	if departures.has(key) or now-completed>30 or departures.size()>=160:return
	departures[key]={id=seed_value,nav=berth.nav,point=berth.queue,born=completed,updated=now,walk=1.0}

func actors(now: float, origin: Vector3, camera: Vector3) -> Array:
	var result:=[]
	for key in departures.keys():
		var person: Dictionary=departures[key];var age: float=now-person.born
		if age>35:departures.erase(key);continue
		var nav=person.nav
		var point: Vector2=person.point
		var direction:=1.0 if point.x<(nav.start+nav.end)*.5 else -1.0
		var target:=Vector2((nav.start+nav.end)*.5+float(posmod(person.id,9)-4),2.02+nav.width-.5)
		var next: Vector2=nav.move(point,(target-point).normalized()*1.15*clampf(now-person.updated,0,2))
		var elapsed: float=now-person.updated
		person.point=next;person.updated=now
		var position: Vector3=nav.point(next,origin)
		var forward: Vector3=person.get("forward",nav.graph.tangent(nav.edge,next.x,1)*direction)
		if elapsed>0:
			person.walk=1.0 if next.distance_squared_to(point)>.000001 else 0.0
			if person.walk>0:forward=nav.point(next,origin)-nav.point(point,origin)
		person.forward=forward
		if position.distance_squared_to(camera)<10000:
			result.append({pose=Transform3D(Basis.looking_at(forward.normalized()),position),id=person.id,walk=person.walk,seated=false,distance=position.distance_squared_to(camera),fade=clampf((35-age)/5,0,1)})
	return result
