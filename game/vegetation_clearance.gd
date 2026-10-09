extends RefCounted
## Immutable rendered-footprint exclusion shared by scenery workers.
static func build(world: RailWorld):
	var result=preload("res://game/geographic_scenery_occupancy.gd").new()
	for edge in world.graph.edges.values():
		var points: PackedVector3Array=edge.points
		for i in range(1,points.size()):
			result.add_road(Vector2(points[i-1].x,points[i-1].z),Vector2(points[i].x,points[i].z),3.15)
	for station in world.stations:
		for face in preload("res://sim/platform_faces.gd").entries(station):
			var span:=preload("res://sim/berth_clearance.gd").platform_span(world,face.edge)
			for s in range(floori(span.x),ceili(span.y),12):
				var a:=world.graph.position(face.edge,s);var b:=world.graph.position(face.edge,minf(s+12,span.y))
				var right: Vector3=world.graph.tangent(face.edge,s,1).cross(Vector3.UP)*face.platform_side
				var polygon:=PackedVector2Array()
				for p in [a+right*1.9,b+right*1.9,b+right*(2.02+face.platform_width+.3),a+right*(2.02+face.platform_width+.3)]:
					polygon.append(Vector2(p.x,p.z))
				result.add_polygon(polygon,.15)
	for sig in world.signals.values():
		var p:=world.graph.position(sig.edge,sig.s)
		var right:=world.graph.tangent(sig.edge,sig.s,sig.dir).cross(Vector3.UP)
		p+=right*3.3
		result.add_road(Vector2(p.x,p.z),Vector2(p.x,p.z),1.2)
	return result
