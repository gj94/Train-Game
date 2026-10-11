extends RefCounted
const Times:=preload("res://persistence/railway_times.gd")
const Snapshot:=preload("res://sim/world_snapshot.gd")
const DIRECTORY:="res://.local/timeline-tests"

func write(w: RailWorld) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIRECTORY))
	var id:="T%06d" % roundi(w.clock_seconds())
	var file:=FileAccess.open_compressed(DIRECTORY+"/"+id+".bin",FileAccess.WRITE,FileAccess.COMPRESSION_ZSTD)
	file.store_var(Snapshot.capture(w));file.close()
	return {id=id,file=id+".bin",clock=w.clock_seconds(),sha256=FileAccess.get_sha256(DIRECTORY+"/"+id+".bin")}

func test_timeline_restore_preserves_moving_ai_railway():
	var w:=preload("res://sim/layouts/traffic_service.gd").build()
	for t in w.trains.values():t.automatic=true
	w.dispatcher().enabled=true;w.dispatcher().manual_service=""
	for i in 150:w.step(2)
	if not w.active_trains().any(func(t):return t.speed>1):return "Fixture not moving"
	var loaded:=Times.load_state(write(w),DIRECTORY)
	if not loaded.ok:return loaded.reason
	if var_to_bytes(Snapshot.capture(w))!=var_to_bytes(Snapshot.capture(loaded.world)):return "Load changed AI authority or motion"
	for i in 10:w.step(.5);loaded.world.step(.5)
	return var_to_bytes(Snapshot.capture(w))==var_to_bytes(Snapshot.capture(loaded.world))

func test_timeline_rejects_corruption_paths_and_wrong_clock():
	var w:=preload("res://sim/layouts/traffic_service.gd").build()
	var row:=write(w);row.clock+=300
	if Times.load_state(row,DIRECTORY).ok:return "Wrong clock accepted"
	row=write(w);row.sha256="bad"
	return not Times.load_state(row,DIRECTORY).ok and not Times.valid_row({id="../T1",file="../T1.bin",sha256="",clock=0}) and not Times.valid_row({id="T1",file="T1.bin",sha256="",clock=1})

func test_timeline_catalogue_requires_continuous_five_minute_states():
	var row:=write(preload("res://sim/layouts/traffic_service.gd").build())
	var data:={version=1,engine=Engine.get_version_info().string,complete=true,states=[row]}
	var path:=DIRECTORY+"/catalogue.json"
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(data))
	if not Times.catalogue(DIRECTORY).ok:return "Valid catalogue rejected"
	var next: Dictionary=row.duplicate();next.clock+=600;data.states.append(next)
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(data))
	if Times.catalogue(DIRECTORY).ok:return "Missing five-minute state accepted"
	data.states.pop_back();data.complete=false
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(data))
	return not Times.catalogue(DIRECTORY).ok

func test_timeline_only_offers_active_passenger_workings():
	var w:=preload("res://sim/layouts/traffic_service.gd").build()
	w.trains.T1.lifecycle="stored";w.trains.T2.service_complete=true
	return Times.available(w).all(func(t):return t.id not in ["T1","T2"]) and Times.available(w).size()>0

func test_every_open_coastal_station_has_a_safe_exact_station_spawn():
	var w:=preload("res://sim/layouts/kerala_coast.gd").build_traffic(true)
	for i in w.stations.size():
		if not w.stations[i].get("passenger_open",true):continue
		var spot:=Times.station_spot(w,i)
		if spot.is_empty():return "Missing platform: "+w.stations[i].code
		var nav:=preload("res://game/platform_navigation.gd").new(w,spot.road)
		if not nav.allowed(spot.point):return "Unsafe landing: "+w.stations[i].code
		if nav.obstacles.any(func(r):return r.grow(.8).has_point(spot.point)):return "Cramped landing: "+w.stations[i].code
	return Times.station_spot(w,-1).is_empty() and Times.station_spot(w,w.stations.size()).is_empty()
