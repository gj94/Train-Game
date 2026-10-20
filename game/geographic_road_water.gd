extends RefCounted
## Tile-local water exclusion for ground-level road ribbons. Islands remain dry;
## tagged culverts/covered drains do not paint open water across the road.
var cells:={}
var count:=0
func _init(features: Array=[]) -> void:
	for feature in features:
		if feature.kind=="water":
			var polygons: Array=feature.geometry.coordinates if feature.geometry.type=="MultiPolygon" else [feature.geometry.coordinates]
			for polygon in polygons:
				if polygon.is_empty():continue
				var rings:=[]
				for raw in polygon:
					var ring:=PackedVector2Array()
					for p in raw:ring.append(Vector2(p[0],p[1]))
					rings.append(ring)
				add(rings[0],rings.slice(1))
		elif feature.kind=="stream" and feature.tags.get("tunnel","no")=="no" and feature.tags.get("covered","no")!="yes":
			var lines: Array=feature.geometry.coordinates if feature.geometry.type=="MultiLineString" else [feature.geometry.coordinates]
			var width:=4.0 if feature.tags.get("waterway")=="river" else 1.2
			for line in lines:
				for i in range(1,line.size()):
					var a:=Vector2(line[i-1][0],line[i-1][1]);var b:=Vector2(line[i][0],line[i][1])
					if a.distance_squared_to(b)<.000001:continue
					var side: Vector2=Vector2(-(b-a).y,(b-a).x).normalized()*width
					add(PackedVector2Array([a-side,b-side,b+side,a+side]),[])
func add(ring: PackedVector2Array,holes: Array) -> void:
	if ring.size()<3:return
	var bounds:=Rect2(ring[0],Vector2.ZERO)
	for p in ring:bounds=bounds.expand(p)
	var item:={id=count,ring=ring,holes=holes,bounds=bounds};count+=1
	for x in range(floori(bounds.position.x/64),floori(bounds.end.x/64)+1):
		for z in range(floori(bounds.position.y/64),floori(bounds.end.y/64)+1):
			var key:=Vector2i(x,z)
			if not cells.has(key):cells[key]=[]
			cells[key].append(item)
func wet(p: Vector2) -> bool:
	for item in cells.get(Vector2i(floori(p.x/64),floori(p.y/64)),[]):
		if Geometry2D.is_point_in_polygon(p,item.ring) and not item.holes.any(func(h):return Geometry2D.is_point_in_polygon(p,h)):return true
	return false
func clip(pieces: Array) -> Array:
	if pieces.is_empty():return []
	var bounds:=Rect2(pieces[0][0],Vector2.ZERO)
	for piece in pieces:
		for p in piece:bounds=bounds.expand(p)
	var result:=pieces;var used:={}
	for x in range(floori(bounds.position.x/64),floori(bounds.end.x/64)+1):
		for z in range(floori(bounds.position.y/64),floori(bounds.end.y/64)+1):
			for item in cells.get(Vector2i(x,z),[]):
				if used.has(item.id) or not bounds.intersects(item.bounds):continue
				used[item.id]=true
				var next:=[]
				for part in result:
					var outside:=Geometry2D.clip_polygons(part,item.ring)
					if not outside.any(func(p):return Geometry2D.is_polygon_clockwise(p)):next.append_array(outside)
					for hole in item.holes:next.append_array(Geometry2D.intersect_polygons(part,hole))
				result=next
	return result
