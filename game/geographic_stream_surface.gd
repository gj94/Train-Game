extends RefCounted
## OSM often supplies a canal centreline and a water polygon for the same
## waterway. Keep one surface there, preserving streams through polygon holes.
static func uncovered(c,line: Array) -> Array:
	var points:=PackedVector2Array()
	for p in line:points.append(Vector2(p[0],p[1]))
	if points.size()<2:return []
	var pieces:=[points]
	for water in c.water_levels:
		var polygons: Array=water.geometry.coordinates if water.geometry.type=="MultiPolygon" else [water.geometry.coordinates]
		for polygon in polygons:
			if polygon.is_empty():continue
			var outer:=PackedVector2Array()
			for p in polygon[0]:outer.append(Vector2(p[0],p[1]))
			var next:=[]
			for piece in pieces:
				next.append_array(Geometry2D.clip_polyline_with_polygon(piece,outer))
				for raw in polygon.slice(1):
					var hole:=PackedVector2Array()
					for p in raw:hole.append(Vector2(p[0],p[1]))
					next.append_array(Geometry2D.intersect_polyline_with_polygon(piece,hole))
			pieces=next
			if pieces.is_empty():return []
	return pieces

static func draw(c,feature: Dictionary) -> void:
	if feature.tags.get("tunnel","no")!="no" or feature.tags.get("covered","no")=="yes":return
	for raw in c._lines(feature.geometry):
		for line in uncovered(c,raw):
			for i in range(1,line.size()):
				var a:=Vector3(line[i-1].x,0,line[i-1].y);var b:=Vector3(line[i].x,0,line[i].y)
				if a.distance_squared_to(b)<.000001:continue
				a.y=c._ground(a.x,a.z)+.09;b.y=c._ground(b.x,b.z)+.09
				var side: Vector3=(b-a).normalized().cross(Vector3.UP)*(4.0 if feature.tags.get("waterway")=="river" else 1.2)
				c.batch.quad("water",a-side,b-side,b+side,a+side,Vector3.UP)
