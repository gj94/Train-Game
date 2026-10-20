extends RefCounted
const Grid:=preload("res://game/geographic_scenery_occupancy.gd")
func rectangle(a: Vector2,b: Vector2) -> PackedVector2Array:
	return PackedVector2Array([a,Vector2(b.x,a.y),b,Vector2(a.x,b.y)])
func rail():
	var grid:=Grid.new();grid.add_road(Vector2(-200,0),Vector2(200,0),3)
	return grid
func platform():
	var grid:=Grid.new();grid.add_polygon(rectangle(Vector2(-20,-20),Vector2(20,20)),2)
	return grid
func test_track_through_footprint_is_rejected_even_when_all_corners_are_clear():
	return not rail().clear_polygon(rectangle(Vector2(-50,-50),Vector2(50,50)))
func test_track_fully_inside_large_building_is_rejected_across_grid_cells():
	return not rail().clear_polygon(rectangle(Vector2(-500,-500),Vector2(500,500)))
func test_overhanging_roof_respects_rail_envelope_and_margin():
	return not rail().clear_polygon(rectangle(Vector2(198,2),Vector2(300,25)),1)
func test_building_clear_of_track_is_retained():
	return rail().clear_polygon(rectangle(Vector2(-50,5),Vector2(50,50)),1)
func test_platform_fully_inside_building_is_rejected():
	return not platform().clear_polygon(rectangle(Vector2(-50,-50),Vector2(50,50)))
func test_building_fully_inside_platform_is_rejected():
	return not platform().clear_polygon(rectangle(Vector2(-1,-1),Vector2(1,1)))
func test_platform_and_building_margins_both_count():
	return not platform().clear_polygon(rectangle(Vector2(22,0),Vector2(30,10)),1)
func test_nearby_building_outside_both_margins_is_retained():
	return platform().clear_polygon(rectangle(Vector2(24,0),Vector2(30,10)),1)
func test_invalid_empty_footprint_cannot_be_approved():
	return not rail().clear_polygon(PackedVector2Array())

func test_mapped_sidings_reserve_building_envelopes_before_feature_render_order():
	var chunk=preload("res://game/geographic_scenery_chunk.gd").new(null,{},null)
	chunk._register_occupied([{kind="rail",tags={railway="rail"},geometry={type="LineString",coordinates=[[-200,0],[200,0]]}}])
	return not chunk.mapped_rail_clearance.clear_polygon(rectangle(Vector2(-30,-30),Vector2(30,30)),1.2) and chunk.mapped_rail_clearance.clear_polygon(rectangle(Vector2(-30,8),Vector2(30,30)),1.2)

func test_roads_reserve_complete_building_footprints_but_tunnels_and_paths_do_not():
	var script=preload("res://game/geographic_scenery_chunk.gd")
	for tags in [{highway="primary",bridge="yes",layer="1"},{highway="residential"},{highway="primary",tunnel="yes",layer="-1"},{highway="footway"}]:
		var chunk=script.new({station_sites={}}, {}, null)
		chunk._register_occupied([{kind="road",tags=tags,
			geometry={type="LineString",coordinates=[[-200,0],[200,0]]}}])
		var ring:=rectangle(Vector2(-30,-30),Vector2(30,30))
		var blocked: bool=tags.get("tunnel","no")=="no" and tags.highway!="footway"
		if chunk.mapped_road_clearance.clear_polygon(ring,1.0)==blocked:return "Wrong road/footprint reservation: "+str(tags)
		if not chunk.mapped_road_clearance.clear_polygon(rectangle(Vector2(-30,8),Vector2(30,30)),1.0):return "Clear neighbouring building removed"
		if blocked:
			# Actual builder must exit before allocating a foundation or facade.
			chunk.batch=preload("res://game/geographic_mesh.gd").new()
			chunk._building({id="crossing-building",tags={building="yes"},
				geometry={type="Polygon",coordinates=[[[-30,-30],[30,-30],[30,30],[-30,30],[-30,-30]]]}})
			if not chunk.batch.surfaces.is_empty():return "Building still rendered across the road"
	return true
