extends SceneTree
## One serial measurement job. Each physical working is measured once, with
## inherited booked-time holds removed. Output is planning input, not acceptance.
const Physics = preload("res://tools/lib/timetable_physics.gd")
const Pack = preload("res://sim/service_pack.gd")
const Trial = preload("res://sim/service_trial.gd")
const Observer = preload("res://tools/record_service_traffic.gd")
const Depot = preload("res://sim/depot_workings.gd")

func _initialize() -> void:call_deferred("run")

func write_json(path: String, data) -> void:
	var f:=FileAccess.open(path,FileAccess.WRITE)
	f.store_string(JSON.stringify(data,"\t")+"\n");f.close()

func run() -> void:
	var source:="res://art/timetables/kerala-coast-network-v2.json"
	var output:="res://.local/incremental-timetable-2026-10-30/physics"
	var limit:=1000
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--source="):source=arg.trim_prefix("--source=")
		elif arg.begins_with("--output="):output=arg.trim_prefix("--output=")
		elif arg.begins_with("--limit="):limit=int(arg.trim_prefix("--limit="))
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source))
	var groups:=Physics.groups(data.services)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var sources:=preload("res://persistence/prepared_sources.gd").collect()
	for tool in ["tools/lib/timetable_physics.gd","tools/measure_timetable_physics.gd"]:
		sources[tool]=FileAccess.get_sha256("res://"+tool)
	var manifest:={kind="unconstrained physical measurements; not shared-capacity or timetable acceptance",version=1,source=source,source_sha256=FileAccess.get_sha256(source),sources=sources,sample_seconds=2,profiles=[],complete=false}
	var index_path:=output+"/index.json"
	if FileAccess.file_exists(index_path):
		var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(index_path))
		if previous.sources!=sources or previous.source_sha256!=manifest.source_sha256:
			printerr("Measurement inputs changed; use a new generation");quit(1);return
		manifest=previous
	var began:=Time.get_ticks_msec();var measured:=0
	for group in groups:
		if manifest.profiles.any(func(p):return p.key==group.key):continue
		if measured>=limit:break
		var candidate:=data.duplicate(true)
		candidate.world_start="00:00";candidate.day=1
		candidate.services=[Physics.probe(group.service)]
		var result:=Pack.build(candidate)
		if not result.ok:printerr(result.reason);quit(1);return
		var w: RailWorld=result.world
		w.dispatcher().predictive.configure(true,false)
		var train: Train=w.trains.values()[0]
		var trial:=Trial.new(w)
		# Probe offsets deliberately precede achievable arrivals; the probe's
		# finite horizon must therefore be independent of those early targets.
		trial.deadline=86400.0
		var edges: Dictionary={};var sections: Dictionary={};var samples: Array=[]
		var last_print:=Time.get_ticks_msec()
		while not trial.done:
			trial.step()
			if train.lifecycle=="active" and not train.service_complete:
				var time:=w.clock_seconds()-180.0
				for road in train.path:
					if not edges.has(road.edge):edges[road.edge]={start=time,finish=time,direction=road.dir}
					edges[road.edge].finish=time
					var section: String=w.single_line_sections.get(road.edge,"")
					if not section.is_empty():
						if not sections.has(section):sections[section]={start=time,finish=time,direction=road.dir}
						sections[section].finish=time
				samples.append([time,Observer.positions(w)[0]])
			if Time.get_ticks_msec()-last_print>30000:
				print("MEASURING ",group.service.id," clock=",w.clock_text());last_print=Time.get_ticks_msec()
		if not trial.ok:printerr(group.service.id,": ",trial.report);quit(1);return
		var tt=train.completed_timetable if train.completed_timetable!=null else train.timetable
		var report:={key=group.key,ids=group.ids,service=group.service,probe=candidate.services[0],arrivals=tt.actual_arrivals.map(func(t):return t-180 if t>=0 else t),departures=tt.actual_departures.map(func(t):return t-180 if t>=0 else t),
			edges=edges,sections=sections,samples=samples,stations=w.stations.map(func(s):return {code=s.code,name=s.name,s=s.s,half=s.yard_half,platform_tracks=s.platform_tracks}),
			length=train.length,mass=train.mass,max_power=train.max_power,max_accel=train.max_accel,max_speed=train.max_speed,service_decel=train.service_decel,
			events=w.events,terminal_complete=Depot.finished(w,train),terminal_clock=w.clock_seconds()-180.0,clock_origin=180.0}
		var file: String=group.key+".json"
		if FileAccess.file_exists(output+"/"+file):printerr("Unindexed measurement already exists: ",file);quit(1);return
		write_json(output+"/"+file,report)
		manifest.profiles.append({key=group.key,ids=group.ids,file=file,sha256=FileAccess.get_sha256(output+"/"+file)})
		measured+=1
		manifest.complete=manifest.profiles.size()==groups.size()
		write_json(index_path,manifest)
		print("MEASURED ",group.service.id," profiles=",manifest.profiles.size(),"/",groups.size()," arrival=",report.arrivals[-1]," wall=",(Time.get_ticks_msec()-began)*.001)
	print("PHYSICS ",manifest.profiles.size(),"/",groups.size()," complete=",manifest.complete)
	quit(0)
