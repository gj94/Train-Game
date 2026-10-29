extends SceneTree
## Export per-service passenger exchange and infrastructure for offline authoring.
## Train IDs seed passenger demand, so a shared traction profile must not also
## substitute another service's exchange times.
const Pack = preload("res://sim/service_pack.gd")
const Passengers = preload("res://sim/passenger_service.gd")
const Berth = preload("res://sim/berth_clearance.gd")
const Physics = preload("res://tools/lib/timetable_physics.gd")

func _initialize() -> void:call_deferred("run")

func run() -> void:
	var source:="res://art/timetables/kerala-coast-network-v2.json"
	var output:="res://.local/incremental-timetable-2026-10-30/planning-inputs.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--source="):source=arg.trim_prefix("--source=")
		elif arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	if FileAccess.file_exists(output):printerr("Planning input output already exists");quit(1);return
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source))
	var built:=Pack.build(data)
	if not built.ok:printerr(built.reason);quit(1);return
	var w: RailWorld=built.world
	var services: Dictionary={}
	for service in data.services:
		var t: Train=w.trains[service.id]
		Passengers.setup(t)
		var exchanges: Array=[]
		for i in t.timetable.stops.size():
			var stop: Dictionary=t.timetable.stops[i]
			var platform:=Passengers.platform_at(w,stop.block)
			if platform.is_empty():exchanges.append(0.0);continue
			t.path=[{edge=stop.block,dir=stop.direction}];t.head_s=stop.s;t.speed=0
			Passengers._begin(t,i,t.timetable.stops.size(),platform)
			var duration: float=t.passengers.duration
			exchanges.append(duration)
			Passengers.update(w,t,duration+.01)
		services[service.id]={profile=Physics.identity(service),passenger_exchange_seconds=exchanges,length=t.length,
			mass=t.mass,max_power=t.max_power,max_accel=t.max_accel,max_speed=t.max_speed,service_decel=t.service_decel}
	var stations: Array=[]
	for station in w.stations:
		var roads: Array=[]
		for road in station.platform_tracks:
			roads.append({id=road,capacity=Berth.capacity(w,road),allowed_dir=w.graph.edges[road].allowed_dir,detail=station.platform_details[road]})
		stations.append({code=station.code,name=station.name,s=station.s,half=station.yard_half,through_halt=station.through_halt,passenger_open=station.passenger_open,roads=roads})
	var result:={kind="planning inputs; not a shared-capacity certificate",source_sha256=FileAccess.get_sha256(source),
		services=services,stations=stations,single_line_sections=w.single_line_sections,route_sections=w.scenery.route.sections}
	var f:=FileAccess.open(output,FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"\t")+"\n");f.close()
	print("PLANNING INPUTS services=",services.size()," stations=",stations.size()," simulation_ticks=0")
	quit(0)
