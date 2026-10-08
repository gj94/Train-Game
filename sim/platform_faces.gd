extends RefCounted
## Platform positions are not the same quantity as tracks or platform bodies.
static func entries(station: Dictionary) -> Array:
	var result:=[]
	for road in station.platform_tracks:
		var detail: Dictionary=station.get("platform_details",{}).get(road,{platform_width=3.43,platform_side=-1})
		if detail.get("platform_width",0)<=0:continue
		for side in detail.get("platform_sides",[detail.platform_side]):
			var face:=detail.duplicate()
			face.edge=road;face.platform_side=side
			result.append(face)
	return result
