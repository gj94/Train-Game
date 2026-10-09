extends RefCounted
const Kerala:=preload("res://game/kerala_scenery.gd")
const Layout:=preload("res://game/geographic_building_layout.gd")
const Chunk:=preload("res://game/geographic_scenery_chunk.gd")
const Occupancy:=preload("res://game/geographic_scenery_occupancy.gd")
class FlatData:
	var station_sites:={}
	func ground_at(_x: float,_z: float) -> float:return 3.0
	func nearest_rail(_x: float,_z: float) -> Dictionary:return {distance=100.0}
class RecordedMesh:
	var points:=[]
	func quad(_kind,a,b,c,d,_normal,_colour,_uvs) -> void:points.append_array([a,b,c,d])
func catalog() -> Dictionary:return JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/scenery/manifest.json"))
func test_road_facing_building_keeps_all_new_assets_inside_rotated_envelope():
	var data:=catalog()
	for kind in ["kerala_veranda","laterite_cottage","balcony_villa","coastal_shop"]:
		var asset: Dictionary=data[kind]
		for angle in [.0,.43,1.83]:
			var extent:=Vector2(asset.godot_size[0]+.5,asset.godot_size[2]+.5)*.5
			var ring:=PackedVector2Array()
			for p in [Vector2(-extent.x,-extent.y),Vector2(extent.x,-extent.y),extent,Vector2(-extent.x,extent.y)]:ring.append(p.rotated(angle)+Vector2(64,95))
			var front:=Vector2(0,-1).rotated(angle)
			var fit:=Layout.fit(ring,2 if kind=="balcony_villa" else 1,{"shop":"yes"} if kind=="coastal_shop" else {},0,{kind:asset},front)
			if fit.is_empty():return "New asset cannot fit its own envelope: "+kind
			var basis:=Basis(Vector3.UP,fit.angle).scaled_local(fit.scale)
			if Vector2(-basis.z.x,-basis.z.z).normalized().dot(front)<.99:return "Facade faces away from mapped road: "+kind
			for x in [asset.godot_min[0],asset.godot_max[0]]:
				for z in [asset.godot_min[2],asset.godot_max[2]]:
					var p: Vector3=fit.position+basis*Vector3(x,0,z)
					if not Geometry2D.is_point_in_polygon(Vector2(p.x,p.z),ring):return "Footprint escape: "+kind
	return true
func test_field_bunds_agree_across_positive_and_negative_tile_boundaries():
	for x in [-1024.0,-512.0,0.0,512.0,1024.0]:
		if Kerala.parcel_edge(Vector2(x,50))!=0:return "Tile boundary is not a stable parcel edge"
		# Vector2 uses 32-bit components; +/- .3 near 1024 quantizes differently.
		if absf(Kerala.parcel_edge(Vector2(x-.3,50))-Kerala.parcel_edge(Vector2(x+.3,50)))>.0002:return "Parcel coordinates depend on tile side"
	return Kerala.parcel_edge(Vector2(32,48))==32
func test_boat_hull_respects_water_holes_tile_edges_and_road_clearance():
	var c:=Chunk.new(null,{},null)
	var water:={type="Polygon",coordinates=[[[0,0],[512,0],[512,512],[0,512],[0,0]],[[90,90],[110,90],[110,110],[90,110],[90,90]]]}
	if Kerala.water_envelope(c,Vector2(100,100),Vector2.RIGHT,water):return "Boat in water polygon hole"
	if Kerala.water_envelope(c,Vector2(3,30),Vector2.RIGHT,water):return "Boat straddles tile boundary"
	if not Kerala.water_envelope(c,Vector2(50,50),Vector2.RIGHT,water):return "Clear water rejected"
	c.occupancy.add_road(Vector2(53,40),Vector2(53,60),1.5)
	return not Kerala.water_envelope(c,Vector2(50,50),Vector2.RIGHT,water)
func test_new_asset_geometry_has_bounded_cost_and_portable_manifest():
	var data:=catalog()
	for kind in Kerala.ASSETS:
		if not data.has(kind):return "Missing portable asset "+kind
		if data[kind].triangles>10000:return "Excessive repeated scenery geometry "+kind
		if data[kind].surfaces>3:return "Excessive per-instance surfaces "+kind
	return true
func test_boat_rejects_narrow_island_between_sample_points():
	var c:=Chunk.new(null,{},null)
	var water:={type="Polygon",coordinates=[[[0,0],[512,0],[512,512],[0,512],[0,0]],[[51,49],[51.3,49],[51.3,51],[51,51],[51,49]]]}
	return not Kerala.water_envelope(c,Vector2(50,50),Vector2.RIGHT,water)
func test_precise_small_water_overrides_dry_landcover_raster():
	var c:=Chunk.new(FlatData.new(),{},null)
	c.mask.resize(4096);c.mask.fill(0)
	c.water_levels=[{height=.8,geometry={type="Polygon",coordinates=[[[8,8],[12,8],[12,12],[8,12],[8,8]]]}}]
	return is_equal_approx(c._ground(10,10),.3) and is_equal_approx(c._ground(14,14),3.0) and c.wet_samples[Vector2(10,10)]
func test_bank_grading_is_local_and_ignores_tile_clipping_edges():
	var c:=Chunk.new(FlatData.new(),{},null)
	c.mask.resize(4096);c.mask.fill(0)
	c.water_levels=[{height=.8,geometry={type="Polygon",coordinates=[[[0,0],[100,0],[100,512],[0,512],[0,0]]]}}]
	c._index_shores()
	if c._ground(102,50)>1.3 or c._ground(102,50)<1.02:return "Bank does not meet water datum smoothly"
	if c._ground(120,50)!=3.0:return "Bank grading escaped its local band"
	return not c.shore_bins.has(Vector2i(0,4))
func test_refined_shore_perimeter_matches_coarse_neighbour_edges():
	var c:=Chunk.new(FlatData.new(),{},null)
	c.batch=RecordedMesh.new()
	c.water_levels=[{height=.8,geometry={type="Polygon",coordinates=[[[64,64],[69,64],[69,69],[64,69],[64,64]]]}}]
	c._shore_cell(Vector2(64,64),8,[Vector3(64,3,64),Vector3(72,4,64),Vector3(72,4,72),Vector3(64,3,72)])
	for p: Vector3 in c.batch.points:
		if p.x==64 or p.x==72 or p.z==64 or p.z==72:
			if not is_equal_approx(p.y,3+(p.x-64)/8):return "Adaptive shoreline splits the coarse edge"
	return true
