extends SceneTree
## Offline observer only: replay disjoint, contiguous baseline intervals from
## verified checkpoints. Record actual train extents every two simulated seconds.
const Times:=preload("res://persistence/railway_times.gd")
const Starts:=preload("res://persistence/service_starts.gd")
var part:=0
var parts:=1
var folder:="res://.local/service-traffic"

func _initialize() -> void:call_deferred("run")

static func chainage(w: RailWorld,point: Dictionary) -> float:
	var edge: Dictionary=w.graph.edges[point.edge]
	return lerpf(edge.chainage_start,edge.chainage_end,point.s/edge.length)

static func positions(w: RailWorld) -> Array:
	var rows:=[]
	for t: Train in w.active_trains():
		# Empty stock/depot movements and trains outside passenger service do not
		# appear as passenger encounters. Entry must never invent an overtake.
		if t.service_complete or preload("res://sim/depot_workings.gd").active(t):continue
		var head:=chainage(w,{edge=t.path[0].edge,s=t.head_s})
		var tail:=chainage(w,t.locate_behind(w.graph,t.length))
		var center:=chainage(w,t.locate_behind(w.graph,t.length*.5))
		rows.append([t.id,center,head,tail,t.path[0].dir])
	rows.sort_custom(func(a,b):return a[0]<b[0])
	return rows

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--part="):part=int(arg.trim_prefix("--part="))
		elif arg.begins_with("--parts="):parts=int(arg.trim_prefix("--parts="))
	if parts<1 or parts>8 or part<0 or part>=parts:printerr("Invalid partition");quit(1);return
	var source:=Times.catalogue();var starts:=Starts.catalogue()
	if not source.ok or not starts.ok:printerr("Verified baseline states required");quit(1);return
	var count: int=source.data.states.size()-1
	var first:=floori(float(count)*part/parts);var last:=floori(float(count)*(part+1)/parts)
	var loaded:=Times.load_state(source.data.states[first])
	if not loaded.ok:printerr(loaded.reason);quit(1);return
	var w: RailWorld=loaded.world
	var target: float=source.data.states[last].clock
	var began:=Time.get_ticks_msec();var steps:=0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var path:=folder+"/%d" % part
	var file:=FileAccess.open(path+".jsonl",FileAccess.WRITE)
	if file==null:printerr("Cannot open traffic recording");quit(1);return
	while true:
		file.store_line(JSON.stringify([w.clock_seconds(),positions(w)]))
		if w.clock_seconds()>=target-.001:break
		w.step(minf(2,target-w.clock_seconds()));steps+=1
		if not w.events.is_empty():printerr("Safety event: ",w.events);quit(1);return
		if steps%900==0:print("TRAFFIC %d/%d %s wall=%.1fs" % [part,parts,w.clock_text(),(Time.get_ticks_msec()-began)*.001])
	file.close()
	# Prove this observer's continuation reached the existing baseline boundary.
	var end:=Times.load_state(source.data.states[last])
	if not end.ok:printerr(end.reason);quit(1);return
	var actual:=positions(w);var expected:=positions(end.world)
	if actual.size()!=expected.size():printerr("Baseline boundary count differs");quit(1);return
	var max_error:=0.0
	for i in actual.size():
		if actual[i][0]!=expected[i][0] or actual[i][4]!=expected[i][4]:printerr("Baseline boundary service differs");quit(1);return
		for column in [1,2,3]:max_error=maxf(max_error,absf(actual[i][column]-expected[i][column]))
	if max_error>.1:printerr("Baseline boundary positions differ: ",max_error);quit(1);return
	var stations:=[]
	for st in w.stations:stations.append({code=st.code,name=st.name,s=st.s,half=st.yard_half})
	var report:={complete=true,part=part,parts=parts,first=source.data.states[first].clock,last=target,steps=steps,stations=stations,
		engine=Engine.get_version_info().string,start_sha256=FileAccess.get_sha256(Starts.DIRECTORY+"/catalogue.json"),
		timeline_sha256=FileAccess.get_sha256(Times.DIRECTORY+"/catalogue.json"),boundary_error_m=max_error,
		wall_seconds=(Time.get_ticks_msec()-began)*.001,events=w.events,recording_sha256=FileAccess.get_sha256(path+".jsonl")}
	FileAccess.open(path+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("TRAFFIC COMPLETE ",part," ",report.wall_seconds," seconds");quit()
