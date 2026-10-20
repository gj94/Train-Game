extends SceneTree
## Replay the reported NCJ–ERS VB journey, including a delayed manual driver.
const Starts=preload("res://persistence/service_starts.gd")
const Prediction=preload("res://sim/dispatch_prediction.gd")
var directory:="res://tests/fixtures/kzt-r36"
var output:=".local/kzt-dispatch.json"
var delay:=0.0
var require_forward:=false

func _initialize() -> void:call_deferred("run")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--starts="):directory=arg.trim_prefix("--starts=")
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
		if arg.begins_with("--delay="):delay=float(arg.trim_prefix("--delay="))
		if arg=="--require-forward":require_forward=true
	var catalogue:=Starts.catalogue(directory)
	if not catalogue.ok:printerr(catalogue.reason);quit(1);return
	var row: Dictionary=catalogue.data.services.filter(func(r):return r.id=="B012")[0]
	var loaded:=Starts.load_start(row,directory)
	if not loaded.ok:printerr(loaded.reason);quit(1);return
	var w: RailWorld=loaded.world
	for t: Train in w.trains.values():t.automatic=true
	var engine=w.dispatcher();engine.manual_service="B012";engine.enabled=true
	var t: Train=w.trains.B012
	var began:=Time.get_ticks_msec()
	var waits:={};var changes:=[]
	var home:="KZT_PYD_M0-NH"
	var last_home:=""
	var last_plan:=""
	var home_prepared:={}
	var circular:=0.0
	var unsafe_release:=false
	var received:=false
	var delayed_at:=-1.0
	var stop_at:=w.clock_seconds()+7200
	while w.clock_seconds()<stop_at and w.events.is_empty():
		# Delay the manual driver AFTER a future platform has been promised.
		# The reservation must remain safe when the arrival estimate slips.
		if delay>0 and delayed_at<0 and engine.future_clearances.plans.any(func(p):return p.incoming=="B012"):
			delayed_at=w.clock_seconds()
		var paused: bool=delayed_at>=0 and w.clock_seconds()<delayed_at+delay
		t.automatic=not paused
		if paused:t.controller=-1
		w.step(.5)
		var ns:=w.next_signal(t)
		if t.speed<.1 and not ns.is_empty() and w.aspect(ns.id)==RailWorld.Aspect.RED and not t.timetable.at_stop:
			waits[ns.id]=waits.get(ns.id,0.0)+.5
		var aspect: String=["RED","YELLOW","GREEN"][w.aspect(home)]
		if aspect!=last_home:
			last_home=aspect
			var h: Dictionary=w.signals[home]
			var d: float=w._stop_distance(t.path[0].edge,t.path[0].dir,t.head_s,{block=h.edge,direction=-1,s=h.s},[])
			var entry:={time=w.clock_text(),clock=w.clock_seconds(),home=aspect,distance=d if is_finite(d) else -1,speed_kmh=t.speed*3.6,destination=h.destination}
			changes.append(entry);print("HOME ",JSON.stringify(entry))
			if not home_prepared.has("clock") and aspect!="RED" and d>0 and w.clock_seconds()>row.departure:
				home_prepared=entry
		var plans: String=JSON.stringify(engine.future_clearances.plans.filter(func(p):return p.incoming=="B012"))
		if plans!=last_plan:
			last_plan=plans;print("PLANS ",w.clock_text()," ",plans)
			changes.append({time=w.clock_text(),plans=JSON.parse_string(plans)})
		if engine.alerts.any(func(a):return a.kind=="conflict"):circular+=.5
		received=received or (t.path.size()==1 and t.path[0].edge in ["KZT_P1","KZT_P2"])
		for p in engine.future_clearances.plans:
			if p.incoming=="B012" and not p.received and w.trains[p.opponent].path.any(func(s):return w.single_line_sections.get(s.edge,"")==p.approach_section):
				unsafe_release=true
		if received and Prediction.chainage(w,t)<240000:break
	var results:={}
	for id in ["B012","B014","B088"]:
		var train: Train=w.trains[id];var tt=train.timetable
		results[id]={road=train.path[0].edge,arrivals=tt.actual_arrivals,departures=tt.actual_departures,calls=tt.stops.map(func(s):return s.name)}
	var ok: bool=w.events.is_empty() and received and circular==0 and not unsafe_release and Prediction.chainage(w,t)<240000 and (delay==0 or delayed_at>=0)
	if require_forward:
		ok=ok and waits.get("ERL-N2",0)<=1 and home_prepared.get("distance",0)>=3500
		ok=ok and changes.any(func(c):return c.get("plans",[]).any(func(p):return p.station=="KZT" and p.incoming=="B012" and p.vacater=="B014" and p.opponent=="B088"))
	var report:={ok=ok,delay=delay,disturbance_clock=delayed_at,waits=waits,home_prepared=home_prepared,changes=changes,services=results,
		events=w.events,circular_seconds=circular,unsafe_release=unsafe_release,clock=w.clock_text(),wall_seconds=(Time.get_ticks_msec()-began)*.001,require_forward=require_forward,
		source_start_sha256=row.sha256,sources=preload("res://persistence/prepared_sources.gd").collect()}
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("KZT_REPLAY ",JSON.stringify({ok=ok,clock=w.clock_text(),waits=waits,home_prepared=home_prepared,circular_seconds=circular,unsafe_release=unsafe_release,report=output}))
	quit(0 if ok else 1)
