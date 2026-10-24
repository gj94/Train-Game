extends RefCounted
## Confined pond edges need a retaining face where a safe earth slope cannot
## reach the mapped water datum. Never construct a wall on clipped tile borders.
const Shores:=preload("res://game/geographic_shore_context.gd")
const Surface:=preload("res://game/geographic_road_support.gd")
const Stations:=preload("res://game/coastal_station_sites.gd")

static func faces(c,feature: Dictionary) -> Array:
	var result:=[]
	var water:={geometry=feature.geometry,height=feature.get("water_height",0.0)}
	for segment in Shores.segments([water]):
		var side: Vector2=(segment.b-segment.a).normalized().orthogonal()
		if c._inside((segment.a+segment.b)*.5+side*.1,water.geometry):side=-side
		var count:=maxi(1,ceili(segment.a.distance_to(segment.b)/2.0))
		for i in count:
			var a: Vector2=segment.a.lerp(segment.b,i/float(count));var b: Vector2=segment.a.lerp(segment.b,(i+1)/float(count))
			# Ordinary banks already meet the water. Only repair a real dry-land
			# height deficit, not the sub-cell interpolation at a normal shoreline.
			if minf(c._ground(a.x+side.x*.5,a.y+side.y*.5),c._ground(b.x+side.x*.5,b.y+side.y*.5))>=water.height-.4:continue
			var centre: Vector2=(a+b)*.5+Vector2(c.origin.x,c.origin.z)
			if Stations.contains(c.geo.station_sites,centre.x,centre.y):continue
			var rail_distance: float=c.geo.nearest_rail(centre.x,centre.y).distance
			var support=c.geo.get("formation_support")
			if support!=null:rail_distance=minf(rail_distance,support.nearest(centre).distance)
			if rail_distance<6.0:continue
			if not road_clear(c,a,b):continue
			var dry_a:=Surface.surface_height(c,a+side*.25);var dry_b:=Surface.surface_height(c,b+side*.25)
			if minf(dry_a,dry_b)>=water.height-.2:continue
			result.append({a=a,b=b,low_a=minf(dry_a,water.height)-.25,low_b=minf(dry_b,water.height)-.25,top=water.height+.16,side=side,rail_distance=rail_distance})
	return result

static func road_clear(c,a: Vector2,b: Vector2) -> bool:
	if c.water_bank_roads==null:
		var index=preload("res://game/geographic_scenery_occupancy.gd").new()
		var tile:=Vector2i(floori(c.origin.x/512),floori(c.origin.z/512))
		for dx in range(-1,2):
			for dz in range(-1,2):
				var features: Array=c.geo.tile(tile+Vector2i(dx,dz)).get("features",[]) if c.geo.has_method("tile") else (c.tile_features if dx==0 and dz==0 else [])
				for feature in features:
					if feature.kind!="road" or feature.tags.get("tunnel","no")!="no" or feature.tags.get("highway","") in ["proposed","construction"]:continue
					var width: float=preload("res://game/geographic_road_surface.gd").WIDTHS.get(feature.tags.get("highway",""),4.0)*.5+.65
					for line in c._lines(feature.geometry):
						for i in range(1,line.size()):
							var offset:=Vector2(dx*512,dz*512)
							index.add_road(Vector2(line[i-1][0],line[i-1][1])+offset,Vector2(line[i][0],line[i][1])+offset,width)
		c.water_bank_roads=index
	return c.water_bank_roads.clear((a+b)*.5,a.distance_to(b)*.5+.15)

static func draw(c,feature: Dictionary) -> void:
	for face in faces(c,feature):
		var a:=Vector3(face.a.x,face.low_a,face.a.y);var b:=Vector3(face.b.x,face.low_b,face.b.y)
		var top_a:=Vector3(a.x,face.top,a.z);var top_b:=Vector3(b.x,face.top,b.z)
		var normal:=Vector3(face.side.x,0,face.side.y)
		var tint:=Color(.43,.44,.39,1.0/15.0)
		c.batch.quad("architecture",a,b,top_b,top_a,normal,tint)
		c.batch.quad("architecture",b,a,top_a,top_b,-normal,tint)
