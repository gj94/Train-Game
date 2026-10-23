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
	var common: PackedVector3Array=cells[0].plane
	var coplanar:=true
	for cell in cells:
		for point in cell.plane:
			if absf(plane_height(common,Vector2(point.x,point.z))-point.y)>.0001:
				coplanar=false;break
		if not coplanar:break
	if coplanar:return _triangles(ring,common,lift)
	var result:=[]
	for cell in cells:
		for part in Geometry2D.intersect_polygons(ring,cell.ring):
			result.append_array(_triangles(part,cell.plane,lift))
	return result

static func _triangles(ring: PackedVector2Array,plane: PackedVector3Array,lift: float) -> Array:
	var result:=[]
	var indices:=Geometry2D.triangulate_polygon(ring)
	for j in range(0,indices.size(),3):
		var triangle:=PackedVector3Array()
		for k in 3:
			var p: Vector2=ring[indices[j+k]]
			triangle.append(Vector3(p.x,plane_height(plane,p)+lift,p.y))
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
				result.append({plane=plane,ring=ring})
	return result

static func plane_height(plane: PackedVector3Array,p: Vector2) -> float:
	var a:=Vector2(plane[0].x,plane[0].z)
	var b:=Vector2(plane[1].x,plane[1].z)-a
	var c:=Vector2(plane[2].x,plane[2].z)-a
	var determinant:=b.cross(c)
	var u: float=(p-a).cross(c)/determinant
	var v: float=b.cross(p-a)/determinant
	return plane[0].y+u*(plane[1].y-plane[0].y)+v*(plane[2].y-plane[0].y)
