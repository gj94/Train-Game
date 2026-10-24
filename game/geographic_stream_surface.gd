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
			var previous:=Vector2.ZERO
			var width:=4.0 if feature.tags.get("waterway")=="river" else 1.2
			for i in range(1,line.size()):
				var a: Vector2=line[i-1];var b: Vector2=line[i]
				if a.distance_squared_to(b)<.000001:continue
				var side: Vector2=(b-a).normalized().orthogonal()*width
				if previous!=Vector2.ZERO:
					for sign_value in [-1,1]:
						project(c,PackedVector2Array([a,a+previous*sign_value,a+side*sign_value]))
				# Short footprints bound terrain-cell work even for diagonal OSM ways.
				# Project every patch on the actual fine/coarse triangles, avoiding
				# long endpoint chords suspended above the land or buried in hills.
				var count:=maxi(1,ceili(a.distance_to(b)/8.0))
				for j in count:
					var start:=a.lerp(b,j/float(count));var end:=a.lerp(b,(j+1)/float(count))
					project(c,PackedVector2Array([start-side,end-side,end+side,start+side]))
				previous=side

static func project(c,ring: PackedVector2Array) -> void:
	var area:=0.0
	for i in ring.size():area+=ring[i].cross(ring[(i+1)%ring.size()])
	if absf(area)<.000001:return
	for tri: PackedVector3Array in preload("res://game/geographic_ground_ribbon.gd").project(c,ring,.04):
		c.batch.triangle("water",tri[0],tri[1],tri[2],Vector3.UP)
