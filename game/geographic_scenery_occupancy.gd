extends RefCounted
## Tile-local broad phase prevents reconstructed planting from covering mapped
## houses, roads and water. Immutable after build; each streaming worker owns it.
var cells:={}
var _next_item:=0
func add_polygon(ring: PackedVector2Array,margin: float=0.0) -> void:
	if ring.size()<3:return
	var bounds:=Rect2(ring[0],Vector2.ZERO)
	for p in ring:bounds=bounds.expand(p)
	var item:={ring=ring,bounds=bounds,margin=margin}
	_insert(item,bounds.grow(margin+6))
func add_road(a: Vector2,b: Vector2,half_width: float) -> void:
	_insert({a=a,b=b,width=half_width},Rect2(a,Vector2.ZERO).expand(b).grow(half_width+6))
func _insert(item: Dictionary,bounds: Rect2) -> void:
	item.query_id=_next_item;_next_item+=1
	item.query_bounds=bounds
	for x in range(floori(bounds.position.x/32),floori(bounds.end.x/32)+1):
		for z in range(floori(bounds.position.y/32),floori(bounds.end.y/32)+1):
			var key:=Vector2i(x,z)
			if not cells.has(key):cells[key]=[]
			cells[key].append(item)
func clear(p: Vector2,radius: float) -> bool:
	# Radius <=6 is registered in each item's broad phase.
	assert(radius<=6)
	for item in cells.get(Vector2i(floori(p.x/32),floori(p.y/32)),[]):
		if item.has("ring"):
			if not item.bounds.grow(radius+item.margin).has_point(p):continue
			if Geometry2D.is_point_in_polygon(p,item.ring):return false
			for i in item.ring.size():
				if distance(p,item.ring[i],item.ring[(i+1)%item.ring.size()])<radius+item.margin:return false
		elif distance(p,item.a,item.b)<radius+item.width:return false
	return true
static func distance(p: Vector2,a: Vector2,b: Vector2) -> float:
	return p.distance_to(a.lerp(b,clampf((p-a).dot(b-a)/maxf(.000001,(b-a).length_squared()),0,1)))

## Test the complete footprint, including edges passing over a track with all
## vertices far away. The immutable cell index is shared by streaming workers.
func clear_polygon(ring: PackedVector2Array,margin: float=0.0) -> bool:
	if ring.size()<3:return false
	assert(margin>=0)
	var bounds:=Rect2(ring[0],Vector2.ZERO)
	for p in ring:bounds=bounds.expand(p)
	bounds=bounds.grow(margin)
	var visited:={}
	for x in range(floori(bounds.position.x/32),floori(bounds.end.x/32)+1):
		for z in range(floori(bounds.position.y/32),floori(bounds.end.y/32)+1):
			for item in cells.get(Vector2i(x,z),[]):
				if visited.has(item.query_id):continue
				visited[item.query_id]=true
				if not bounds.intersects(item.query_bounds,true):continue
				if item.has("ring"):
					if Geometry2D.is_point_in_polygon(ring[0],item.ring) or Geometry2D.is_point_in_polygon(item.ring[0],ring):return false
					for i in item.ring.size():
						if _segment_touches_polygon(item.ring[i],item.ring[(i+1)%item.ring.size()],ring,margin+item.margin):return false
				elif _segment_touches_polygon(item.a,item.b,ring,margin+item.width):return false
	return true

static func _segment_touches_polygon(a: Vector2,b: Vector2,ring: PackedVector2Array,radius: float) -> bool:
	if Geometry2D.is_point_in_polygon(a,ring) or Geometry2D.is_point_in_polygon(b,ring):return true
	for i in ring.size():
		var p: Vector2=ring[i];var q: Vector2=ring[(i+1)%ring.size()]
		if Geometry2D.segment_intersects_segment(a,b,p,q)!=null:return true
		if minf(minf(distance(a,p,q),distance(b,p,q)),minf(distance(p,a,b),distance(q,a,b)))<=radius:return true
	return false
