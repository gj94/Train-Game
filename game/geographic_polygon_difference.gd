extends RefCounted
## Hole-free convex polygon difference shared by scenery mesh builders.
static func half_plane(poly: PackedVector2Array,a: Vector2,b: Vector2,sign_value: float) -> PackedVector2Array:
	var result:=PackedVector2Array()
	if poly.size()<3:return result
	for i in poly.size():
		var p:=poly[i];var q:=poly[(i+1)%poly.size()]
		var dp: float=(b-a).cross(p-a)*sign_value;var dq: float=(b-a).cross(q-a)*sign_value
		if dp>=0:result.append(p)
		if (dp<0)!=(dq<0):result.append(p.lerp(q,dp/(dp-dq)))
	return result

static func subtract_convex(poly: PackedVector2Array,cut: PackedVector2Array) -> Array:
	# Boolean polygons can return a hole contour when a shorter strip is wholly
	# inside another. Triangulating that contour alone would refill the hole.
	# Peel disjoint convex outside pieces instead, retaining no hole contours.
	var remaining:=poly;var result:=[];var area:=0.0
	for i in cut.size():area+=cut[i].cross(cut[(i+1)%cut.size()])
	var sign_value:=1.0 if area>0 else -1.0
	for i in cut.size():
		var a:=cut[i];var b:=cut[(i+1)%cut.size()]
		var outside:=half_plane(remaining,a,b,-sign_value)
		if outside.size()>=3:result.append(outside)
		remaining=half_plane(remaining,a,b,sign_value)
		if remaining.size()<3:break
	return result
