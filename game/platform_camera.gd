extends RefCounted
## Safe spectator starting point on the nearest open station's rendered platform.
const Surface := preload("res://game/platform_navigation.gd")
static func spectator_point(nav, s: float) -> Dictionary:
	for lateral in [2.02+nav.width*.68,2.9,2.6]:
		for offset in [0.0,.3,-.3,.6,-.6]:
			var p:=Vector2(s+offset,lateral)
			if nav.allowed(p):return {point=p}
	return {}

static func nearest(world: RailWorld, observer: Vector3) -> Dictionary:
	var stations: Array=world.stations.filter(func(st):return st.get("passenger_open",true))
	stations.sort_custom(func(a,b):return a.origin.distance_squared_to(observer)<b.origin.distance_squared_to(observer))
	for station in stations:
		var best: Dictionary={}
		var score:=INF
		for road in station.get("platform_tracks",[]):
			if not station.get("platform_details",{}).has(road):continue
			var nav:=Surface.new(world,road)
			if nav.edge.is_empty():continue
			for s in range(ceili(nav.start+2),floori(nav.end-2),8):
				var landing:=spectator_point(nav,float(s))
				if landing.is_empty():continue
				var eye: Vector3=nav.point(landing.point)+Vector3.UP*1.65
				var d:=eye.distance_squared_to(observer)
				if d<score:
					score=d
					var toward: Vector3=world.graph.position(road,landing.point.x)-eye
					toward.y=0
					var along: Vector3=world.graph.tangent(road,landing.point.x,1)*(1 if landing.point.x<(nav.start+nav.end)*.5 else -1)
					toward=along+toward.normalized()*.4
					best={eye=eye,forward=toward.normalized(),station=station.name,road=road,point=landing.point}
		if not best.is_empty():return best
		# Fictional layouts expose their flat platform rectangles directly.
		for rect: Rect2 in station.get("platforms",[]):
			var p:=Vector2(clampf(observer.x,rect.position.x+2,rect.end.x-2),clampf(observer.z,rect.position.y+1.5,rect.end.y-1.5))
			var eye:=Vector3(p.x,station.origin.y+2.85,p.y)
			var d:=eye.distance_squared_to(observer)
			if d<score:
				score=d
				var toward: Vector3=station.origin-eye;toward.y=0
				if toward.length_squared()<.01:toward=Vector3.FORWARD
				best={eye=eye,forward=toward.normalized(),station=station.name}
		if not best.is_empty():return best
	return {}
