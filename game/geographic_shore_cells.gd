extends RefCounted
## Shared terrain/road shore topology. Neighbouring fine cells share real 2 m
## samples; only a fine-to-coarse edge is interpolated onto the 8 m neighbour.
const Occupancy:=preload("res://game/geographic_scenery_occupancy.gd")
const RADIUS:=10.0

static func refined(c,start: Vector2) -> bool:
	var bins=c.get("shore_bins")
	if bins==null:
		# Small standalone terrain fixtures can expose wet samples without an index.
		var wet:=0;var water=c.get("wet_samples")
		for offset in [Vector2.ZERO,Vector2(8,0),Vector2(8,8),Vector2(0,8)]:
			var p: Vector2=start+offset;c._ground(p.x,p.y)
			if water!=null and water.get(p,false):wet+=1
		return wet>0 and wet<4
	# Retain the existing coarse boundary contract between independent tiles.
	# The new continuous fine grid applies inside the tile, including its banks.
	if start.x<0 or start.y<0 or start.x>504 or start.y>504:return false
	var cache=c.get("shore_refinement_cache")
	if cache!=null and cache.has(start):return cache[start]
	var centre:=start+Vector2(4,4)
	var result:=false
	var geo=c.get("geo")
	if geo!=null:
		var support=geo.get("formation_support")
		if support!=null:
			var origin: Vector3=c.origin
			result=support.fine_cells.has(Vector2i(floori((origin.x+start.x)/8),floori((origin.z+start.y)/8)))
	for segment in bins.get(Vector2i(floori(centre.x/32),floori(centre.y/32)),[]):
		if Occupancy.distance(centre,segment.a,segment.b)<=RADIUS:
			result=true;break
	if cache!=null:cache[start]=result
	return result

static func quads(c,start: Vector2,corners: PackedVector3Array,fine: bool) -> Array:
	var count:=4 if fine else 1
	var stitch:=[true,true,true,true]
	if fine and c.get("shore_bins")!=null:
		for i in 4:
			stitch[i]=not refined(c,start+[Vector2(0,-8),Vector2(8,0),Vector2(0,8),Vector2(-8,0)][i])
	var result:=[]
	for z in count:
		for x in count:
			var points:=PackedVector3Array()
			for offset in [Vector2(x,z),Vector2(x+1,z),Vector2(x+1,z+1),Vector2(x,z+1)]:
				var uv: Vector2=offset/float(count);var p:=start+uv*8
				var height: float=c._ground(p.x,p.y)
				if uv.y==0 and stitch[0]:height=lerpf(corners[0].y,corners[1].y,uv.x)
				elif uv.x==1 and stitch[1]:height=lerpf(corners[1].y,corners[2].y,uv.y)
				elif uv.y==1 and stitch[2]:height=lerpf(corners[3].y,corners[2].y,uv.x)
				elif uv.x==0 and stitch[3]:height=lerpf(corners[0].y,corners[3].y,uv.y)
				points.append(Vector3(p.x,height,p.y))
			result.append(points)
	return result
