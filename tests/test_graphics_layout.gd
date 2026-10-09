extends RefCounted
const Layout:=preload("res://game/geographic_building_layout.gd")
const Occupancy:=preload("res://game/geographic_scenery_occupancy.gd")
func catalog() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/scenery/manifest.json"))
func rectangle(angle: float,offset:=Vector2.ZERO) -> PackedVector2Array:
	var ring:=PackedVector2Array()
	for p in [Vector2(-5,-6),Vector2(5,-6),Vector2(5,6),Vector2(-5,6)]:ring.append(p.rotated(angle)+offset)
	return ring
func test_detailed_building_stays_within_rotated_mapped_footprint():
	var data:=catalog()
	for angle in [0.0,.73,2.31,-1.35]:
		for offset in [Vector2.ZERO,Vector2(320,-400)]:
			var ring:=rectangle(angle,offset)
			var fit:=Layout.fit(ring,2,{},8,data)
			if fit.is_empty():return "Valid two-storey rectangle was rejected"
			var bounds: Dictionary=data[fit.kind]
			var basis:=Basis(Vector3.UP,fit.angle).scaled_local(fit.scale)
			for x in [bounds.godot_min[0],bounds.godot_max[0]]:
				for z in [bounds.godot_min[2],bounds.godot_max[2]]:
					var p: Vector3=fit.position+basis*Vector3(x,0,z)
					if not Geometry2D.is_point_in_polygon(Vector2(p.x,p.z),ring):return "Detailed mesh leaves mapped footprint"
	return true
func test_irregular_footprint_keeps_mapped_geometry():
	var ring:=PackedVector2Array([Vector2(0,0),Vector2(12,0),Vector2(12,5),Vector2(4,5),Vector2(4,10),Vector2(0,10)])
	return Layout.fit(ring,1,{},0,catalog()).is_empty()
func test_skewed_footprint_cannot_gain_corners():
	var ring:=PackedVector2Array([Vector2(0,0),Vector2(10,0),Vector2(11,12),Vector2(1,12)])
	return Layout.fit(ring,2,{},0,catalog()).is_empty()
func test_tower_and_tiny_buildings_keep_real_envelope():
	var tiny:=PackedVector2Array([Vector2(0,0),Vector2(2,0),Vector2(2,2),Vector2(0,2)])
	return Layout.fit(rectangle(0),9,{},0,catalog()).is_empty() and Layout.fit(tiny,1,{},0,catalog()).is_empty()
func test_vegetation_road_clearance_crosses_spatial_cells():
	var occupied:=Occupancy.new()
	occupied.add_road(Vector2(-90,31),Vector2(90,31),3)
	for p in [Vector2(-33,35),Vector2(0,32),Vector2(32,27)]:
		if occupied.clear(p,2):return "Missed road across grid boundary"
	return occupied.clear(Vector2(0,39),2)
func test_vegetation_clearance_covers_building_edge_and_interior():
	var occupied:=Occupancy.new()
	occupied.add_polygon(rectangle(.4,Vector2(32,32)),.6)
	return not occupied.clear(Vector2(32,32),3) and not occupied.clear(Vector2(32,39),3) and occupied.clear(Vector2(60,60),3)
func test_explicit_height_and_industrial_storeys_remain_mapped():
	return Layout.fit(rectangle(0),1,{"height":"28 m"},0,catalog()).is_empty() and Layout.fit(rectangle(0),4,{"building":"industrial"},0,catalog()).is_empty()
func test_detail_placement_is_deterministic():
	var data:=catalog()
	return Layout.fit(rectangle(.7),2,{},18,data)==Layout.fit(rectangle(.7),2,{},18,data)
