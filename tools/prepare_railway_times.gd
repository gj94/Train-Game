extends SceneTree
## Reuse exact service-origin checkpoints as acceleration anchors, step the same
## serial simulation between them, and round-trip every five-minute state.
const Times:=preload("res://persistence/railway_times.gd")
const Starts:=preload("res://persistence/service_starts.gd")
const Snapshot:=preload("res://sim/world_snapshot.gd")
var output:=Times.DIRECTORY
var part:=0
var parts:=1
var catalogue_path:=""

func _initialize() -> void:call_deferred("run")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--part="):part=int(arg.trim_prefix("--part="))
		elif arg.begins_with("--parts="):parts=int(arg.trim_prefix("--parts="))
	if parts<1 or parts>8 or part<0 or part>=parts:printerr("Invalid preparation partition");quit(1);return
	catalogue_path=output+"/catalogue.json" if parts==1 else "res://.local/railway-time-parts/%d.json" % part
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(catalogue_path.get_base_dir()))
	var source:=Starts.catalogue()
	if not source.ok or not source.data.get("audit",{}).get("ok",false):printerr("Prepare and verify departures first: "+source.reason);quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var anchors: Array=source.data.services.duplicate()
	anchors.sort_custom(func(a,b):return a.start_clock<b.start_clock)
	var loaded:=Starts.load_start(anchors[0]);var w: RailWorld=loaded.world
	var began:=Time.get_ticks_msec();var total_steps:=0
	var first:=ceili(w.clock_seconds()/300)*300
	var last:=ceili(float(source.data.audit.clock)/300)*300
	var count:=int((last-first)/300)+1
	var per_part:=ceili(float(count)/parts)
	var start_index:=part*per_part;var end_index:=mini(count,start_index+per_part)
	var data:={version=1,engine=Engine.get_version_info().string,complete=false,states=[],sources=source.data.sources,
		departure_catalogue_sha256=FileAccess.get_sha256(Starts.DIRECTORY+"/catalogue.json"),layout_signature=source.data.layout_signature}
	for target_index in range(start_index,end_index):
		var target:=first+target_index*300
		var best:={}
		for anchor in anchors:
			if anchor.start_clock>w.clock_seconds()+.001 and anchor.start_clock<=target:best=anchor
		if not best.is_empty():
			loaded=Starts.load_start(best)
			if not loaded.ok:printerr(loaded.reason);quit(1);return
			w=loaded.world
		while w.clock_seconds()<target-.001:
			w.step(minf(2,target-w.clock_seconds()));total_steps+=1
		if not w.events.is_empty():printerr("Timeline safety event at "+w.clock_text());quit(1);return
		var state:=Snapshot.capture(w)
		var id:="T%06d" % target;var path:=output.path_join(id+".bin")
		var file:=FileAccess.open_compressed(path,FileAccess.WRITE,FileAccess.COMPRESSION_ZSTD)
		file.store_var(state);file.close()
		var row:={id=id,file=id+".bin",clock=target,sha256=FileAccess.get_sha256(path),active=Times.available(w).size()}
		var restored:=Times.load_state(row,output)
		if not restored.ok or var_to_bytes(Snapshot.capture(restored.world))!=var_to_bytes(state):printerr("Timeline restore differs: "+id);quit(1);return
		data.states.append(row)
		FileAccess.open(catalogue_path,FileAccess.WRITE).store_string(JSON.stringify(data,"\t"))
		print("TIME %s states=%d active=%d wall=%.1fs" % [w.clock_text(),data.states.size(),row.active,(Time.get_ticks_msec()-began)*.001])
	data.complete=true;data.audit={ok=true,states=data.states.size(),round_trips=data.states.size(),events=w.events,steps=total_steps,wall_seconds=(Time.get_ticks_msec()-began)*.001}
	data.part=part;data.parts=parts
	FileAccess.open(catalogue_path,FileAccess.WRITE).store_string(JSON.stringify(data,"\t"))
	print("TIMELINE ",JSON.stringify(data.audit));quit()
