extends SceneTree
## Diagnostic observer: recover actual receiving/passing roads from an existing
## replay's five-minute states. Never changes or certifies the prepared files.
const Times:=preload("res://persistence/railway_times.gd")
const Positions:=preload("res://tools/record_service_traffic.gd")
var folder:=""
var events_path:=""
var output:=""
var only_train:=""
var failures:=[]
var witnesses:=[]
var compared_samples:=0
var maximum_error:=0.0

func _initialize() -> void:call_deferred("run")

func fail(reason: String) -> void:
	failures.append(reason);printerr(reason)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--folder="):folder=arg.trim_prefix("--folder=")
		elif arg.begins_with("--events="):events_path=arg.trim_prefix("--events=")
		elif arg.begins_with("--output="):output=arg.trim_prefix("--output=")
		elif arg.begins_with("--train="):only_train=arg.trim_prefix("--train=")
	if folder.is_empty() or events_path.is_empty() or output.is_empty():
		printerr("Required: --folder= --events= --output=; optional --train=");quit(1);return
	var catalogue=JSON.parse_string(FileAccess.get_file_as_string(folder+"/starts/catalogue.json"))
	var summary=JSON.parse_string(FileAccess.get_file_as_string(events_path))
	if not catalogue is Dictionary or not summary is Dictionary or not summary.get("events") is Array:
		printerr("Replay catalogue or encounter summary is invalid");quit(1);return
	# Partial observations are useful but must still use the exact frozen inputs.
	for path: String in catalogue.sources:
		var digest:=FileAccess.get_sha256("res://"+path) if path.ends_with(".bin") else FileAccess.get_file_as_string("res://"+path).replace("\r\n","\n").sha256_text()
		if digest!=catalogue.sources[path]:fail("Changed replay input: "+path)
	if not failures.is_empty():quit(1);return
	var events: Array=summary.events.filter(func(e):return e.kind=="overtake" and (only_train.is_empty() or only_train in [e.a,e.b]))
	if events.is_empty():fail("No matching measured overtake")
	var ranges:=[]
	for event: Dictionary in events:ranges.append(Vector2(floorf(event.time/300)*300,ceilf(event.cleared/2)*2))
	var samples:={}
	var recording:=FileAccess.open(folder+"/traffic.jsonl",FileAccess.READ)
	while not recording.eof_reached():
		var line:=recording.get_line()
		if line.is_empty():continue
		var parser:=JSON.new()
		if parser.parse(line)!=OK:
			if recording.eof_reached():break # Ignore only an unfinished trailing write.
			fail("Malformed complete traffic sample");break
		var frame=parser.data
		if not frame is Array:fail("Invalid complete traffic sample");break
		if ranges.any(func(span):return frame[0]>=span.x-.001 and frame[0]<=span.y+.001):samples[roundi(frame[0])]=frame[1]
	recording.close()
	for event: Dictionary in events:
		observe(event,samples)
	var report:={ok=failures.is_empty(),complete_replay=summary.get("finished",false),
		purpose="Observed roads only; not timetable certification",source_folder=folder,
		compared_samples=compared_samples,maximum_position_error_m=maximum_error,
		failures=failures,witnesses=witnesses}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("OVERTAKE_ROADS ok=%s witnesses=%d samples=%d max_error=%.9fm" % [report.ok,witnesses.size(),compared_samples,maximum_error])
	quit(0 if report.ok else 1)

func observe(event: Dictionary,samples: Dictionary) -> void:
	var clock:=floori(event.time/300)*300
	var id:="T%06d" % clock
	var path:=folder+"/times/"+id+".bin"
	if not FileAccess.file_exists(path):fail("Missing observed checkpoint: "+id);return
	var loaded:=Times.load_state({id=id,file=id+".bin",clock=float(clock),sha256=FileAccess.get_sha256(path)},folder+"/times")
	if not loaded.ok:fail(loaded.reason);return
	var w: RailWorld=loaded.world
	w.dispatcher().predictive.execution(false,4)
	var witness:={event=event,checkpoint=id,checkpoint_sha256=FileAccess.get_sha256(path)}
	while true:
		var current:=roundi(w.clock_seconds())
		if not compare(w,samples.get(current),current):break
		if not witness.has("aligned") and w.clock_seconds()+.001>=event.time:
			witness.aligned=pair(w,event)
		if w.clock_seconds()+.001>=event.cleared:
			witness.cleared=pair(w,event);break
		w.step(2)
		if not w.events.is_empty():fail("Safety event while recovering "+id+": "+str(w.events));break
	if w.dispatcher().predictive._worker!=null:w.dispatcher().predictive._worker.close()
	witnesses.append(witness)
	print("Observed ",event.overtaker," at ",event.get("station","")," from ",id)

func compare(w: RailWorld,expected,clock: int) -> bool:
	if not expected is Array:fail("Missing original traffic sample at %d" % clock);return false
	var actual:=Positions.positions(w)
	if actual.size()!=expected.size():fail("Replay train count differs at %d" % clock);return false
	for i in actual.size():
		if actual[i][0]!=expected[i][0] or actual[i][4]!=expected[i][4]:fail("Replay membership differs at %d" % clock);return false
		for axis in [1,2,3]:maximum_error=maxf(maximum_error,absf(actual[i][axis]-expected[i][axis]))
	if maximum_error>.1:fail("Replay positions differ at %d (%.4f m)" % [clock,maximum_error]);return false
	compared_samples+=1;return true

func pair(w: RailWorld,event: Dictionary) -> Dictionary:
	var rows:={}
	for id: String in [event.a,event.b]:
		var t: Train=w.trains[id]
		var centre: String=t.locate_behind(w.graph,t.length*.5).edge
		var station_index:=w.stations.find_custom(func(s):return s.code==event.get("station",""))
		var station: Dictionary=w.stations[station_index] if station_index>=0 else {}
		var details: Dictionary=station.get("platform_details",{}).get(centre,{})
		rows[id]={head_road=t.path[0].edge,centre_road=centre,road_role=details.get("service","outside yard"),
			booked_here=t.timetable.stops.any(func(s):return s.block.get_slice("_P",0)==event.get("station","")),
			tail_road=t.locate_behind(w.graph,t.length).edge,speed_kmh=t.speed*3.6,
			at_booked_stop=t.timetable.at_stop,call_index=t.timetable.index,
			hold=w.dispatch_holds.get(id,{}).duplicate(true),
			reason=w.dispatcher().states.get(id,{}).get("reason",t.status)}
	return {clock=w.clock_seconds(),trains=rows}
