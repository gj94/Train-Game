extends RefCounted
## Fit the existing detailed architectural kit inside a mapped rectangular footprint.
## Irregular/narrow/oversized polygons keep their actual mapped facade mesh.
const KINDS:=["tiled_house","tiled_cottage","kerala_bungalow","townhouse","shop_house","apartments_3","apartments_4","workshop","warehouse"]
static func fit(ring: PackedVector2Array,levels: int,tags: Dictionary,seed_value: int,manifest: Dictionary) -> Dictionary:
	if ring.size()!=4:return {}
	var centre:=Vector2.ZERO
	for p in ring:centre+=p
	centre/=4
	var edge:=ring[1]-ring[0]
	if edge.length()<3:return {}
	var along:=edge.normalized()
	var across:=Vector2(-along.y,along.x)
	var lo:=Vector2(INF,INF);var hi:=Vector2(-INF,-INF)
	for p in ring:
		var local:=Vector2((p-centre).dot(along),(p-centre).dot(across))
		lo=lo.min(local);hi=hi.max(local)
	var size:=hi-lo
	for corner in [lo+Vector2(.15,.15),Vector2(hi.x-.15,lo.y+.15),hi-Vector2(.15,.15),Vector2(lo.x+.15,hi.y-.15)]:
		if not Geometry2D.is_point_in_polygon(centre+along*corner.x+across*corner.y,ring):return {}
	# A bounding rectangle may cover somebody else's plot at a skewed corner.
	var area:=0.0
	for i in 4:area+=ring[i].cross(ring[(i+1)%4])
	if absf(area)*.5<size.x*size.y*.94:return {}
	var kind: String
	if tags.get("building","") in ["industrial","warehouse","shed"]:
		if levels>2:return {}
		kind="warehouse" if size.x*size.y>280 else "workshop"
	elif levels==1:kind=["tiled_house","tiled_cottage","kerala_bungalow"][seed_value%3]
	elif levels==2:kind=["townhouse","shop_house"][seed_value%2]
	elif levels==3:kind="apartments_3"
	elif levels==4:kind="apartments_4"
	else:return {}
	if not manifest.has(kind):return {}
	var data: Dictionary=manifest[kind]
	var source:=Vector3(data.godot_size[0],data.godot_size[1],data.godot_size[2])
	var mapped_height:=float(str(tags.get("height","0")).trim_suffix(" m"))
	if mapped_height>0 and (mapped_height/source.y<.70 or mapped_height/source.y>1.40):return {}
	var sx: float=(size.x-.30)/source.x;var sz: float=(size.y-.30)/source.z
	if minf(sx,sz)<.68 or maxf(sx,sz)>1.65:return {}
	var basis:=Basis(Vector3(along.x,0,along.y),Vector3.UP,Vector3(across.x,0,across.y))
	var scale:=Vector3(sx,1,sz)
	# Vertical scale stays 1: door, stair and storey heights remain human-sized.
	var local_centre:=Vector3((data.godot_min[0]+data.godot_max[0])*.5,0,(data.godot_min[2]+data.godot_max[2])*.5)
	var position:=Vector3(centre.x,0,centre.y)-basis*(local_centre*scale)
	return {kind=kind,position=position,angle=atan2(-along.y,along.x),scale=scale}
