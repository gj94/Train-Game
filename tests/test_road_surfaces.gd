extends RefCounted
const Reservations:=preload("res://game/geographic_road_reservations.gd")
const Profiles:=preload("res://game/geographic_road_profiles.gd")
const Road:=preload("res://game/geographic_road_surface.gd")
class AccessGround:
	extends RefCounted
	var road_profiles
	func ground_at(_x: float,_z: float) -> float:return 0.0
func rect(a: Vector2,b: Vector2) -> PackedVector2Array:
	return PackedVector2Array([a,Vector2(b.x,a.y),b,Vector2(a.x,b.y)])
func area(pieces: Array) -> float:
	var result:=0.0
	for ring in pieces:
		var sum:=0.0
		for i in ring.size():sum+=ring[i].cross(ring[(i+1)%ring.size()])
		result+=absf(sum)*.5
	return result
func test_full_ribbon_is_clipped_even_when_road_midpoint_misses_platform():
	var reserve:=Reservations.new()
	reserve.add(rect(Vector2(14,-10),Vector2(18,10)),7.3)
	var parts:=reserve.clip(rect(Vector2(0,-3),Vector2(20,3)),Vector3.ZERO,0)
	return parts.size()==2 and is_equal_approx(area(parts),96.0)
func test_platform_clipping_crosses_tile_and_spatial_index_boundaries():
	var reserve:=Reservations.new()
	reserve.add(rect(Vector2(510,500),Vector2(520,530)),7.3)
	return is_equal_approx(area(reserve.clip(rect(Vector2(500,510),Vector2(530,516)),Vector3.ZERO,0)),120.0)
func test_flyover_clears_platform_but_cannot_slice_through_station_building():
	var reserve:=Reservations.new()
	var ring:=rect(Vector2(0,0),Vector2(20,20))
	reserve.add(ring,7.3)
	if not is_equal_approx(area(reserve.clip(ring,Vector3.ZERO,8.0)),400):return "Clear flyover suppressed"
	if not reserve.clip(ring,Vector3.ZERO,1.0).is_empty():return "Surface road crosses platform"
	reserve.add(ring,INF)
	return reserve.clip(ring,Vector3.ZERO,8.0).is_empty()
func test_hole_in_small_road_cell_never_fills_reserved_footprint():
	var reserve:=Reservations.new()
	reserve.add(rect(Vector2(5,5),Vector2(10,10)),7)
	return reserve.clip(rect(Vector2.ZERO,Vector2(20,20)),Vector3.ZERO,0).is_empty()
func test_local_origin_has_identical_clipped_surface():
	var reserve:=Reservations.new()
	reserve.add(rect(Vector2(1020,2000),Vector2(1040,2020)),7)
	var origin:=Vector3(1024,0,2048)
	var absolute:=rect(Vector2(1010,2005),Vector2(1050,2010))
	var local:=PackedVector2Array()
	for p in absolute:local.append(p-Vector2(origin.x,origin.z))
	return is_equal_approx(area(reserve.clip(absolute,Vector3.ZERO,0)),area(reserve.clip(local,origin,0)))
func test_bridge_profile_interpolates_without_raising_unconnected_parallel_road():
	var profile:=Profiles.new({segments=[["bridge",60,0,8,68,0,10,1],["approach",68,0,10,88,0,8.5,0]]})
	if profile.sample("bridge",Vector2(64,0)).get("height")!=9:return "Bridge grade wrong"
	if not profile.sample("other",Vector2(64,0)).is_empty():return "Unconnected road raised"
	if not profile.sample("bridge",Vector2(64,1)).is_empty():return "Nearby road raised"
	return profile.sample("bridge",Vector2(68,0)).height==profile.sample("approach",Vector2(68,0)).height and not profile.sample("approach",Vector2(75,0)).bridge
func test_road_miter_meets_both_segment_edges_at_corner():
	var points: Array[Vector3]=[Vector3.ZERO,Vector3(10,0,0),Vector3(10,0,10)]
	var m: Vector3=Road._miter(points,1)
	return is_equal_approx(absf(m.x),1) and is_equal_approx(absf(m.z),1) and m.length()<1.42
func test_station_access_does_not_invent_canal_or_rail_crossing():
	var access=preload("res://game/station_road_access.gd")
	var options:=[{a=Vector3.ZERO,b=Vector3(20,0,0),distance=20,gate=0}]
	var stream:={kind="stream",tags={waterway="stream"},geometry={type="LineString",coordinates=[[10,-20],[10,20]]}}
	if not access.clear_links(options,[stream],[Vector2.ZERO]).is_empty():return "Access spur crosses open canal"
	stream.tags.tunnel="culvert"
	if access.clear_links(options,[stream],[Vector2.ZERO]).size()!=1:return "Existing covered canal incorrectly blocks access"
	var graph:=TrackGraph.new();graph.add_node("a",Vector3(10,0,-20));graph.add_node("b",Vector3(10,0,20));graph.add_edge("rail","a","b")
	return access.clear_links(options,[],[],preload("res://game/scenery_clearance.gd").new(graph)).is_empty()

func test_parallel_road_edge_cannot_paint_over_water():
	var water=preload("res://game/geographic_road_water.gd").new()
	water.add(rect(Vector2(0,3),Vector2(40,30)),[])
	var road:=rect(Vector2(0,0),Vector2(20,5))
	return not water.wet(Vector2(10,2.5)) and is_equal_approx(area(water.clip([road])),60.0)

func test_island_road_is_retained_while_water_is_removed():
	var water=preload("res://game/geographic_road_water.gd").new()
	water.add(rect(Vector2(0,0),Vector2(100,100)),[rect(Vector2(40,40),Vector2(60,60))])
	var road:=rect(Vector2(20,45),Vector2(80,55))
	return water.wet(Vector2(25,50)) and not water.wet(Vector2(50,50)) and is_equal_approx(area(water.clip([road])),200)

func test_covered_drain_has_no_open_water_surface():
	var feature:={kind="stream",tags={waterway="stream",tunnel="culvert"},geometry={type="LineString",coordinates=[[0,0],[100,0]]}}
	return not preload("res://game/geographic_road_water.gd").new([feature]).wet(Vector2(50,0))

func test_station_gate_cannot_connect_to_underside_of_raised_approach():
	var zone: Dictionary=preload("res://game/station_precinct_plan.gd")._plan("test","test",Vector3.ZERO,Basis.IDENTITY,Vector2(40,20),true,false)
	var data:=AccessGround.new()
	var access=preload("res://game/station_road_access.gd")
	var a:=Vector2(-80,-60);var b:=Vector2(80,-60)
	if access.candidates(zone,data,a,b,"road").is_empty():return "Fixture has no reachable road"
	data.road_profiles=Profiles.new({segments=[["road",-80,-60,5,80,-60,5,0]]})
	if not access.candidates(zone,data,a,b,"road").is_empty():return "Entrance connects below raised road"
	data.road_profiles=Profiles.new({segments=[["road",-80,-60,.09,80,-60,.09,0]]})
	var connections: Array=access.candidates(zone,data,a,b,"road")
	return not connections.is_empty() and connections.all(func(c):return is_equal_approx(c.b.y,.09))

func test_clipped_road_keeps_absolute_texture_coordinates_and_separate_edge_mask():
	var batch=preload("res://game/geographic_mesh.gd").new()
	var origin:=Vector3(1024,0,2048)
	var c:={batch=batch,origin=origin,geo={road_reservations=null},road_water=null}
	var corners: Array[Vector3]=[Vector3(0,0,-2),Vector3(20,0,-2),Vector3(20,0,2),Vector3(0,0,2)]
	Road._surface(c,"road",corners,Vector3.ZERO,Vector3(20,0,0),Color.WHITE)
	var holder:=Node3D.new()
	batch.finish(holder,{road=StandardMaterial3D.new()},"Fixture")
	var arrays: Array=holder.get_child(0).mesh.surface_get_arrays(0)
	var result:=true
	for i in arrays[Mesh.ARRAY_VERTEX].size():
		var p: Vector3=arrays[Mesh.ARRAY_VERTEX][i]
		var uv: Vector2=arrays[Mesh.ARRAY_TEX_UV][i]
		var edge: Vector2=arrays[Mesh.ARRAY_TEX_UV2][i]
		if uv.distance_to(Vector2(p.x+origin.x,p.z+origin.z))>.001:result=false
		if absf(edge.x-(p.z/4+.5))>.001:result=false
	holder.free()
	return result

func test_rail_envelope_keeps_level_crossing_and_flyover_but_rejects_mid_height_road():
	var reserve:=Reservations.new()
	var ring:=rect(Vector2.ZERO,Vector2(20,20))
	reserve.add(ring,9.05,.52)
	if not is_equal_approx(area(reserve.clip(ring,Vector3.ZERO,-.05,.42)),400):return "Ground crossing removed"
	if not reserve.clip(ring,Vector3.ZERO,4,4.5).is_empty():return "Road passes through train/OHE space"
	return is_equal_approx(area(reserve.clip(ring,Vector3.ZERO,9.6,10.05)),400)
