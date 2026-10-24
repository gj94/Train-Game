extends SceneTree
## Bounded real-route regression, using isolated measured 11:35 fixture positions.
## Full-day prepared-state integration is validated separately.
const Snapshot:=preload("res://sim/world_snapshot.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var w:=preload("res://tests/predictive_fixture.gd").build();var e=w.dispatcher();e.predictive.configure(true,false)
	var samples:=[];var last:={};var main_pass:=false;var earlier_hold:=false;var loop_used:=false
	var began:=Time.get_ticks_msec()
	while w.clock_seconds()<42900:
		w.step(.5)
		var slow: Train=w.trains.K1;var fast: Train=w.trains.B002
		var p: Dictionary=e.predictive.plan(w,slow)
		var hold: Dictionary=w.dispatch_holds.get("K1",{})
		if hold.get("kind","")=="overtake" and hold.get("station","")=="KPY":earlier_hold=true
		if slow.path[0].edge=="STKT_P3":loop_used=true
		if fast.path[0].edge=="STKT_P1" and fast.speed>20 and slow.path[0].edge=="STKT_P3":main_pass=true
		var key:={slow=slow.path[0].edge,fast=fast.path[0].edge,station=p.get("station",""),action=p.get("action",""),other=p.get("other",""),hold=hold.get("station","")+hold.get("other","")}
		if key!=last:
			samples.append({clock=w.clock_seconds(),state=key,slow_speed=slow.speed,fast_speed=fast.speed,order=p.get("order",{})});last=key
	var ok:=not earlier_hold and loop_used and main_pass and w.events.is_empty()
	var report:={ok=ok,earlier_hold=earlier_hold,loop_used=loop_used,main_pass=main_pass,events=w.events,history=w.dispatch_history,samples=samples,wall_seconds=(Time.get_ticks_msec()-began)*.001}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.local/dispatcher-v2-2026-10-24"))
	FileAccess.open("res://.local/dispatcher-v2-2026-10-24/order-fixture-live.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("Predictive live regression: ",ok," loop=",loop_used," main pass=",main_pass," earlier hold=",earlier_hold," safety=",w.events.size()," wall=",report.wall_seconds)
	quit(0 if ok else 1)
