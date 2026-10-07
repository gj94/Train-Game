extends RefCounted
## BODY V2 website acoustic rules. Pure calculations, no players or scene state.
const Data := preload("res://game/body_v2_data.gd")
const Layout := preload("res://game/rail_joint_layout.gd")

static func falloff(distance: float, capped: bool = true) -> float:
	var d := minf(distance, Data.MAX_DISTANCE) if capped else distance
	return Data.REF_DISTANCE / (Data.REF_DISTANCE + Data.ROLLOFF * (maxf(Data.REF_DISTANCE, d) - Data.REF_DISTANCE))

static func stereo(source: Vector3, listener: Vector3, forward: Vector3, up: Vector3 = Vector3.UP) -> Vector2:
	var d := source - listener
	var front := forward.normalized()
	var right := front.cross(up).normalized()
	var azimuth := rad_to_deg(atan2(d.dot(right), d.dot(front)))
	if azimuth > 90.0: azimuth = 180.0 - azimuth
	if azimuth < -90.0: azimuth = -180.0 - azimuth
	var angle := (azimuth + 90.0) / 180.0 * PI / 2.0
	return Vector2(cos(angle), sin(angle)) * falloff(d.length())

static func normalizer(distances: Array) -> float:
	var largest := 0.0
	var power := 0.0
	for distance in distances:
		var weight := falloff(distance, false)
		largest = maxf(largest, weight)
		power += weight * weight
	return largest / maxf(.001, sqrt(power))

static func rolling_pitch(radial_speed: float) -> float:
	return Data.SOUND_SPEED / (Data.SOUND_SPEED + radial_speed * Data.DOPPLER)

static func propagation(source: Vector3, listener: Vector3) -> float:
	return Vector2(source.x-listener.x, source.z-listener.z).length() / Data.SOUND_SPEED

static func variant(vehicle: int, bogie: int, axle: int) -> int:
	return posmod(vehicle * 3 + bogie * 2 + axle, 8)

static func axle_load(vehicle: int, bogie: int, axle: int, locomotive: bool) -> float:
	return 1.22 if locomotive else .9 + posmod(maxi(vehicle-1,0)*7 + bogie*3 + axle,9)*.025

static func describe(axles: Array) -> Dictionary:
	var groups := {}
	var identities := []
	identities.resize(axles.size())
	for i in axles.size():
		var a: Dictionary = axles[i]
		var key := "%d:%d" % [a.car, floori(a.cls/2.0)]
		if not groups.has(key): groups[key] = []
		groups[key].append(i)
	var bogies := []
	for key in groups:
		var indices: Array = groups[key]
		indices.sort_custom(func(a,b): return axles[a].x < axles[b].x)
		var center := 0.0
		for order in indices.size():
			var index: int = indices[order]
			var a: Dictionary = axles[index]
			var bogie := floori(a.cls/2.0)
			identities[index] = {variant=variant(a.car,bogie,order), load=axle_load(a.car,bogie,order,indices.size()==3), order=order}
			center += a.x
		bogies.append({x=center/indices.size(), car=axles[indices[0]].car})
	return {axles=identities,bogies=bogies}

## Project onto polylines first, then choose one existing visible rail gap.
static func listening_joint(graph: TrackGraph, focus: Vector3) -> Dictionary:
	var best := {}
	var best_distance := INF
	var candidates: Array=[]
	for edge in graph.edges:
		var e: Dictionary=graph.edges[edge]
		var bound: AABB=e.bounds
		var nearest:=focus.clamp(bound.position,bound.end)
		candidates.append({edge=edge,score=focus.distance_squared_to(nearest)})
	candidates.sort_custom(func(a,b): return a.score<b.score)
	for candidate in candidates:
		if candidate.score>best_distance: break
		var edge: String=candidate.edge
		var e: Dictionary = graph.edges[edge]
		if e.length <= Layout.OFFSET: continue
		for segment in range(e.points.size()-1):
			var a: Vector3 = e.points[segment]
			var d: Vector3 = e.points[segment+1]-a
			var fraction := clampf((focus-a).dot(d)/maxf(.0001,d.length_squared()),0.0,1.0)
			var projected: Vector3 = a+d*fraction
			var s: float = e.cum[segment] + d.length()*fraction
			var k := clampi(roundi((s-Layout.OFFSET)/Layout.SPACING),0,ceili((e.length-Layout.OFFSET)/Layout.SPACING)-1)
			var point := graph.position(edge,Layout.OFFSET+k*Layout.SPACING)
			var score := focus.distance_squared_to(point)
			if score < best_distance:
				best_distance = score
				best = {edge=edge,joint=k,point=point,projected=projected,tangent=d.normalized()}
	return best
