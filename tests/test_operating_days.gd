extends RefCounted
const Days:=preload("res://persistence/operating_days.gd")
const Pack:=preload("res://sim/service_pack.gd")

func test_alternate_days_cannot_alias_checkpoint_directories():
	var standard:=Days.definition("standard");var intensive:=Days.definition("intensive")
	return standard.starts!=intensive.starts and standard.times!=intensive.times and Days.definition("missing").id=="standard"

func test_intensive_pack_keeps_original_day_and_formation_limits():
	var a: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/timetables/kerala-coast-100-through-services.json"))
	var b: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/timetables/kerala-coast-intensive.json"))
	if a.services.size()!=100 or b.services.size()!=140:return "Both operating days must coexist"
	var ids:={}
	for row in a.services:ids[row.id]=row
	var selected: Dictionary=b.services.filter(func(row):return row.id=="K1")[0]
	var slowest:=INF
	for row in b.services:
		if row.id in ids and row.speed_limit_kmh!=ids[row.id].speed_limit_kmh:return "Artificial equipment speed cap"
		if row.id in ids and row.id not in ["K1","B002"] and row!=ids[row.id]:return "Unrelated standard schedule changed"
		if row.id=="K1":slowest=row.stops[-1].minutes_from_origin
	return b.services.filter(func(row):return row.stock.begins_with("vb")).size()==2 and slowest>ids.K1.stops[-1].minutes_from_origin and selected.priority==20

func test_intensive_timetable_decodes_with_full_length_and_forward_reachability():
	var decoded:=Pack.decode(FileAccess.get_file_as_string("res://art/timetables/kerala-coast-intensive.json"))
	if not decoded.ok:return decoded.reason
	return decoded.world.trains.size()==140

func test_saved_day_metadata_restores_and_old_saves_clear_it():
	var tree:=Engine.get_main_loop()
	var previous=tree.get_meta("timetable_id") if tree.has_meta("timetable_id") else null
	var load_script:=preload("res://game/save_load.gd")
	# Preserve all unrelated metadata while exercising this optional save field.
	var meta:={}
	for key in load_script.META:
		if tree.has_meta(key):meta[key]=tree.get_meta(key)
	load_script.prepare_metadata(tree,{meta={timetable_id="intensive"}})
	var ok: bool=tree.get_meta("timetable_id","")=="intensive"
	load_script.prepare_metadata(tree,{meta={}})
	ok=ok and not tree.has_meta("timetable_id")
	load_script.prepare_metadata(tree,{meta=meta})
	if previous!=null:tree.set_meta("timetable_id",previous)
	return ok

func test_timeline_and_departure_entries_keep_day_when_old_journey_is_cleared():
	var tree:=Engine.get_main_loop()
	var keys: Array=preload("res://game/save_load.gd").META.duplicate()
	keys.append("prepared_start")
	var previous:={}
	for key in keys:
		if tree.has_meta(key):previous[key]=tree.get_meta(key)
	tree.set_meta("timetable_id","intensive")
	tree.set_meta("service_pack","previous import")
	Days.stage_start(tree,{service="K1",mode="ride",timeline="T028800"})
	var ok: bool=tree.get_meta("prepared_start").timetable_id=="intensive" and not tree.has_meta("service_pack")
	tree.set_meta("timetable_id","intensive")
	Days.stage_start(tree,{service="B042",timetable_id="standard"})
	ok=ok and tree.get_meta("prepared_start").timetable_id=="standard"
	for key in keys:
		if tree.has_meta(key):tree.remove_meta(key)
	for key in previous:tree.set_meta(key,previous[key])
	return ok

func test_all_days_have_distinct_prepared_data_and_explicit_dispatcher():
	var paths:=[];var modes:={}
	for day in Days.DAYS:
		if day.starts in paths or day.times in paths:return "Shared prepared data"
		paths.append(day.starts);paths.append(day.times);modes[day.id]=day.dispatcher
	return modes=={standard="classic",intensive="classic",standard_v2="predictive",intensive_v2="predictive",network="classic",network_v2="predictive"}

func test_predictive_pack_opt_in_is_validated_and_keeps_classic_default():
	var original:=Pack.defaults("kerala_coast",false)
	var a:=Pack.build(original)
	if not a.ok or a.world.dispatcher().predictive.enabled:return "Classic default lost"
	var opted: Dictionary=original.duplicate(true);opted.dispatcher="predictive"
	var b:=Pack.build(opted)
	if not b.ok or not b.world.dispatcher().predictive.enabled:return "V2 import ignored"
	opted.dispatcher="unknown"
	return not Pack.build(opted).ok

func test_predictive_intensive_changes_departures_without_padding_k1_or_forcing_passes():
	var classic: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/timetables/kerala-coast-intensive.json"))
	var v2: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/timetables/kerala-coast-intensive-v2.json"))
	if v2.services.size()!=140 or v2.dispatcher!="predictive":return "Wrong V2 roster"
	for index in classic.services.size():
		var a: Dictionary=classic.services[index].duplicate(true);var b: Dictionary=v2.services[index].duplicate(true)
		if a.id.begins_with("D"):
			a.erase("departure");a.erase("name");b.erase("departure");b.erase("name")
		if a!=b:return "Changed formation, calls or slow schedule: "+str(a.id)
	var decoded:=Pack.decode(JSON.stringify(v2))
	return decoded.ok and decoded.world.dispatcher().predictive.enabled
