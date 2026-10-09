extends RefCounted
const Sites:=preload("res://game/coastal_station_sites.gd")

func bins() -> Dictionary:
	var zone:={centre=Vector3(510,2,510),basis=Basis.IDENTITY,extent=Vector2(40,30),solid_centre=Vector3(510,2,518),solid_extent=Vector2(20,10),height=1.8,code="TEST"}
	return {Vector2i(0,0):[zone],Vector2i(0,1):[zone],Vector2i(1,0):[zone],Vector2i(1,1):[zone]}

func test_building_crossing_site_is_removed_even_when_centre_is_outside():
	var ring:=PackedVector2Array([Vector2(519,500),Vector2(559,500),Vector2(559,508),Vector2(519,508)])
	if not Sites.intersect(bins(),ring,Vector3.ZERO):return "A building crossing the station apron survived because its centre is outside"
	return not Sites.intersect(bins(),PackedVector2Array([Vector2(570,500),Vector2(580,500),Vector2(580,510),Vector2(570,510)]),Vector3.ZERO)

func test_forecourt_keeps_access_road_but_excludes_building_overlap():
	var data:=bins()
	if not Sites.contains(data,510,500):return "Forecourt not reserved for station scenery"
	if Sites.contains(data,510,500,0,true):return "Approach road outside building was suppressed"
	return Sites.contains(data,510,518,0,true)

func test_planting_clearance_crosses_tile_boundary():
	var data:=bins()
	if Sites.contains(data,535,510):return "Point unexpectedly lies inside apron"
	if not Sites.contains(data,535,510,12):return "Tree crown intrudes from adjacent tile"
	return not Sites.contains(data,550,510,12)

func test_ground_infill_does_not_raise_lower_terrain_or_affect_outside():
	var data:=bins()
	if not is_equal_approx(Sites.ground(data,510,510,6),1.8):return "Terrain would bury the station plinth"
	if not is_equal_approx(Sites.ground(data,510,510,-1),-1):return "Lower ground was raised instead of using a retaining foundation"
	return is_equal_approx(Sites.ground(data,600,600,6),6)
