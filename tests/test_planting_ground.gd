extends RefCounted
const Site=preload("res://game/geographic_planting_site.gd")
const Ribbon=preload("res://game/geographic_ground_ribbon.gd")
func test_plant_roots_match_actual_refined_bank_triangles():
	var c=preload("res://tests/test_shore_cells.gd").new().bank()
	var checked:=0;var coarse_difference:=false
	for x in range(64,80):
		for z in range(64,80):
			var p:=Vector2(x+.3,z+.7);var height:=Site.height(c,p)
			if not is_finite(height):continue
			for cell in Ribbon._cell(c,Vector2(floorf(p.x/8)*8,floorf(p.y/8)*8)):
				if not Geometry2D.is_point_in_polygon(p,cell.ring):continue
				if absf(height-Ribbon.plane_height(cell.plane,p))>.00001:return "Root misses rendered triangle"
				checked+=1
			var coarse=preload("res://game/geographic_foundations.gd").surface_height(c._ground,p.x,p.y)
			if absf(coarse-height)>.1:coarse_difference=true
	return checked>10 and coarse_difference
func test_precise_water_overrides_dry_landcover_for_planting():
	var c=preload("res://tests/test_shore_cells.gd").new().bank()
	return c._class_at(30,30)==0 and not is_finite(Site.height(c,Vector2(30,30)))
func test_root_envelope_cannot_overhang_the_water_edge():
	var c=preload("res://tests/test_shore_cells.gd").new().bank()
	var p=Vector2(75.2,60)
	return is_finite(Site.height(c,p)) and not is_finite(Site.height(c,p,.7))
func test_dry_islands_remain_plantable():
	var c=preload("res://tests/test_shore_cells.gd").new().bank()
	c.water_levels=[{height=.8,geometry={type="Polygon",coordinates=[[[0,0],[100,0],[100,100],[0,100],[0,0]],[[20,20],[40,20],[40,40],[20,40],[20,20]]]}}]
	return is_finite(Site.height(c,Vector2(30,30),.7)) and not is_finite(Site.height(c,Vector2(10,10),.7))
