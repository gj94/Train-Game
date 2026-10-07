extends RefCounted
const Foundations := preload("res://game/geographic_foundations.gd")
const Bridges := preload("res://game/geographic_bridges.gd")

func test_building_footing_follows_sloping_ground_on_every_side():
	var ground:=func(x,z):return x*.2+z*.1
	var ring:=PackedVector2Array([Vector2(0,0),Vector2(24,0),Vector2(24,16),Vector2(0,16)])
	var points:=Foundations.outline(ring,ground)
	if points.size()<20:return "Footprint edges were not sampled"
	for p in points:
		if absf(p.y-ground.call(p.x,p.z))>.0001:return "Footing does not touch terrain"
	return points.map(func(p):return p.y).max()>ground.call(12,8)+2

func test_ground_sampler_matches_both_rendered_cell_triangles():
	var ground:=func(x,z):return 8.0 if x==8 and z==8 else 0.0
	return absf(Foundations.surface_height(ground,6,2)-2)<.0001 and absf(Foundations.surface_height(ground,2,6)-2)<.0001

func test_bridge_decks_keep_fractional_endpoints_and_chunk_seams_closed():
	var e:={chainage_start=0.0,chainage_end=512.0,length=512.0}
	var spans:=[{start=250.23,end=302.67}]
	var a: Array=Bridges.intervals(e,0,256,spans)
	var b: Array=Bridges.intervals(e,256,512,spans)
	return a[0].start==250.23 and a[0].end==b[0].start and b[0].end==302.67

func test_first_two_stops_have_bridge_supports_across_mapped_backwaters():
	var data=preload("res://game/geographic_data.gd").new()
	return not data.bridge_at(4250).is_empty() and not data.bridge_at(6600).is_empty() and data.bridge_at(5100).is_empty()
