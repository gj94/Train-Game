extends RefCounted
## Dense nearby cover with finite distance/cell culling, generated once per tile.
static func groundcover(chunk) -> void:
	var spacing:=2.8
	var count:=floori(512/spacing)
	var rail_cells:={}
	for z in count:
		for x in count:
			var p:=Vector3((x+.5)*spacing+chunk.rng.randf_range(-.7,.7),0,(z+.5)*spacing+chunk.rng.randf_range(-.7,.7))
			var land: int=chunk._class_at(p.x,p.z)
			if land in [4,5,6,7,8]:continue
			var absolute: Vector3=p+chunk.origin
			var key:=Vector2i(floori(p.x/16),floori(p.z/16))
			if not rail_cells.has(key):rail_cells[key]=chunk.geo.nearest_rail(chunk.origin.x+key.x*16+8,chunk.origin.z+key.y*16+8)
			var rail: Dictionary=rail_cells[key]
			if rail.distance>95:continue
			if land==2 and rail.distance>18:continue # Preserve cropped fields.
			if preload("res://game/coastal_station_sites.gd").contains(chunk.geo.station_sites,absolute.x,absolute.z,2.0):continue
			if chunk.geo.vegetation_clearance!=null and not chunk.geo.vegetation_clearance.clear(Vector2(absolute.x,absolute.z),2.0):continue
			if chunk._near_mapped_rail(Vector2(p.x,p.z),5):continue
			if not chunk.occupancy.clear(Vector2(p.x,p.z),1.8):continue
			p.y=preload("res://game/geographic_foundations.gd").surface_height(chunk._ground,p.x,p.z)
			var scale:=Vector3(chunk.rng.randf_range(.85,1.15),chunk.rng.randf_range(.6,1.4),chunk.rng.randf_range(.85,1.15))
			chunk.library.place("coastal_grass",p,chunk.rng.randf()*TAU,scale)
