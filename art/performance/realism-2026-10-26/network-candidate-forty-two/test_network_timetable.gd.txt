extends RefCounted
const Network := preload("res://sim/timetables/kerala_network.gd")
const Kerala := preload("res://sim/layouts/kerala_coast.gd")
const Pack := preload("res://sim/service_pack.gd")
const Stock := preload("res://sim/stock/ported_stock.gd")
const Clock := preload("res://sim/world_clock.gd")

func test_193_services_have_day_and_night_traffic_and_most_are_through_journeys():
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/timetables/kerala-coast-network.json"))
	if data.services.size()!=193:return "Wrong service count"
	var counts:={local=0,mail=0,superfast=0,vb=0};var hours:={};var boundaries:=0
	for row in data.services:
		counts[row.journey.category]+=1
		var hour:=floori(Clock.parse_time(row.departure)/3600)
		hours[hour]=int(hours.get(hour,0))+1
		if row.stops.any(func(s):return s.has("boundary")):boundaries+=1
		if row.has("speed_limit_kmh") or row.has("forced_passes"):return "Artificial category speed or passing control"
		for call in row.stops:
			if call.dwell_minutes>3:return "Padded passenger dwell"
	if counts!={local=40,mail=89,superfast=56,vb=8} or boundaries!=153:return "Wrong category/through mix"
	for hour in 24:
		if int(hours.get(hour,0))<3:return "Missing overnight/day spread at hour "+str(hour)
	return true

func test_both_dispatchers_use_identical_authored_calls_stock_and_departures():
	var a: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/timetables/kerala-coast-network.json"))
	var b: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/timetables/kerala-coast-network-v2.json"))
	if a.services!=b.services:return "Planner comparison is confounded by changed services"
	for data in [a,b]:
		var result:=Pack.build(data)
		if not result.ok:return result.reason
		if result.world.dispatcher().predictive.enabled!=(data.dispatcher=="predictive"):return "Wrong engine"
	return true

func test_category_hierarchy_comes_from_calls_and_unmodified_stock_physics():
	var w:=Kerala.build(true);var durations:=[];var stops:=[]
	for category in ["local","mail","superfast","vb"]:
		var row:={id="PROBE",category=category,first="ERS",last="NCJ",direction=1,origin="ERS",destination="NCJ",departure="06:00",stock="vb16" if category=="vb" else ("icf" if category=="local" else "lhb")}
		var result:=Network.service(w,row)
		if not result.ok:return result.reason
		durations.append(result.data.stops[-1].minutes_from_origin);stops.append(result.data.stops.size())
	for i in 3:
		if stops[i]<=stops[i+1] or durations[i]<=durations[i+1]:return "Call/time hierarchy failed: "+str(stops)+" / "+str(durations)
	# Actual Train acceleration, not a timetable category multiplier.
	var local:=Train.new("L",1);Stock.configure(local,"icf","passenger")
	var express:=Train.new("E",1);Stock.configure(express,"lhb","express")
	var vb:=Train.new("V",1);Stock.configure(vb,"vb16","fixed")
	for t in [local,express,vb]:
		t.controller=1
		for i in 600:t.update_speed(.1)
	return vb.speed>local.speed+10 and vb.speed>express.speed+10 and local.max_speed==110.0/3.6 and express.max_speed==140.0/3.6

func test_network_checkpoints_preserve_boundary_identity_without_mutating_source():
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/timetables/kerala-coast-network-v2.json"))
	var result:=Pack.build(data)
	if not result.ok:return result.reason
	var snapshot=preload("res://sim/world_snapshot.gd")
	var before: Dictionary=snapshot.capture(result.world)
	var restored: Dictionary=snapshot.restore(before)
	if not restored.ok:return restored.reason
	return var_to_bytes(snapshot.capture(restored.world))==var_to_bytes(before) and restored.world.scenery.network_portals.size()==4

func test_selected_services_reproduce_source_records_without_hidden_edits():
	var selection=JSON.parse_string(FileAccess.get_file_as_string("res://art/timetables/kerala-coast-network-service-selection.json"))
	var overrides=JSON.parse_string(FileAccess.get_file_as_string("res://art/timetables/kerala-coast-network-departure-overrides.json"))
	var source: Dictionary=Network.pack(Kerala.build(true),true)
	var expected_removed:=["M021","M025","M032","M043","M052","M055","M056","M057","M058","M066","M067","M089","M090","M098","M099"]
	var removed: Array=selection.excluded.map(func(edit):return edit.service)
	removed.sort()
	if removed!=expected_removed or source.services.size()!=208:return "Selection changed without a reviewed population update"
	var by_id:={}
	for service in source.services:by_id[service.id]=service
	for edit in overrides.changes:
		if by_id[edit.service].departure!=edit.from:return "Departure source mismatch"
		by_id[edit.service].departure=edit.to
	var retained: Array=source.services.filter(func(service):return not removed.has(service.id))
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://art/timetables/kerala-coast-network-v2.json"))
	if JSON.parse_string(JSON.stringify(retained))!=data.services:return "A retained service has an unreviewed edit"
	return by_id.K1.departure=="06:00" and retained.size()==193
