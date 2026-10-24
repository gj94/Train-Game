extends RefCounted
## Worker-owned, bounded cache of real shore segments. Tiles share a narrow bank
## halo without sharing mutable geometry, adding water surfaces or altering data.
# Ten metres of bank grading plus the 8 m normal derivative halo. The bank's
# grading/refinement distance remains unchanged; only context is expanded.
const RADIUS:=18.0
const CACHE_LIMIT:=64
var entries:={}
var order:=[]

static func segments(waters: Array) -> Array:
	var result:=[]
	for water in waters:
		var polygons: Array=water.geometry.coordinates if water.geometry.type=="MultiPolygon" else [water.geometry.coordinates]
		for poly in polygons:
			for ring in poly:
				for i in range(1,ring.size()):
					var a:=Vector2(ring[i-1][0],ring[i-1][1]);var b:=Vector2(ring[i][0],ring[i][1])
					# Tile clipping edges are not shores. Hole boundaries are shores.
					if (is_equal_approx(a.x,b.x) and (is_zero_approx(a.x) or is_equal_approx(a.x,512))) or (is_equal_approx(a.y,b.y) and (is_zero_approx(a.y) or is_equal_approx(a.y,512))):continue
					result.append({a=a,b=b,height=water.height})
	return result

func _remember(key: Vector2i,waters: Array) -> void:
	if entries.has(key):return
	var bounded:=[]
	for water in waters:
		var polygons: Array=water.geometry.coordinates if water.geometry.type=="MultiPolygon" else [water.geometry.coordinates]
		var bounds:=Rect2();var first:=true
		for poly in polygons:
			for ring in poly:
				for raw in ring:
					var p:=Vector2(raw[0],raw[1])
					if first:bounds=Rect2(p,Vector2.ZERO);first=false
					else:bounds=bounds.expand(p)
		if not first:bounded.append({geometry=water.geometry,height=water.height,bounds=bounds})
	entries[key]={segments=segments(waters),waters=bounded};order.append(key)
	if order.size()>CACHE_LIMIT:entries.erase(order.pop_front())

func around(geo,key: Vector2i,own_water: Array) -> Array:
	if not entries.has(key):_remember(key,own_water)
	var result:=[]
	var area:=Rect2(Vector2.ZERO,Vector2(512,512)).grow(RADIUS)
	# Absolute tile order is stable for both sides, including equal-distance
	# shore candidates. Cache only segments, not entire neighbouring buildings.
	for x in range(key.x-1,key.x+2):
		for z in range(key.y-1,key.y+2):
			var source:=Vector2i(x,z)
			if not entries.has(source):
				var waters:=[]
				for feature in geo.tile(source).get("features",[]):
					if feature.kind=="water":waters.append({geometry=feature.geometry,height=feature.get("water_height",0.0)})
				_remember(source,waters)
			else:
				# Keep all nine participants alive until border_waters reads them.
				# A FIFO hit could otherwise be evicted by a later missing neighbour.
				order.erase(source);order.append(source)
			var offset:=Vector2(source-key)*512.0
			for segment in entries[source].segments:
				var a: Vector2=segment.a+offset;var b: Vector2=segment.b+offset
				if not area.intersects(Rect2(a,Vector2.ZERO).expand(b),true):continue
				result.append({a=a,b=b,height=segment.height})
	return result

func border_waters(key: Vector2i) -> Array:
	var result:=[]
	var area:=Rect2(Vector2.ZERO,Vector2(512,512)).grow(RADIUS)
	for x in range(key.x-1,key.x+2):
		for z in range(key.y-1,key.y+2):
			var source:=Vector2i(x,z)
			var offset:=Vector2(source-key)*512.0
			for water in entries.get(source,{}).get("waters",[]):
				if area.intersects(Rect2(water.bounds.position+offset,water.bounds.size),true):
					# Keep source-local rings: both neighbours test identical points
					# against identical coordinates, including polygon holes/corners.
					result.append({geometry=water.geometry,height=water.height,offset=offset})
	return result
