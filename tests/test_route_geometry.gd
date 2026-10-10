extends RefCounted
const Layout:=preload("res://sim/layouts/kerala_coast.gd")
var _layout
var _world
func layout():
	if _layout==null:
		_layout=Layout.new();_world=_layout._build()
	return _layout
func world() -> RailWorld:
	layout();return _world

func test_offset_tracks_are_continuous_at_alignment_sample_boundaries():
	var route=layout()
	for index in range(5,route.distance.size()-5,19):
		var s: float=route.distance[index]
		for offset in [-80.0,0.0,80.0]:
			var a: Array=route.point(s-.001,offset);var b: Array=route.point(s+.001,offset)
			if Vector2(a[0]-b[0],a[2]-b[2]).length()>.01:return "Offset jumps at "+str(s)+" m, offset "+str(offset)
	return true

func test_no_abrupt_sample_bends_on_actual_running_graph():
	var w:=world()
	for id in w.graph.edges:
		var pts: PackedVector3Array=w.graph.edges[id].local_points
		for i in range(1,pts.size()-1):
			var a:=pts[i]-pts[i-1];a.y=0
			var b:=pts[i+1]-pts[i];b.y=0
			if minf(a.length(),b.length())<1:continue
			if rad_to_deg(a.angle_to(b))>3:return "Abrupt rail bend on "+id
	return true

func test_ladder_transitions_are_long_enough_for_lateral_displacement():
	var w:=world()
	for id in w.graph.edges:
		if not "_LADDER_" in id:continue
		var e: Dictionary=w.graph.edges[id]
		var shift: float=absf(w.graph.nodes[e.a].lateral-w.graph.nodes[e.b].lateral)
		if e.chainage_end-e.chainage_start+0.01<maxf(100,sqrt(6*shift*250)):return "Short ladder: "+id
	return true

func test_double_running_lines_keep_their_physical_sides():
	var route=layout()
	var paired:={}
	for section in route.data.sections:
		if section.tracks!=2:continue
		if section.up_offset-section.down_offset<4.2:return "Pinched double line "+section.a+"–"+section.b
		paired[section.a]=true;paired[section.b]=true
	for station in world().stations:
		if not paired.has(station.code):continue
		var roads: Array=station.operating_roads
		if roads[1].offset-roads[0].offset<4.2:return "Main-line side reversal at "+station.code
	return true

func test_csv_faces_and_full_rake_capacity_survive_smoothing():
	var ops: Dictionary=layout().operations
	var counts:={}
	for st in ops.stations:counts[st.code]=st.register_platforms
	var w:=world()
	for st in w.stations:
		var faces:=preload("res://sim/platform_faces.gd").entries(st)
		if faces.size()!=counts[st.code]:return "CSV platform count changed at "+st.code
		if not st.passenger_open:continue
		for face in faces:
			if preload("res://sim/berth_clearance.gd").capacity(w,face.edge)<550:return "Full rake no longer fits "+face.edge
	return true

func test_outer_yards_and_approaches_are_grounded_without_filling_bridges():
	var w:=world()
	var geo=preload("res://game/geographic_data.gd").new(w.scenery.route)
	geo.install_railway(w)
	geo.station_sites=preload("res://game/coastal_station_sites.gd").build(w)
	for id in w.graph.edges:
		if not (id.begins_with("QLN_") or id.begins_with("TVC_")):continue
		var edge: Dictionary=w.graph.edges[id]
		for s in range(10,int(edge.length)-10,25):
			var p:=w.graph.position(id,s)
			if geo.nearest_rail(p.x,p.z).bridge:continue
			if absf(geo.ground_at(p.x,p.z)-(p.y-.15))>.15:return "Formation height mismatch on "+id
	var bridge: Array=layout().point(6600)
	var surface: float=geo.ground_at(bridge[0],bridge[2])
	return geo.nearest_rail(bridge[0],bridge[2]).bridge and surface<=bridge[1]-.79

func test_every_booked_busy_call_remains_reachable_and_fits_its_formation():
	var w:=Layout.build_traffic(true)
	for t: Train in w.trains.values():
		for i in t.timetable.stops.size():
			var stop: Dictionary=t.timetable.stops[i]
			if preload("res://sim/berth_clearance.gd").capacity(w,stop.block,true)<t.length:return t.id+" exceeds "+stop.block
			if i==0:continue
			var previous: Dictionary=t.timetable.stops[i-1]
			if is_inf(w._stop_distance(previous.block,previous.direction,previous.s,stop,[])):return t.id+" cannot reach "+stop.block
	return true
