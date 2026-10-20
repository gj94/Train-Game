extends SceneTree
## Static presentation check: entrance endpoints must meet a real rendered road.
func _initialize() -> void:
	var w=preload("res://sim/layouts/kerala_coast.gd").build()
	var geo=preload("res://game/geographic_data.gd").new(w.scenery.route)
	geo.install_railway(w)
	geo.station_sites=preload("res://game/coastal_station_sites.gd").build(w,geo)
	var seen:={};var failures:=[];var total:=0;var cache:={}
	for zones in geo.station_sites.values():
		for zone in zones:
			if zone.get("access_zone",false) or seen.has(zone.id):continue
			seen[zone.id]=true
			for link in zone.access:
				total+=1
				var b: Vector3=link[1]
				var point:=Vector2(b.x,b.z)
				var error:=INF
				for x in range(floori(b.x/512)-1,floori(b.x/512)+2):
					for z in range(floori(b.z/512)-1,floori(b.z/512)+2):
						var key:=Vector2i(x,z)
						if not cache.has(key):cache[key]=geo.tile(key)
						for f in cache[key].get("features",[]):
							if f.kind!="road" or f.tags.get("tunnel","no")!="no":continue
							var lines: Array=f.geometry.coordinates if f.geometry.type=="MultiLineString" else [f.geometry.coordinates]
							for line in lines:
								for i in range(1,line.size()):
									var a:=Vector2(line[i-1][0]+x*512,line[i-1][1]+z*512)
									var c:=Vector2(line[i][0]+x*512,line[i][1]+z*512)
									if point.distance_to(Geometry2D.get_closest_point_to_segment(point,a,c))>.1:continue
									var profile: Dictionary=geo.road_profiles.sample(f.id,point)
									var height: float=profile.get("height",geo.ground_at(b.x,b.z)+.07)
									error=minf(error,absf(height-b.y))
				if error>.15:failures.append({station=zone.id,at=str(b),height_error=error})
	print("STATION_ROAD_CONNECTIONS links=",total," height_failures=",failures.size())
	for failure in failures:printerr(JSON.stringify(failure))
	quit(0 if failures.is_empty() and total>=40 else 1)
