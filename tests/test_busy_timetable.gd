extends RefCounted
const Kerala := preload("res://sim/layouts/kerala_coast.gd")
const Busy := preload("res://sim/timetables/kerala_busy.gd")
const Stock := preload("res://sim/stock/ported_stock.gd")
var _world: RailWorld

func world() -> RailWorld:
	if _world==null:_world=Kerala.build_traffic(true)
	return _world

func codes(t: Train) -> Array:
	return t.timetable.stops.map(func(s):return s.block.get_slice("_P",0))

func test_exactly_two_full_route_vbs_one_each_direction_with_major_calls():
	var trains: Array=world().trains.values().filter(func(t):return t.stock_kind.begins_with("ported:vb"))
	if trains.size()!=2:return "Expected one VB in each direction, no short VB shuttles"
	var directions:=[]
	for t: Train in trains:
		var stops:=codes(t);var expected: Array=Busy.VB_CALLS.duplicate()
		if t.path[0].dir<0:expected.reverse()
		if stops!=expected:return t.id+" misses a major call or does not cover the full line"
		if t.dispatch_priority!=100:return "VB must have the highest traffic priority"
		directions.append(t.path[0].dir)
	directions.sort()
	return directions==[-1,1]

func test_multiple_long_distance_workings_in_both_directions():
	var full:={1:0,-1:0};var intercity:={1:0,-1:0}
	for t: Train in world().trains.values():
		var stops:=codes(t);var dir: int=t.path[0].dir
		if stops.has("ERS") and stops.has("NCJ"):full[dir]+=1
		elif stops.has("ERS") and stops.has("TVC"):intercity[dir]+=1
	return full[1]>=10 and full[-1]>=10 and intercity[1]>=5 and intercity[-1]>=5

func test_regional_calls_follow_open_reachable_platforms():
	var w:=world()
	for row in Busy.definitions(w):
		if row[9] not in ["passenger","regional"]:continue
		var t: Train=w.trains[row[0]];var calls:=codes(t)
		var first: int=w.stations.find(w.stations.filter(func(s):return s.code==calls[0])[0])
		var last: int=w.stations.find(w.stations.filter(func(s):return s.code==calls[-1])[0])
		for i in range(mini(first,last),maxi(first,last)+1):
			var st: Dictionary=w.stations[i]
			if not st.passenger_open:continue
			var served: bool=st.platform_tracks.any(func(r):return st.platform_details[r].platform_width>0 and w.graph.allows(r,row[3]))
			if served!=calls.has(st.code):return t.id+" incorrect local call at "+st.code
	return w.trains.K1.timetable.stops.size()==55 and not codes(w.trains.K1).has("TNU")

func test_local_and_intercity_formations_are_seated_and_speeds_are_not_capped():
	var w:=world()
	for row in Busy.definitions(w):
		var t: Train=w.trains[row[0]];var spec:=Train.new("SPEC",1)
		Stock.configure(spec,row[2],Busy.PROFILES[row[9]].formation)
		if t.rake_profile!=spec.rake_profile or not is_equal_approx(t.length,spec.length):return t.id+" incorrect formation"
		if t.max_speed!=spec.max_speed or t.max_speed<110.0/3.6:return t.id+" has an artificial speed cap"
		if row[9] in ["passenger","regional","intercity"] and t.rake_profile!="passenger":return "Seated working has sleeper rake"
	return true

func test_workings_cover_morning_evening_and_have_feasible_origin_headways():
	var origins:={};var morning:=0;var evening:=0;var last:=0.0
	for t: Train in world().trains.values():
		var key: String=codes(t)[0]+str(t.path[0].dir)
		if not origins.has(key):origins[key]=[]
		origins[key].append(t.timetable.departure)
		if t.timetable.departure<11*3600:morning+=1
		if t.timetable.departure>=17*3600:evening+=1
		last=maxf(last,t.timetable.departure)
	for key: String in origins:
		var times: Array=origins[key]
		times.sort()
		for i in range(1,times.size()):
			# Following trains may be grouped to leave an opposing crossing window.
			# Full-day traffic audits establish capacity; forbid near-simultaneous
			# departures here rather than enforcing a uniform half-hour pattern.
			if times[i]-times[i-1]<300:return "Over-clustered origin departures at "+key
	return morning>=20 and evening>=20 and last>=22*3600

func test_dwell_and_arrivals_include_junction_work_and_remain_monotone():
	for t: Train in world().trains.values():
		var tt=t.timetable
		for i in range(1,tt.stops.size()):
			var code: String=tt.stops[i].block.get_slice("_P",0)
			if tt.planned_arrival(i)<=tt.planned_departure(i-1):return "Running time ignores previous dwell"
			if code in Busy.JUNCTIONS and tt.stops[i].dwell_minutes<2:return "Junction dwell too short"
			if tt.stops[i].dwell_minutes<1:return "Unrealistic half-minute stop"
		if codes(t).has("ERS") and codes(t).has("NCJ"):
			var hours: float=tt.stops[-1].minutes_from_origin/60.0
			if hours<3 or hours>9:return t.id+" implausible full-route timing: "+str(hours)
	return true

func test_southbound_vb_can_catch_default_passenger_before_tvc():
	var w:=world();var slow: Train=w.trains.K1;var fast: Train=w.trains.B001
	if fast.timetable.departure<=slow.timetable.departure:return "VB should depart behind the player"
	var slow_index: int=codes(slow).find("QLN");var fast_index: int=codes(fast).find("QLN")
	return fast.dispatch_priority>slow.dispatch_priority and fast.timetable.planned_arrival(fast_index)<slow.timetable.planned_arrival(slow_index)

func test_authored_day_retains_legacy_benchmark_fixture():
	var legacy:=Kerala.build_traffic(false)
	return legacy.trains.size()==32 and legacy.trains.has("K3") and not legacy.trains.has("B001")

func test_importable_timetable_matches_defaults_and_decodes_all_workings():
	var pack=preload("res://sim/service_pack.gd")
	var text:=FileAccess.get_file_as_string("res://art/timetables/kerala-coast-100-through-services.json")
	var result: Dictionary=pack.decode(text)
	if not result.ok:return result.reason
	var expected: Dictionary=JSON.parse_string(JSON.stringify(pack.defaults("kerala_coast",true)))
	var actual: Dictionary=JSON.parse_string(text)
	actual.name=expected.name
	return actual==expected and result.world.trains.size()==100
