extends RefCounted
const Access:=preload("res://game/village_access.gd")
const Walls:=preload("res://game/village_walls.gd")
const Occupancy:=preload("res://game/geographic_scenery_occupancy.gd")
class Plot:
	extends RefCounted
	var origin:=Vector3.ZERO
	var batch=preload("res://game/geographic_mesh.gd").new()
	var occupancy=preload("res://game/geographic_scenery_occupancy.gd").new()
	var mapped_rail_clearance=preload("res://game/geographic_scenery_occupancy.gd").new()
	var road_water=preload("res://game/geographic_road_water.gd").new()
	var geo:={station_sites={},vegetation_clearance=null,road_reservations=null,road_profiles=null}
	var tile_features:=[]
	func _ground(x: float,z: float) -> float:return x*.025+z*.01
	func _lines(geometry: Dictionary) -> Array:return [geometry.coordinates]

func test_private_path_can_join_its_house_and_road_but_not_cross_a_neighbour():
	var c:=Plot.new()
	var ring:=Access.corridor(Vector2(30,30),Vector2(60,30))
	c.occupancy.add_polygon(PackedVector2Array([Vector2(25,25),Vector2(31,25),Vector2(31,35),Vector2(25,35)]),.6,"house")
	c.occupancy.add_road(Vector2(60,10),Vector2(60,50),2,"road")
	if not Access.clear(c,ring,"house","road"):return "Own entrance and road connection rejected"
	c.occupancy.add_polygon(PackedVector2Array([Vector2(42,29),Vector2(43,29),Vector2(43,31),Vector2(42,31)]),.6,"neighbour")
	return not Access.clear(c,ring,"house","road")

func test_path_rejects_narrow_water_and_rail_between_its_endpoints():
	var c:=Plot.new()
	var ring:=Access.corridor(Vector2(30,30),Vector2(60,30))
	c.road_water.add(PackedVector2Array([Vector2(42,0),Vector2(42.15,0),Vector2(42.15,80),Vector2(42,80)]),[])
	if Access.clear(c,ring,"house","road"):return "Path crosses a narrow canal"
	c.road_water=preload("res://game/geographic_road_water.gd").new()
	c.mapped_rail_clearance.add_road(Vector2(45,0),Vector2(45,90),3.15)
	return not Access.clear(c,ring,"house","road")

func test_path_rejects_tile_edge_and_existing_props_without_owner():
	var c:=Plot.new()
	if Access.clear(c,Access.corridor(Vector2(1,30),Vector2(40,30)),"a","b"):return "Incomplete cross-tile path"
	c.occupancy.add_road(Vector2(45,30),Vector2(45,30),.4)
	return not Access.clear(c,Access.corridor(Vector2(30,30),Vector2(60,30)),"a","b")

func test_stairs_land_on_ground_with_bounded_rises_and_no_extreme_flight():
	var c:=Plot.new();var a:=Vector2(40,40)
	var stairs:=Access.flight(a,Vector2.RIGHT,15,Access.ground(c._ground,a)+1.1,c._ground)
	if stairs.is_empty() or stairs.count<4:return "Missing plinth access stair"
	var toe: Vector2=a+Vector2.RIGHT*stairs.run
	if absf(stairs.top-stairs.count*stairs.rise-Access.ground(c._ground,toe)-.06)>.00001:return "Floating stair toe"
	if stairs.rise<.09 or stairs.rise>.19:return "Unsafe visual stair proportions"
	return Access.flight(a,Vector2.RIGHT,2,Access.ground(c._ground,a)+2.6,c._ground).is_empty()

func test_road_target_is_in_front_and_rejects_elevated_roads():
	var c:=Plot.new()
	c.tile_features=[{id="back",kind="road",tags={highway="residential"},geometry={coordinates=[[60,0],[60,90]]}},{id="front",kind="road",tags={highway="residential"},geometry={coordinates=[[30,0],[30,90]]}}]
	var target:=Access.road_end(c,Vector2(50,40),Vector2.LEFT)
	if target.is_empty() or target.id!="front" or absf(target.point.x-32.15)>.001:return "Wrong road edge or facade side"
	c.tile_features[1].tags.bridge="yes"
	return Access.road_end(c,Vector2(50,40),Vector2.LEFT).is_empty()

func test_wall_faces_reach_below_sloping_ground_along_both_sides():
	var c:=Plot.new()
	Walls.draw(c,Vector2(20,20),Vector2(40,20),.86,.17,Color(.51,.47,.36,1.0/15))
	var mesh: ArrayMesh=c.batch.surfaces.architecture_detail.commit()
	var vertices: PackedVector3Array=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var grounded:={}
	for p in vertices:
		if absf(p.z-19.915)>.001 and absf(p.z-20.085)>.001:continue
		if p.y<Access.ground(c._ground,Vector2(p.x,p.z))-.1:grounded[snappedf(p.x,.001)]=true
	return grounded.size()>=10

func test_path_rejects_a_platform_reservation_across_its_middle():
	var c:=Plot.new()
	c.geo.road_reservations=preload("res://game/geographic_road_reservations.gd").new()
	c.geo.road_reservations.add(PackedVector2Array([Vector2(42,20),Vector2(44,20),Vector2(44,40),Vector2(42,40)]),8,3)
	return not Access.clear(c,Access.corridor(Vector2(30,30),Vector2(60,30)),"house","road")

class RaisedRoad:
	extends RefCounted
	func sample(_way: String,p: Vector2) -> Dictionary:
		return {height=5.0,bridge=false} if absf(p.x-30)<.06 else {}

func test_path_checks_engineered_height_at_road_centre_not_off_the_profile():
	var c:=Plot.new();c.geo.road_profiles=RaisedRoad.new()
	c.tile_features=[{id="front",kind="road",tags={highway="residential"},geometry={coordinates=[[30,0],[30,90]]}}]
	return Access.road_end(c,Vector2(50,40),Vector2.LEFT).is_empty()

func test_stair_flight_does_not_cut_into_a_steep_cross_slope():
	var sample:=func(_x: float,z: float):return z*2.0
	return Access.flight(Vector2(40,40),Vector2.RIGHT,15,81.1,sample).is_empty()
