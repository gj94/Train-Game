extends RefCounted
## Immutable station footprints shared by terrain/scenery workers.
const Placement:=preload("res://game/coastal_station_placement.gd")
static func build(world: RailWorld) -> Dictionary:
	var bins:={}
	for station in world.stations:
		if not Placement.available(station.code):continue
		var code:=Placement.asset_code(station.code).to_lower()
		var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/ported/station_"+code+"_detail/provenance.json"))
		var site:=Placement.site(world,station,Vector3.ZERO)
		var assembly:=Placement.layout(site.position,site.forward,site.right,source.source_bounds,source.placement)
		var size: Vector2=assembly.footprint
		var p: Vector3=assembly.position
		var right: Vector3=assembly.basis.z
		var yard: bool=not station.get("through_halt",false)
		var centre: Vector3=p-right*(15 if yard else 0)
		var extent:=Vector2(maxf(size.x,100 if yard else 0)+4,size.y+(32 if yard else 4))
		var zone:={centre=centre,basis=assembly.basis,extent=extent,solid_centre=p,solid_extent=size+Vector2.ONE*2,height=p.y-.10,code=station.code}
		var radius:=extent.length()*.5+15
		for x in range(floori((centre.x-radius)/512),floori((centre.x+radius)/512)+1):
			for z in range(floori((centre.z-radius)/512),floori((centre.z+radius)/512)+1):
				var key:=Vector2i(x,z)
				if not bins.has(key):bins[key]=[]
				bins[key].append(zone)
	return bins

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

static func ground(bins: Dictionary,x: float,z: float,height: float) -> float:
	for zone in bins.get(Vector2i(floori(x/512),floori(z/512)),[]):
		var p: Vector3=Vector3(x,zone.centre.y,z)-zone.centre
		if absf(p.dot(zone.basis.x))<=zone.extent.x*.5 and absf(p.dot(zone.basis.z))<=zone.extent.y*.5:
			return minf(height,zone.height)
	return height
