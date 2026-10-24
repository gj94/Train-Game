extends RefCounted
## Plant roots on the emitted fine/coarse terrain, keeping dry-land vegetation
## out of precise mapped water even where the 8 m land-cover mask says grass.
static func height(c,p: Vector2,radius: float=0) -> float:
	var waters: Array=c.water_levels
	var border=c.get("border_water_levels")
	if border!=null and not border.is_empty() and (p.x<radius or p.y<radius or p.x>512-radius or p.y>512-radius):waters=border
	for water in waters:
		for delta in [Vector2.ZERO,Vector2(radius,0),Vector2(-radius,0),Vector2(0,radius),Vector2(0,-radius)]:
			if c._inside(p+delta-water.get("offset",Vector2.ZERO),water.geometry):return INF
	return preload("res://game/geographic_road_support.gd").surface_height(c,p)
