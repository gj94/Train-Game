extends RefCounted
## Immutable station footprints shared by terrain/scenery workers.
static func build(world: RailWorld) -> Dictionary:
	return preload("res://game/station_precinct_plan.gd").build(world)


static func contains(bins: Dictionary,x: float,z: float,margin: float=0,solid: bool=false) -> bool:
	for zone in bins.get(Vector2i(floori(x/512),floori(z/512)),[]):
		var p: Vector3=Vector3(x,zone.centre.y,z)-(zone.solid_centre if solid else zone.centre)
		var size: Vector2=zone.solid_extent if solid else zone.extent
		if absf(p.dot(zone.basis.x))<=size.x*.5+margin and absf(p.dot(zone.basis.z))<=size.y*.5+margin:return true
	return false

static func intersect(bins: Dictionary,ring: PackedVector2Array,origin: Vector3) -> bool:
	if ring.is_empty():return false
	var minimum:=ring[0]+Vector2(origin.x,origin.z)
	var maximum:=minimum
	for point in ring:
		var absolute:=point+Vector2(origin.x,origin.z)
		minimum=minimum.min(absolute);maximum=maximum.max(absolute)
	var candidates:=[]
	for x in range(floori(minimum.x/512),floori(maximum.x/512)+1):
		for z in range(floori(minimum.y/512),floori(maximum.y/512)+1):
			for zone in bins.get(Vector2i(x,z),[]):
				if not candidates.has(zone):candidates.append(zone)
	for zone in candidates:
		var polygon:=PackedVector2Array()
		for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
			var p: Vector3=zone.centre-origin+zone.basis.x*corner.x*zone.extent.x*.5+zone.basis.z*corner.y*zone.extent.y*.5
			polygon.append(Vector2(p.x,p.z))
		if not Geometry2D.intersect_polygons(ring,polygon).is_empty():return true
	return false

static func road_blocked(bins: Dictionary,x: float,z: float,margin: float) -> bool:
	for zone in bins.get(Vector2i(floori(x/512),floori(z/512)),[]):
		if zone.get("access_zone",false):continue
		var p: Vector3=Vector3(x,zone.centre.y,z)-zone.centre
		if absf(p.dot(zone.basis.x))<zone.extent.x*.5+margin and absf(p.dot(zone.basis.z))<zone.extent.y*.5+margin:return true
	return false

static func ground(bins: Dictionary,x: float,z: float,height: float) -> float:
	return preload("res://game/station_precinct_plan.gd").ground(bins,x,z,height)
