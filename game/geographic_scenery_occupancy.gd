extends RefCounted
## Tile-local broad phase prevents reconstructed planting from covering mapped
## houses, roads and water. Immutable after build; each streaming worker owns it.
var cells:={}
func add_polygon(ring: PackedVector2Array,margin: float=0.0) -> void:
	if ring.size()<3:return
	var bounds:=Rect2(ring[0],Vector2.ZERO)
	for p in ring:bounds=bounds.expand(p)
	var item:={ring=ring,bounds=bounds,margin=margin}
	_insert(item,bounds.grow(margin+6))
func add_road(a: Vector2,b: Vector2,half_width: float) -> void:
	_insert({a=a,b=b,width=half_width},Rect2(a,Vector2.ZERO).expand(b).grow(half_width+6))
func _insert(item: Dictionary,bounds: Rect2) -> void:
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
