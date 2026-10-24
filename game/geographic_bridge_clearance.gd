extends RefCounted
## Landward bridge walls must not close an existing road underneath the rail.
const WIDTHS:={motorway=10.0,trunk=9.0,primary=8.0,secondary=6.5,tertiary=5.5,residential=4.5,service=3.6,footway=1.5,path=1.0,track=2.8}
static func clear(geo,ring: PackedVector2Array,top: float,bottom: float) -> bool:
	var bounds:=Rect2(ring[0],Vector2.ZERO)
	for p in ring:bounds=bounds.expand(p)
	# The road centreline can lie just outside the wall's tile while its full
	# carriageway overlaps it. Include neighbouring tiles within the road width.
	bounds=bounds.grow(6)
	for x in range(floori(bounds.position.x/512),floori(bounds.end.x/512)+1):
		for z in range(floori(bounds.position.y/512),floori(bounds.end.y/512)+1):
			for f in geo.tile(Vector2i(x,z)).get("features",[]):
				if f.kind!="road" or f.tags.get("tunnel","no")!="no" or f.tags.get("highway") in ["proposed","construction"]:continue
				var lines: Array=[f.geometry.coordinates] if f.geometry.type=="LineString" else f.geometry.coordinates
				var width: float=WIDTHS.get(f.tags.get("highway"),4.0)*.5
				for line in lines:
					for i in range(1,line.size()):
						var a:=Vector2(line[i-1][0]+x*512,line[i-1][1]+z*512);var b:=Vector2(line[i][0]+x*512,line[i][1]+z*512)
						if a.distance_squared_to(b)<.001:continue
						var side:=(b-a).normalized().orthogonal()*width
						for part in Geometry2D.intersect_polygons(ring,PackedVector2Array([a-side,b-side,b+side,a+side])):
							var centre:=Vector2.ZERO
							for point in part:centre+=point
							centre/=part.size()
							var probes: Array=[centre]
							for j in part.size():probes.append(part[j]);probes.append((part[j]+part[(j+1)%part.size()])*.5)
							for point: Vector2 in probes:
								var t:=clampf((point-a).dot(b-a)/a.distance_squared_to(b),0,1);var p:=a.lerp(b,t)
								var sample: Dictionary=geo.road_profiles.sample(f.id,p) if geo.road_profiles!=null else {}
								var height: float=sample.height if sample.has("height") else geo.ground_at(p.x,p.y)+.07
								if height<top-.05 and height+4>bottom:return false
	return true
