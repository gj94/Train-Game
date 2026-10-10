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
