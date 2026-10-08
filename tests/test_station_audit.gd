extends RefCounted
const Kerala=preload("res://sim/layouts/kerala_coast.gd")
const ROOT="res://data/routes/kerala_coast/"
func test_every_station_has_research_evidence_without_claiming_certification():
	var audit: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"station-audit.json"))
	var route: Dictionary=Kerala.source()
	if audit.stations.size()!=route.stations.size():return "Missing station evidence"
	for i in route.stations.size():
		var entry: Dictionary=audit.stations[i]
		if entry.code!=route.stations[i].code or not entry.browser_source.begins_with("https://indiarailinfo.com/"):return "Unlinked station"
		if entry.track_count_status.is_empty():return "Missing confidence qualifier"
	return true
func test_all_nameboards_have_three_languages_and_tamil_in_tamil_nadu():
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"station-signs.json"))
	if data.size()!=56:return "Missing sign"
	for code in data:
		var s: Dictionary=data[code]
		if s.board_name.is_empty() or s.board_local_name.is_empty() or s.board_hindi.is_empty():return code+": missing script"
		if code in ["KZTW","KZT","PYD","ERL","VRLR","NJT","NCJ"]:
			var tamil:=false
			for c in s.board_local_name: tamil=tamil or (c.unicode_at(0)>=0x0B80 and c.unicode_at(0)<=0x0BFF)
			if not tamil:return "Missing Tamil: "+code
	return true
func test_commissioned_southern_double_line_and_nagercoil_town_loop():
	var w:=Kerala.build()
	for sec in w.scenery.route.sections:
		if sec.a in ["ERL","VRLR","NJT"] and sec.tracks!=2:return "Open second line omitted: "+sec.a
	var town: Dictionary=w.stations.filter(func(s):return s.code=="NJT")[0]
	var halt: Dictionary=w.stations.filter(func(s):return s.code=="VRLR")[0]
	return town.platform_tracks.size()==3 and not town.through_halt and halt.platform_tracks.size()==2 and halt.through_halt
func test_goods_roads_are_not_passenger_platforms():
	var w:=Kerala.build()
	var station: Dictionary=w.stations.filter(func(s):return s.code=="QLN")[0]
	for road in station.operating_roads:
		if road.road>=7 and road.platform_width!=0:return "Goods road acquired a passenger platform"
	return true
