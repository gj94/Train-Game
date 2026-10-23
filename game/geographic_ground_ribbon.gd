extends RefCounted
## Ground ribbons share the rendered terrain triangles. Worker-local cells are
## reused by asphalt, shoulders and paint; coplanar patches need no subdivision.
static func project(c,ring: PackedVector2Array,lift: float) -> Array:
	var bounds:=Rect2(ring[0],Vector2.ZERO)
	for p in ring:bounds=bounds.expand(p)
	var cells:=[]
	var cache=c.get("ground_ribbon_cells")
	for z in range(floori(bounds.position.y/8),ceili(bounds.end.y/8)):
		for x in range(floori(bounds.position.x/8),ceili(bounds.end.x/8)):
			var key:=Vector2i(x,z)
			if cache!=null:
				if not cache.has(key):cache[key]=_cell(c,Vector2(x*8,z*8))
				cells.append_array(cache[key])
			else:cells.append_array(_cell(c,Vector2(x*8,z*8)))
	if cells.is_empty():return []
	var common: PackedFloat64Array=cells[0].equation
	var coplanar:=true
	for cell in cells:
		for point in cell.plane:
			if absf(common[0]*point.x+common[1]*point.z+common[2]-point.y)>.0001:
				coplanar=false;break
		if not coplanar:break
	if coplanar:return _triangles(ring,common,lift)
	var result:=[]
	for cell in cells:
		for part in Geometry2D.intersect_polygons(ring,cell.ring):
			result.append_array(_triangles(part,cell.equation,lift))
	return result

static func _triangles(ring: PackedVector2Array,equation: PackedFloat64Array,lift: float) -> Array:
	var result:=[]
	var indices:=Geometry2D.triangulate_polygon(ring)
	for j in range(0,indices.size(),3):
		var triangle:=PackedVector3Array()
		for k in 3:
			var p: Vector2=ring[indices[j+k]]
			triangle.append(Vector3(p.x,equation[0]*p.x+equation[1]*p.y+equation[2]+lift,p.y))
		result.append(triangle)
	return result

static func _cell(c,start: Vector2) -> Array:
	var corners:=PackedVector3Array()
	var wet:=0
	var water=c.get("wet_samples")
	for offset in [Vector2.ZERO,Vector2(8,0),Vector2(8,8),Vector2(0,8)]:
		var p: Vector2=start+offset
		corners.append(Vector3(p.x,c._ground(p.x,p.y),p.y))
		if water!=null and water.get(p,false):wet+=1
	var result:=[]
	# Identical 2 m shore refinement and coarse-edge interpolation to terrain.
	var steps:=4 if wet>0 and wet<4 else 1
	for iz in steps:
		for ix in steps:
			var points:=PackedVector3Array()
			for offset in [Vector2(ix,iz),Vector2(ix+1,iz),Vector2(ix+1,iz+1),Vector2(ix,iz+1)]:
				var uv: Vector2=offset/float(steps)
				var p: Vector2=start+uv*8
				var height: float=c._ground(p.x,p.y)
				if uv.y==0:height=lerpf(corners[0].y,corners[1].y,uv.x)
				elif uv.y==1:height=lerpf(corners[3].y,corners[2].y,uv.x)
				elif uv.x==0:height=lerpf(corners[0].y,corners[3].y,uv.y)
				elif uv.x==1:height=lerpf(corners[1].y,corners[2].y,uv.y)
				points.append(Vector3(p.x,height,p.y))
			for indices in [[0,1,2],[0,2,3]]:
				var plane:=PackedVector3Array([points[indices[0]],points[indices[1]],points[indices[2]]])
				var ring:=PackedVector2Array()
				for p in plane:ring.append(Vector2(p.x,p.z))
				result.append({plane=plane,ring=ring,equation=_equation(plane)})
	return result

static func _equation(plane: PackedVector3Array) -> PackedFloat64Array:
	# Cache y = ax + bz + c once per worker-local terrain triangle, rather than
	# redoing barycentric vectors/divisions for every road/shoulder/paint vertex.
	# Doubles avoid losing height precision in the intercept near a tile corner.
	var dx1: float=plane[1].x-plane[0].x;var dz1: float=plane[1].z-plane[0].z
	var dx2: float=plane[2].x-plane[0].x;var dz2: float=plane[2].z-plane[0].z
	var dy1: float=plane[1].y-plane[0].y;var dy2: float=plane[2].y-plane[0].y
	var determinant:=dx1*dz2-dx2*dz1
	var a: float=(dy1*dz2-dy2*dz1)/determinant
	var b: float=(dx1*dy2-dx2*dy1)/determinant
	return PackedFloat64Array([a,b,plane[0].y-a*plane[0].x-b*plane[0].z])

static func plane_height(plane: PackedVector3Array,p: Vector2) -> float:
	var a:=Vector2(plane[0].x,plane[0].z)
	var b:=Vector2(plane[1].x,plane[1].z)-a
	var c:=Vector2(plane[2].x,plane[2].z)-a
	var determinant:=b.cross(c)
	var u: float=(p-a).cross(c)/determinant
	var v: float=b.cross(p-a)/determinant
	return plane[0].y+u*(plane[1].y-plane[0].y)+v*(plane[2].y-plane[0].y)
