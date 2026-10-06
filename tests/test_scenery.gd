extends RefCounted
const Plan := preload("res://game/scenery_plan.gd")
const Clearance := preload("res://game/scenery_clearance.gd")
const Line := preload("res://sim/layouts/southern_corridor.gd")

func test_clearance_checks_segment_interiors_and_negative_cells():
	var graph={edges={a={points=PackedVector3Array([Vector3(-130,0,-70),Vector3(140,0,65)])}}}
	var index=Clearance.new(graph)
	if index.clear_point(Vector3(5,0,-2.5),2): return "Mid-segment railway obstruction missed"
	if not index.clear_point(Vector3(-130,0,-80),9): return "Clear site incorrectly rejected"
	if index.clear_rect(Rect2(-129,-72,3,4),0): return "Negative-cell track intersection missed"
	if index.clear_rect(Rect2(-5,-12,20,20),0): return "Crossing segment outside both rectangle endpoints missed"
	if not index.clear_rect(Rect2(-100,-100,10,10),5): return "Separate footprint incorrectly rejected"
	return true

func test_settlements_and_fields_clear_actual_railway_and_roads():
	var plan=Plan.new()
	plan.build(Line.build())
	var zones:={}
	for building in plan.buildings:
		zones[building.zone]=zones.get(building.zone,0)+1
		if not plan.clearance.clear_rect(building.rect,18): return "Building inside railway margin: "+building.zone
		for road in plan.roads:
			if building.rect.intersects(road.rect): return "Building over a road: "+str(building.position)
	for i in plan.buildings.size():
		for j in range(i+1,plan.buildings.size()):
			if plan.buildings[i].rect.intersects(plan.buildings[j].rect): return "Overlapping building footprints"
	for field in plan.fields:
		if not plan.clearance.clear_rect(field.rect,19): return "Crops inside railway margin"
		for road in plan.roads:
			if field.rect.intersects(road.rect): return "Crops covering a road"
	for zone in ["CPM_front","CPM_back","MRT_front","MRT_back","KDP_front","KDP_back","village_0","village_1","village_2","village_3"]:
		if zones.get(zone,0)<30: return "Missing settlement: "+zone
	print("Scenery plan: ",plan.buildings.size()," buildings; ",plan.fields.size()," fields; ",plan.roads.size()," road sections; ",plan.props.size()," props; ",plan.tree_sites.size()," planted trees")
	return true

func test_scenery_plan_is_reproducible_without_advancing_simulation():
	var world=Line.build()
	var before=world.time
	var a=Plan.new()
	var b=Plan.new()
	a.build(world)
	b.build(world)
	return a.buildings==b.buildings and a.fields==b.fields and a.tree_sites==b.tree_sites and world.time==before

func test_building_clearance_footprints_enclose_exported_model_bounds():
	var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/scenery/manifest.json"))
	for kind in Plan.SHAPES:
		if not catalog.has(kind): return "Missing model manifest: "+kind
		var item: Dictionary=catalog[kind]
		var half: Vector2=Plan.SHAPES[kind]*.5
		if not item.has("godot_min"): return "Missing evaluated model bounds: "+kind
		var a: Array=item.godot_min
		var b: Array=item.godot_max
		if a[0]<-half.x or b[0]>half.x or a[2]<-half.y or b[2]>half.y: return "Placement footprint too small: "+kind
		if item.surfaces!=1: return "Architecture export lost single-surface batching: "+kind
	return true

func test_land_index_blocks_roads_and_buildings_across_cell_boundaries():
	var plan=Plan.new()
	plan.buildings=[{rect=Rect2(-66,-10,8,16)}]
	plan.roads=[{rect=Rect2(63,-4,70,8)}]
	plan.fields=[{rect=Rect2(100,40,40,40)}]
	plan._index_land()
	for p in [Vector3(-62,0,0),Vector3(64,0,0),Vector3(132,0,0),Vector3(125,0,55)]:
		if plan.clear_land_point(p): return "Occupancy index missed a reserved site"
	return plan.clear_land_point(Vector3(20,0,20),3) and not plan.clear_land_point(Vector3(61,0,0),3)

func test_decorative_traffic_stays_on_roads_and_wraps_smoothly():
	var traffic=load("res://game/road_traffic.gd")
	var points:=PackedVector3Array([Vector3(-100,.14,0),Vector3(100,.14,0),Vector3(100,.14,33),Vector3(-100,.14,33)])
	for reverse in [false,true]:
		var route: Curve3D=traffic.make_route(points,reverse)
		var length:=route.get_baked_length()
		for metre in int(length):
			var pose: Transform3D=traffic.pose_at(route,metre)
			var p:=pose.origin
			var on_road:=absf(p.z)<2.5 or absf(p.z-33)<2.5 or absf(p.x-100)<2.5 or absf(p.x+100)<2.5
			if not on_road: return "Decorative vehicle left the road at "+str(p)
			if not pose.is_finite(): return "Invalid traffic transform"
		var before: Transform3D=traffic.pose_at(route,length-.01)
		var after: Transform3D=traffic.pose_at(route,.01)
		if before.origin.distance_to(after.origin)>.05 or before.basis.z.dot(after.basis.z)<.999: return "Traffic loop teleports at seam"
	return true

func test_scenery_library_does_not_keep_unloaded_world_alive():
	var owner=load("res://game/world_view.gd").new()
	var ref=weakref(owner)
	var library=load("res://game/scenery_library.gd").new(owner)
	owner.scenery_library=library
	owner=null
	if ref.get_ref()!=null: return "Scenery asset cache retains the old world after reload"
	return library.view==null

func test_raised_curbs_leave_junctions_and_bus_bays_open():
	var plan=Plan.new()
	var main={a=Vector3(-40,.1,0),b=Vector3(40,.1,0),rect=Rect2(-44,-4,88,8),width=8}
	plan.roads=[main,{a=Vector3(0,.1,-30),b=Vector3(0,.1,30),rect=Rect2(-3,-33,6,66),width=6}]
	plan.bus_bays=[{rect=Rect2(18,4,16,5)}]
	for side in [-1,1]:
		var spans=plan.curb_sections(main,side*5.05,.8)
		for span: Vector2 in spans:
			for metre in range(ceili(span.x),floori(span.y)+1):
				var x=-40+metre
				if absf(x)<3.3: return "Raised pavement crosses the junction"
				if side==1 and x>17.8 and x<34.2: return "Pavement blocks the bus bay"
		if spans.is_empty(): return "Unrelated sidewalk was removed"
	return true
