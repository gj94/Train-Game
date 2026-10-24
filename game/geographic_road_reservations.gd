extends RefCounted
## Exact rendered platform/precinct footprints. Clip the full road ribbon,
## including shoulders and paint; a midpoint cannot protect a wide road.
var cells:={}
var count:=0
func _init(world: RailWorld=null,sites: Dictionary={}) -> void:
	if world==null:return
	# At-grade crossings may meet the rail head; true flyovers pass above OHE.
	# Omit inconsistent map fragments through the intervening train envelope.
	for eid in world.graph.edges:
		var length: float=world.graph.edges[eid].length
		for s in range(0,ceili(length),12):
			var end:=minf(s+12,length)
			var a:=world.graph.position(eid,s);var b:=world.graph.position(eid,end)
			# Include the ballast shoulder and a 35 cm verge clearance. This also
			# covers short chords between the mapped railway's curved samples.
			var ar:=world.graph.tangent(eid,s,1).cross(Vector3.UP)*3.15
			var br:=world.graph.tangent(eid,end,1).cross(Vector3.UP)*3.15
			var ring:=PackedVector2Array()
			for p in [a-ar,b-br,b+br,a+ar]:ring.append(Vector2(p.x,p.z))
			add(ring,maxf(a.y,b.y)+9.05,minf(a.y,b.y)+.52,Vector2(b.x-a.x,b.z-a.z).normalized())
	for station in world.stations:
		for face in preload("res://sim/platform_faces.gd").entries(station):
			var span:=preload("res://sim/berth_clearance.gd").platform_span(world,face.edge)
			for s in range(floori(span.x),ceili(span.y),12):
				var a:=world.graph.position(face.edge,s);var b:=world.graph.position(face.edge,minf(s+12,span.y))
				var r: Vector3=world.graph.tangent(face.edge,s,1).cross(Vector3.UP)*face.platform_side
				var ring:=PackedVector2Array()
				for p in [a+r*1.7,b+r*1.7,b+r*(2.02+face.platform_width+.6),a+r*(2.02+face.platform_width+.6)]:ring.append(Vector2(p.x,p.z))
				add(ring,maxf(a.y,b.y)+7.3) # roof/footbridge; road flyovers may pass above
	var seen:={}
	for zones in sites.values():
		for zone in zones:
			if seen.has(zone.id) or zone.get("access_zone",false):continue
			seen[zone.id]=true
			var ring:=PackedVector2Array()
			for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
				var p: Vector3=zone.centre+zone.basis.x*corner.x*zone.extent.x*.5+zone.basis.z*corner.y*zone.extent.y*.5
				ring.append(Vector2(p.x,p.z))
			add(ring,zone.height+5.0)
			# A flyover can clear an open forecourt, never the station building.
			var building:=PackedVector2Array()
			for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
				var p: Vector3=zone.solid_centre+zone.basis.x*corner.x*(zone.solid_extent.x*.5+.5)+zone.basis.z*corner.y*(zone.solid_extent.y*.5+.5)
				building.append(Vector2(p.x,p.z))
			add(building,INF)
func add(ring: PackedVector2Array,ceiling: float,floor_height: float=-INF,rail_axis: Vector2=Vector2.ZERO) -> void:
	var bounds:=Rect2(ring[0],Vector2.ZERO)
	for p in ring:bounds=bounds.expand(p)
	var item:={id=count,ring=ring,ceiling=ceiling,floor_height=floor_height,bounds=bounds,rail_axis=rail_axis};count+=1
	for x in range(floori(bounds.position.x/64),floori(bounds.end.x/64)+1):
		for z in range(floori(bounds.position.y/64),floori(bounds.end.y/64)+1):
			var key:=Vector2i(x,z)
			if not cells.has(key):cells[key]=[]
			cells[key].append(item)
func near_parallel(ring: PackedVector2Array,origin: Vector3,axis: Vector2) -> bool:
	var offset:=Vector2(origin.x,origin.z);var bounds:=Rect2(ring[0]+offset,Vector2.ZERO)
	for p in ring:bounds=bounds.expand(p+offset)
	axis=axis.normalized()
	for x in range(floori(bounds.position.x/64),floori(bounds.end.x/64)+1):
		for z in range(floori(bounds.position.y/64),floori(bounds.end.y/64)+1):
			for item in cells.get(Vector2i(x,z),[]):
				if bounds.intersects(item.bounds) and absf(axis.dot(item.rail_axis))>.9396926:return true
	return false

func clip(ring: PackedVector2Array,origin: Vector3,minimum_height: float,maximum_height: float=INF,road_axis: Vector2=Vector2.ZERO,crossings: Array=[]) -> Array:
	if maximum_height==INF:maximum_height=minimum_height+.45
	var offset:=Vector2(origin.x,origin.z)
	var bounds:=Rect2(ring[0]+offset,Vector2.ZERO)
	for p in ring:bounds=bounds.expand(p+offset)
	var result:=[ring];var used:={}
	for x in range(floori(bounds.position.x/64),floori(bounds.end.x/64)+1):
		for z in range(floori(bounds.position.y/64),floori(bounds.end.y/64)+1):
			for item in cells.get(Vector2i(x,z),[]):
				var floor_height: float=item.floor_height
				# A road running within 20 degrees of the track is not an at-grade
				# crossing. Keep its full ribbon off the rail/ballast at railhead level.
				# True cross roads, low underpasses and clear flyovers retain their rules.
				var parallel:=road_axis!=Vector2.ZERO and absf(road_axis.normalized().dot(item.rail_axis))>.9396926
				if parallel:floor_height-=1.02
				if used.has(item.id) or minimum_height>item.ceiling or maximum_height<floor_height or not bounds.intersects(item.bounds):continue
				used[item.id]=true
				var local:=PackedVector2Array()
				for p in item.ring:local.append(p-offset)
				var reserved: Array=[local]
				if parallel and maximum_height<item.floor_height:
					for crossing in crossings:
						if absf(crossing.axis.dot(item.rail_axis))>.85 or crossing.height<minimum_height-.35 or crossing.height>maximum_height+.35:continue
						var remainder:=[]
						for part in reserved:remainder.append_array(preload("res://game/geographic_polygon_difference.gd").subtract_convex(part,crossing.ring))
						reserved=remainder
				for reserved_part in reserved:
					var next:=[]
					for part in result:
						var cut:=Geometry2D.clip_polygons(part,reserved_part)
						# Keep the established conservative handling of enclosed
						# obstacles; never triangulate a hole as filled road surface.
						if cut.any(func(p):return Geometry2D.is_polygon_clockwise(p)):continue
						next.append_array(cut)
					result=next
				if result.is_empty():return []
	return result
