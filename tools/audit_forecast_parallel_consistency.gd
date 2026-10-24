extends SceneTree
## Compare detached planner results across a complete prepared day without
## stepping its railway. This is a determinism audit, not a throughput benchmark.
const Times:=preload("res://persistence/railway_times.gd")
const Snapshot:=preload("res://sim/world_snapshot.gd")
const InputData:=preload("res://sim/dispatch_forecast_input.gd")
const Worker:=preload("res://sim/dispatch_forecast_worker.gd")
var directory:="res://data/timetables/standard_v2/times"
var output:=""
var failures:=[]

func _initialize() -> void:call_deferred("run")
func fail(reason: String) -> void:failures.append(reason);printerr(reason)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--directory="):directory=arg.trim_prefix("--directory=")
		elif arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	if output.is_empty():printerr("Required --output in a separate audit folder");quit(1);return
	var loaded:=Times.catalogue(directory)
	if not loaded.ok:printerr(loaded.reason);quit(1);return
	var catalogue: Dictionary=loaded.data
	if catalogue.get("dispatcher","")!="predictive":printerr("Expected a certified V2 timeline");quit(1);return
	if not catalogue.get("sources") is Dictionary:printerr("Missing source manifest");quit(1);return
	for path: String in catalogue.sources:
		var digest:=FileAccess.get_sha256("res://"+path) if path.ends_with(".bin") else FileAccess.get_file_as_string("res://"+path).replace("\r\n","\n").sha256_text()
		if digest!=catalogue.sources[path]:fail("Changed railway input "+path)
	if not failures.is_empty():quit(1);return
	var rows:=[];var directions:={};var actions:={};var caller:=OS.get_thread_caller_id()
	for meta: Dictionary in catalogue.states:
		var restored:=Times.load_state(meta,directory)
		if not restored.ok:fail(meta.id+": "+restored.reason);break
		var w: RailWorld=restored.world
		var before:=var_to_bytes(Snapshot.capture(w))
		var frame:=InputData.frame(w);var worker:=Worker.new(InputData.topology(w))
		var original_input:=var_to_bytes(frame)
		var expected:=worker.synchronous(frame)
		var comparisons:=[]
		for count in [1,2,4]:
			var actual:=worker.parallel_complete(frame,count)
			var same: bool=actual.plans==expected.plans and actual.inputs==expected.inputs and actual.occupied==expected.occupied and actual.claims==expected.claims
			if not same:fail("Planner result differs at %s with %d workers" % [meta.id,count])
			if not frame.trains.is_empty() and caller in actual.worker_threads:fail("Forecast ran on owner at "+meta.id)
			comparisons.append({workers=count,equal=same,worker_threads=actual.worker_threads})
		worker.close()
		if var_to_bytes(frame)!=original_input:fail("Worker changed detached input at "+meta.id)
		if var_to_bytes(Snapshot.capture(w))!=before:fail("Forecast changed live railway at "+meta.id)
		for plan: Dictionary in expected.plans:
			directions[str(plan.direction)]=directions.get(str(plan.direction),0)+1
			actions[plan.action]=actions.get(plan.action,0)+1
		rows.append({id=meta.id,sha256=meta.sha256,clock=meta.clock,trains=frame.trains.size(),plans=expected.plans.size(),comparisons=comparisons})
		if rows.size()%20==0:print("CONSISTENCY ",rows.size(),"/",catalogue.states.size()," checkpoints")
		if not failures.is_empty():break
	var report:={ok=failures.is_empty() and rows.size()==catalogue.states.size(),failures=failures,
		directory=directory,catalogue_sha256=FileAccess.get_sha256(directory+"/catalogue.json"),source_hashes=catalogue.sources.size(),
		states_expected=catalogue.states.size(),states_checked=rows.size(),samples=rows,proposal_directions=directions,proposal_actions=actions,
		limitation="Read-only planning equality across saved states; no railway stepping, live scheduling equivalence, safety certification or performance claim."}
	var file:=FileAccess.open(output,FileAccess.WRITE)
	if file==null:printerr("Cannot write audit output");quit(1);return
	file.store_string(JSON.stringify(report,"\t"));file.close()
	print("PARALLEL_CONSISTENCY ",report.ok," states=",rows.size()," directions=",directions," actions=",actions)
	quit(0 if report.ok else 1)
