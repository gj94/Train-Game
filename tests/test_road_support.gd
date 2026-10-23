extends RefCounted
const Support:=preload("res://game/geographic_road_support.gd")
const Road:=preload("res://game/geographic_road_surface.gd")
const Profiles:=preload("res://game/geographic_road_profiles.gd")
const Occupancy:=preload("res://game/geographic_scenery_occupancy.gd")
class Ground:
	extends RefCounted
	var geo={road_profiles=null,road_reservations=null,vegetation_clearance=null}
	var origin:=Vector3.ZERO
	var road_water=preload("res://game/geographic_road_water.gd").new()
	var road_supports
	var road_barrier_widths: Dictionary={}
	var road_support_records: Array=[]
	var ground_ribbon_cells: Dictionary={}
	var tile_features: Array=[]
	var batch=preload("res://game/geographic_mesh.gd").new()
	var occupancy=Occupancy.new()
	func _ground(x: float,_z: float) -> float:return x*.05
	func _corridor(_x: float,_z: float) -> bool:return true
	func _lines(geometry: Dictionary) -> Array:return [geometry.coordinates]
class NeighbourData:
	extends RefCounted
	var road_profiles
	var road_reservations
	var vegetation_clearance
	var features: Array=[]
	func tile(key: Vector2i) -> Dictionary:return {features=features} if key==Vector2i(1,0) else {}

func top(height: float) -> Array[Vector3]:
	return [Vector3(0,height,-2),Vector3(4,height,-2),Vector3(4,height,2),Vector3(0,height,2)]
func plan(c,height: float,features: Array=[]) -> Dictionary:
	return Support.new(features,Road.WIDTHS).plan(c,"approach",top(height),Vector3(0,height+.4,0),Vector3(4,height+.4,0))
func road(id: String,height: float) -> Dictionary:
	return {id=id,kind="road",tags={highway="service"},geometry={type="LineString",coordinates=[[2,-20],[2,20]]},height=height}
func test_dry_low_approach_has_gentle_grounded_batters():
	var c:=Ground.new();var result:=plan(c,2)
	if result.get("kind")!="earth":return "Dry rural fill missing"
	for i in 4:
		var p: Vector3=result.foot[i]
		if absf(p.y-(c._ground(p.x,p.z)-.18))>.001:return "Toe does not reach rendered terrain"
		if absf(p.z)<=2:return "Earth batter has no width"
	return true
func test_high_approach_is_retained_inside_its_footprint():
	var result:=plan(Ground.new(),8)
	return result.get("kind")=="retained" and absf(result.foot[0].z)==2
func test_building_beside_approach_requires_retaining_not_earth_over_property():
	var building:={kind="building",geometry={type="Polygon",coordinates=[[[0,3],[5,3],[5,7],[0,7],[0,3]]]}}
	var result:=plan(Ground.new(),2,[building])
	if result.get("kind")!="retained":return "Slope crosses a building"
	building.geometry.coordinates=[[[0,-1],[5,-1],[5,1],[0,1],[0,-1]]]
	return plan(Ground.new(),2,[building]).is_empty()
func test_rail_underpass_keeps_open_span_including_edges_between_corners():
	var c:=Ground.new();c.geo.vegetation_clearance=Occupancy.new()
	c.geo.vegetation_clearance.add_road(Vector2(2,-20),Vector2(2,20),.2)
	return plan(c,12).is_empty()
func test_narrow_open_drain_is_not_filled_even_with_four_dry_corners():
	var c:=Ground.new()
	c.road_water=preload("res://game/geographic_road_water.gd").new([{kind="stream",tags={waterway="drain"},geometry={type="LineString",coordinates=[[2,-20],[2,20]]}}])
	return plan(c,8).is_empty()
func test_lower_road_keeps_its_underpass_but_same_level_junction_can_share_fill():
	var c:=Ground.new();var feature:=road("crossing",0)
	if not plan(c,8,[feature]).is_empty():return "Lower street buried"
	c.geo.road_profiles=Profiles.new({segments=[["crossing",2,-20,8.4,2,20,8.4,0]]})
	return not plan(c,8,[feature]).is_empty()
func test_station_precinct_is_not_filled_even_beneath_clear_flyover():
	var c:=Ground.new();c.geo.road_reservations=preload("res://game/geographic_road_reservations.gd").new()
	c.geo.road_reservations.add(PackedVector2Array([Vector2(1,-10),Vector2(3,-10),Vector2(3,10),Vector2(1,10)]),7)
	return plan(c,12).is_empty()
func test_fill_reserves_vegetation_and_uses_existing_material_batches():
	var c:=Ground.new();var result:=plan(c,2)
	Support.draw(c,result)
	if c.occupancy.clear(Vector2(2,4),.1):return "Plants can grow through embankment"
	return c.batch.surfaces.size()<=2 and c.batch.surfaces.has("road_shoulder") and c.road_support_records.size()==1
func test_explicit_bridge_is_open_but_untagged_dry_approach_is_supported():
	var c:=Ground.new()
	var feature:={id="approach",kind="road",tags={highway="service"},geometry={type="LineString",coordinates=[[0,0],[12,0]]}}
	c.geo.road_profiles=Profiles.new({segments=[["approach",0,0,8,12,0,8,1]]})
	Road.draw(c,feature)
	if not c.road_support_records.is_empty():return "Bridge span filled"
	c.geo.road_profiles=Profiles.new({segments=[["approach",0,0,8,12,0,8,0]]})
	Road.draw(c,feature)
	return c.road_support_records.size()==3

func test_hairpin_bank_cannot_fold_over_itself_or_collapse():
	if Support.valid_ring(PackedVector2Array([Vector2(0,0),Vector2(4,4),Vector2(0,4),Vector2(4,0)])):return "Crossed bank accepted"
	if Support.valid_ring(PackedVector2Array([Vector2.ZERO,Vector2.ZERO,Vector2.ONE])):return "Collapsed bank accepted"
	return Support.valid_ring(PackedVector2Array([Vector2.ZERO,Vector2(4,0),Vector2(4,4),Vector2(0,4)]))

func test_other_road_grade_is_checked_at_whole_support_edge():
	var c:=Ground.new();var feature:=road("slope",0)
	c.geo.road_profiles=Profiles.new({segments=[["slope",2,-20,-.6,2,20,7.4,0]]})
	# The centre meets the approach, but a much wider batter would bury the
	# descending road at its outer edge. Keep support narrow enough there.
	var result:=plan(c,3,[feature])
	if result.is_empty():return true
	return result.kind=="retained"

func test_earth_to_wall_transition_shares_footings_and_has_no_steep_soil_cap():
	var c:=Ground.new();var support:=Support.new()
	var first:=plan(c,2)
	var second:=first.duplicate(true)
	for i in 4:
		second.top[i].x+=4;second.foot[i]=second.top[i];second.foot[i].y=c._ground(second.foot[i].x,second.foot[i].z)-.18
	support.pending=[first,second];support.flush(c)
	if c.road_support_records.size()!=2:return "Missing transition cells"
	var a: Dictionary=c.road_support_records[0];var b: Dictionary=c.road_support_records[1]
	if a.foot[1].distance_to(b.foot[0])>.001 or a.foot[2].distance_to(b.foot[3])>.001:return "Footings jump at cell boundary"
	for record in c.road_support_records:
		for i in 4:
			var run:=Vector2(record.top[i].x-record.foot[i].x,record.top[i].z-record.foot[i].z).length()
			if record.bank[i].y-record.foot[i].y>run/1.5+.001:return "Earth transition is too steep"
	return true

func test_bank_at_tile_edge_cannot_bury_neighbour_building_or_stream():
	var c:=Ground.new();var data:=NeighbourData.new();c.geo=data
	var edge_top: Array[Vector3]=[Vector3(510,32,18),Vector3(514,32,18),Vector3(514,32,22),Vector3(510,32,22)]
	data.features=[{kind="building",geometry={type="Polygon",coordinates=[[[1,19],[5,19],[5,23],[1,23],[1,19]]]}}]
	if not Support.new().plan(c,"approach",edge_top,Vector3(510,32.4,20),Vector3(514,32.4,20)).is_empty():return "Neighbour building buried"
	data.features=[{id="drain",kind="stream",tags={waterway="drain"},geometry={type="LineString",coordinates=[[1,0],[1,40]]}}]
	return Support.new().plan(c,"approach",edge_top,Vector3(510,32.4,20),Vector3(514,32.4,20)).is_empty()

func test_short_soil_islands_are_retained_but_long_banks_remain():
	for count in [2,6]:
		var c:=Ground.new();var support:=Support.new()
		for index in count:
			var item:=plan(c,2)
			for i in 4:item.top[i].x+=index*4;item.foot[i].x+=index*4
			support.pending.append(item)
		support.flush(c)
		var earth: bool=c.road_support_records.any(func(p):return p.kind=="earth")
		if earth!=(count==6):return "Short soil island or missing continuous bank"
	return true

func test_fill_keeps_overhead_footings_clear_after_tile_rebasing():
	var c:=Ground.new();c.origin=Vector3(1024,0,2048)
	c.geo.road_profiles=Profiles.new({segments=[],support_posts=[[1026,2048]]})
	return plan(c,8).is_empty()
