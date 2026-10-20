extends RefCounted
## Gate-to-road links. No invented road may cross a station building or railway.
static func candidates(zone: Dictionary,data,a: Vector2,b: Vector2,way: String="") -> Array:
	var result:=[]
	var inverse: Basis=zone.basis.inverse()
	var base:=Vector3(zone.building.x,0,zone.building.z)
	var local_a: Vector3=inverse*(Vector3(a.x,0,a.y)-base)
	var local_b: Vector3=inverse*(Vector3(b.x,0,b.y)-base)
	var delta: Vector3=local_b-local_a
	var gates:=[Vector2(0,zone.outer),Vector2(-zone.half,zone.front-8.8),Vector2(zone.half,zone.front-8.8)]
	for index in gates.size():
		var gate: Vector2=gates[index]
		var start: Vector3=zone.building+zone.basis*Vector3(gate.x,.055,gate.y)
		var parameters:=[0.0,1.0,clampf((Vector2(start.x,start.z)-a).dot(b-a)/maxf(.001,a.distance_squared_to(b)),0,1)]
		# Also test where a long road crosses the station's exclusion margin.
		if absf(delta.x)>.01:
			for side in [-1,1]:parameters.append((side*(zone.half+12)-local_a.x)/delta.x)
		if absf(delta.z)>.01:parameters.append((zone.outer-12-local_a.z)/delta.z)
		for t: float in parameters:
			if t<0 or t>1:continue
			var local: Vector3=local_a.lerp(local_b,t)
			if index==0 and (local.z>zone.outer-4 or absf(local.x)>zone.half):continue
			if index>0 and (local.x*(1 if index==2 else -1)<zone.half+4 or local.z>zone.front+3):continue
			var at:=a.lerp(b,t)
			var distance:=Vector2(start.x,start.z).distance_to(at)
			if distance<4 or distance>80:continue
			var end:=Vector3(at.x,data.ground_at(at.x,at.y)+.065,at.y)
			if not way.is_empty() and data.road_profiles!=null:
				var profile: Dictionary=data.road_profiles.sample(way,at)
				# Entrance spurs connect to roads on the ground, not to the
				# underside of a flyover or a raised approach on the same way.
				if not profile.is_empty():
					if profile.bridge or absf(profile.height-end.y)>.2:continue
					end.y=profile.height
			if absf(end.y-start.y)/distance>.10:continue
			result.append({a=start,b=end,distance=distance,gate=index})
	return result

static func clear_links(options: Array,features: Array,origins: Array,rail_clearance=null) -> Array:
	var occupancy=preload("res://game/geographic_scenery_occupancy.gd").new()
	for i in features.size():
		var feature: Dictionary=features[i]
		if feature.kind=="stream" and feature.tags.get("tunnel","no")=="no" and feature.tags.get("covered","no")!="yes":
			var lines: Array=feature.geometry.coordinates if feature.geometry.type=="MultiLineString" else [feature.geometry.coordinates]
			for line in lines:
				for j in range(1,line.size()):
					occupancy.add_road(Vector2(line[j-1][0],line[j-1][1])+origins[i],Vector2(line[j][0],line[j][1])+origins[i],4.0 if feature.tags.get("waterway")=="river" else 1.2)
			continue
		if feature.kind not in ["building","water"]:continue
		var polygons: Array=feature.geometry.coordinates if feature.geometry.type=="MultiPolygon" else [feature.geometry.coordinates]
		for polygon in polygons:
			if polygon.is_empty():continue
			var ring:=PackedVector2Array()
			for v in polygon[0]:ring.append(Vector2(v[0],v[1])+origins[i])
			occupancy.add_polygon(ring)
	options.sort_custom(func(a,b):return a.distance<b.distance)
	var accepted:=[];var used:=[];var attempts:={}
	for option in options:
		if option.gate in used or attempts.get(option.gate,0)>=48:continue
		attempts[option.gate]=attempts.get(option.gate,0)+1
		var a:=Vector2(option.a.x,option.a.z);var b:=Vector2(option.b.x,option.b.z)
		var clear:=true
		var count:=maxi(2,ceili(option.distance/2))
		for j in range(1,count+1):
			var p:=a.lerp(b,float(j)/count)
			if not occupancy.clear(p,3.2) or (rail_clearance!=null and not rail_clearance.clear_point(Vector3(p.x,0,p.y),6.5)):clear=false;break
		if clear:
			used.append(option.gate)
			accepted.append([option.a,option.b])
	return accepted
