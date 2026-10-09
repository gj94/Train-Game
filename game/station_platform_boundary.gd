extends RefCounted
## Boundaries on outer platforms only; islands and entrances stay unobstructed.
static func outer_face(station: Dictionary,face: Dictionary) -> bool:
	var position: float=face.get("offset",0)+face.platform_side*(2.02+face.platform_width)
	for road in station.operating_roads:
		if (road.offset-position)*face.platform_side>0:return false
	return true

static func draw(batch,geo,world: RailWorld,station: Dictionary,origin: Vector3) -> void:
	var sites=preload("res://game/coastal_station_sites.gd")
	for face in preload("res://sim/platform_faces.gd").entries(station):
		if not outer_face(station,face):continue
		var span:=preload("res://sim/berth_clearance.gd").platform_span(world,face.edge)
		for s in range(ceili(span.x+4),floori(span.y-4),3):
			var a:=world.graph.position_relative(face.edge,s,origin)
			var b:=world.graph.position_relative(face.edge,minf(s+3,span.y-4),origin)
			var right:=world.graph.tangent(face.edge,s,1).cross(Vector3.UP)
			var shift: Vector3=right*face.platform_side*(2.02+face.platform_width-.14)
			a+=shift;b+=shift
			var mid: Vector3=(a+b)*.5+origin
			if sites.contains(geo.station_sites,mid.x,mid.z,3):continue
			preload("res://game/station_boundary_mesh.gd").section(batch,a+Vector3.UP*1.26,b+Vector3.UP*1.26)
