extends RefCounted
## Extend terrain/obstacle clearance to the simulation's reconstructed depot tracks.
static func install(data, route: Dictionary) -> void:
	for road in route.get("depot_alignment",[]):
		for i in range(1,road.points.size()):
			var p: Array=road.points[i-1];var q: Array=road.points[i]
			var a:=Vector3(p[0],p[1],p[2]);var b:=Vector3(q[0],q[1],q[2])
			var index: int=data.segments.size()
			data.segments.append({a=a,b=b,s=road.s,bridge=false,depot=true})
			for x in range(floori(minf(a.x,b.x)/data.CELL)-1,floori(maxf(a.x,b.x)/data.CELL)+2):
				for z in range(floori(minf(a.z,b.z)/data.CELL)-1,floori(maxf(a.z,b.z)/data.CELL)+2):
					var key:=Vector2i(x,z)
					if not data.rail_bins.has(key):data.rail_bins[key]=[]
					data.rail_bins[key].append(index)
