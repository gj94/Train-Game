extends RefCounted
const Plans:=preload("res://game/station_precinct_plan.gd")
const Sites:=preload("res://game/coastal_station_sites.gd")
const Civil:=preload("res://game/station_platform_civil.gd")
const Boundary:=preload("res://game/station_platform_boundary.gd")
const Access:=preload("res://game/station_road_access.gd")
static var _world
static var _bins:={}
func fixture():
	if _world==null:
		_world=preload("res://sim/layouts/kerala_coast.gd").build()
		_bins=Plans.build(_world)
	return _world

func test_every_authored_station_and_ers_annex_has_grounding_and_clutter_exclusion():
	var w=fixture();var count:=0
	for station in w.stations:
		if not preload("res://game/authored_station.gd").available(station.code) and station.code!="TNU":continue
		var zones:=Plans.entries(_bins,station)
		if zones.is_empty():return "Missing precinct "+station.code
		for zone in zones:
			count+=1
			if not Sites.contains(_bins,zone.building.x,zone.building.z):return "Unprotected building "+zone.id
			if zone.halt:continue
			var p: Vector3=zone.building+zone.basis.z*(zone.front-6)
			for original in [-10.0,100.0]:
				if absf(Plans.ground(_bins,p.x,p.z,original)-zone.height)>.001:return "Floating or buried forecourt "+zone.id
	if count!=57:return "Expected 56 station footprints plus ERS east; got "+str(count)
	return true

func test_civil_grading_does_not_raise_running_tracks_at_any_station():
	var w=fixture()
	for station in w.stations:
		for edge: String in w.graph.edges:
			if not edge.begins_with(station.code+"_"):continue
			var length: float=w.graph.edges[edge].length
			for t in [.2,.5,.8]:
				var p: Vector3=w.graph.position(edge,length*t)
				if absf(Plans.ground(_bins,p.x,p.z,p.y-.15)-(p.y-.15))>.03:return "Earthwork affects running line "+edge
		# platform_tracks reliably includes all actual passenger roads.
		for edge: String in station.platform_tracks:
			var p: Vector3=w.graph.position(edge,w.graph.edges[edge].length*.5)
			if absf(Plans.ground(_bins,p.x,p.z,p.y-.15)-(p.y-.15))>.03:return "Earthwork enters track "+edge
	return true

func test_single_platform_kumbalam_has_no_generic_footbridge():
	var w=fixture()
	var kumm: Dictionary=w.stations.filter(func(s):return s.code=="KUMM")[0]
	return not Civil.has_bridge(kumm) and Civil.has_bridge(w.stations.filter(func(s):return s.code=="TUVR")[0])

func test_island_faces_do_not_receive_perimeter_fences():
	var station:={operating_roads=[{offset=-10},{offset=0},{offset=10}]}
	if Boundary.outer_face(station,{offset=0,platform_side=1,platform_width=4}):return "Fence obstructs island platform"
	return Boundary.outer_face(station,{offset=-10,platform_side=-1,platform_width=4})

func test_access_links_leave_through_real_boundary_gates_and_keep_roads_visible():
	var w=fixture();var total:=0
	for station in w.stations:
		for plan in Plans.entries(_bins,station):
			for connection in plan.access:
				total+=1
				var a: Vector3=connection[0];var b: Vector3=connection[1]
				var local: Vector3=plan.basis.inverse()*(a-plan.building)
				if absf(local.z-plan.outer)>.08 and absf(absf(local.x)-plan.half)>.08:return "Gate is inside fence "+plan.id
				if Sites.road_blocked(_bins,b.x,b.z,2):return "Mapped road connection is suppressed "+plan.id
				if absf(a.y-b.y)/Vector2(a.x,a.z).distance_to(Vector2(b.x,b.z))>.101:return "Implausibly steep road"
	if total<40:return "Most station entrances were disconnected"
	return true

func test_access_cannot_cross_water_or_buildings():
	var options:=[{a=Vector3(0,0,0),b=Vector3(20,0,0),distance=20,gate=0}]
	var block:={kind="water",geometry={type="Polygon",coordinates=[[[8,-10],[12,-10],[12,10],[8,10],[8,-10]]]}}
	if not Access.clear_links(options,[block],[Vector2.ZERO]).is_empty():return "Spur crosses water"
	block.kind="building"
	if not Access.clear_links(options,[block],[Vector2.ZERO]).is_empty():return "Spur crosses building"
	return Access.clear_links(options,[],[]).size()==1

func test_halting_shelter_does_not_raise_entire_trackside_terrain():
	var w=fixture()
	var station: Dictionary=w.stations.filter(func(s):return s.code=="VRLR")[0]
	var plan: Dictionary=Plans.entries(_bins,station)[0]
	return plan.halt and plan.access.is_empty() and is_equal_approx(Plans.ground(_bins,plan.centre.x,plan.centre.z,-2),-2)
