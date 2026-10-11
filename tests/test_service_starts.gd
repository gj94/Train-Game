extends RefCounted
const Starts:=preload("res://persistence/service_starts.gd")
const Snapshot:=preload("res://sim/world_snapshot.gd")
const Traffic:=preload("res://sim/layouts/traffic_service.gd")
const DIRECTORY:="res://.local/service-start-tests"
const Briefing:=preload("res://persistence/service_briefing.gd")

func write(w: RailWorld) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIRECTORY))
	var path:=DIRECTORY+"/T1.bin"
	var file:=FileAccess.open_compressed(path,FileAccess.WRITE,FileAccess.COMPRESSION_ZSTD)
	file.store_var(Snapshot.capture(w));file.close()
	var row:={id="T1",name="Test service",origin="A",destination="B",stock="lhb",cars=21,stops=w.trains.T1.timetable.stops.size(),duration=3600,
		file="T1.bin",sha256=FileAccess.get_sha256(path),departure=w.trains.T1.timetable.departure,start_clock=w.clock_seconds()}
	row.merge(Briefing.describe(w,w.trains.T1));return row

func test_prepared_state_and_continuation_equal_original_railway():
	var w:=Traffic.build();var row:=write(w)
	var loaded:=Starts.load_start(row,DIRECTORY)
	if not loaded.ok:return loaded.reason
	if var_to_bytes(Snapshot.capture(w))!=var_to_bytes(Snapshot.capture(loaded.world)):return "Railway changed on load"
	for i in 40:w.step(.5);loaded.world.step(.5)
	return var_to_bytes(Snapshot.capture(w))==var_to_bytes(Snapshot.capture(loaded.world))

func test_handover_preserves_authority_and_other_trains():
	var w:=Traffic.build();w.dispatcher().run_cycle(true)
	var before:=Snapshot.capture(w)
	Starts.select(w,"T1")
	var after:=Snapshot.capture(w)
	if before.world!=after.world or before.switches!=after.switches or before.future!=after.future:return "Handover changed railway authorities"
	for t in after.trains:
		if t.id=="T1":
			if t.automatic or t.controller!=-1.0:return "Player not safely held"
		elif t!=before.trains.filter(func(old):return old.id==t.id)[0]:return "Other train changed"
	return w.dispatcher().manual_service=="T1" and w.dispatcher().enabled

func test_corrupt_checkpoint_and_path_escape_rejected():
	var row:=write(Traffic.build())
	row.sha256="wrong"
	if Starts.load_start(row,DIRECTORY).ok:return false
	return not Starts.load_start({id="../T1",file="../T1.bin"},DIRECTORY).ok and not Starts.load_start({id=2},DIRECTORY).ok

func test_moving_stored_or_wrong_time_origin_cannot_be_offered():
	var w:=Traffic.build();w.trains.T1.speed=5
	if Starts.load_start(write(w),DIRECTORY).ok:return "Moving origin accepted"
	w.trains.T1.speed=0;w.trains.T1.lifecycle="stored"
	if Starts.load_start(write(w),DIRECTORY).ok:return "Stored origin accepted"
	w.trains.T1.lifecycle="active"
	var row:=write(w);row.start_clock+=3600
	return not Starts.load_start(row,DIRECTORY).ok

func test_catalogue_requires_completed_replay_and_matching_engine():
	var row:=write(Traffic.build())
	var data:={version=Starts.VERSION,engine=Engine.get_version_info().string,complete=false,services=[row]}
	var path:=DIRECTORY+"/catalogue.json"
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(data))
	if Starts.catalogue(DIRECTORY).ok:return false
	data.complete=true;data.engine="old"
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(data))
	if Starts.catalogue(DIRECTORY).ok:return false
	data.engine=Engine.get_version_info().string
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(data))
	if not Starts.catalogue(DIRECTORY).ok:return false
	data.services.append(row)
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(data))
	return not Starts.catalogue(DIRECTORY).ok

func test_departure_filters_cover_midnight_and_every_service_once():
	var launch:=preload("res://game/launch.gd")
	for minute in 1440:
		var matches:=0
		for filter in range(1,5):
			if launch.in_period(minute*60,filter):matches+=1
		if matches!=1 or not launch.in_period(minute*60,0):return "Overlapping/missing departure period"
	return launch.in_period(86400+2*3600,4) and not launch.in_period(12*3600,4)

func test_briefing_includes_dwell_and_rail_distance():
	var w:=Traffic.build();var t: Train=w.trains.T1;var tt=t.timetable
	var info:=Briefing.describe(w,t)
	if info.calls.size()!=tt.stops.size() or info.distance_m<=0:return "Missing calls/distance"
	var distance:=0.0
	for i in range(1,tt.stops.size()):
		var before: Dictionary=tt.stops[i-1]
		distance+=w._stop_distance(before.block,before.direction,before.s,tt.stops[i],[])
	if absf(info.distance_m-distance)>.001:return "Not track distance"
	var original: float=info.average_kmh
	# Add ten booked minutes at an intermediate call and shift all later calls.
	tt.stops[1].dwell_minutes+=10
	for i in range(2,tt.stops.size()):tt.stops[i].minutes_from_origin+=10
	var slower:=Briefing.describe(w,t)
	return slower.average_kmh<original and slower.distance_m==distance and slower.calls[1].departure-info.calls[1].departure==600

func test_schedule_midnight_and_stable_speed_sort():
	if Briefing.time_text(86400+90)!="00:01 · day 2":return "Midnight day missing"
	var rows:=[{id="B",name="Beta",average_kmh=50,departure=900},{id="A",name="Alpha",average_kmh=50,departure=900},{id="C",name="Gamma",average_kmh=70,departure=800}]
	var fast:=Briefing.ordered(rows,1);var slow:=Briefing.ordered(rows,2)
	return fast.map(func(r):return r.id)==["C","A","B"] and slow.map(func(r):return r.id)==["A","B","C"] and rows[0].id=="B"

func test_incomplete_or_nonfinite_calling_pattern_rejected():
	var row:=write(Traffic.build())
	var data:={version=Starts.VERSION,engine=Engine.get_version_info().string,complete=true,services=[row]}
	var path:=DIRECTORY+"/catalogue.json"
	row.calls[1].arrival=-5
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(data))
	if Starts.catalogue(DIRECTORY).ok:return "Negative time accepted"
	row.calls=[]
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(data))
	return not Starts.catalogue(DIRECTORY).ok
