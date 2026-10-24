extends SceneTree
## Exercise actual nonblocking live forecasts while the railway advances.
## Deliberate owner mutations happen between steps, never on forecast workers.
const Fixture:=preload("res://tests/predictive_fixture.gd")
const InputData:=preload("res://sim/dispatch_forecast_input.gd")
var cases:=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for manual in [false,true]:cases.append(replay(manual))
	var report:={ok=cases.all(func(c):return c.ok),cases=cases}
	var output:="res://.local/dispatcher-v2-2026-10-24/async-live.json"
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("ASYNC_LIVE ",JSON.stringify(report));quit(0 if report.ok else 1)
func replay(manual: bool) -> Dictionary:
	var w:=Fixture.build();var e=w.dispatcher();e.predictive.configure(true,true)
	var began:=w.time;var acquired:=false;var returned:=false
	var accepted:=0;var workers:=[];var stations:={};var stale_peak:=0
	var hold_changes:=[];var previous_hold:="";var passed:={}
	while w.time<began+1980 and w.events.is_empty():
		if manual and not acquired and w.time>=began+90:
			w.trains.K1.automatic=false;w.trains.K1.controller=-1;acquired=true
		if acquired and not returned and w.time>=began+210:
			w.trains.K1.automatic=true;returned=true
		w.step(.5)
		var hold: Dictionary=w.dispatch_holds.get("K1",{})
		var hold_key: String=hold.get("station","")+":"+hold.get("other","")
		if hold_key!=previous_hold:
			hold_changes.append({clock=w.clock_seconds(),station=hold.get("station",""),other=hold.get("other","")});previous_hold=hold_key
		if passed.is_empty() and InputData.chainage(w,w.trains.B002)-w.trains.B002.length>InputData.chainage(w,w.trains.K1):
			passed={clock=w.clock_seconds(),slow_road=w.trains.K1.path[0].edge,fast_road=w.trains.B002.path[0].edge}
		var p: Dictionary=e.predictive.plan(w,w.trains.K1)
		if not p.is_empty():accepted+=1;stations[p.station]=true
		for thread in e.predictive.metrics.get("worker_threads",[]):
			if thread not in workers:workers.append(thread)
		stale_peak=maxi(stale_peak,e.predictive.metrics.get("discarded_stale",0))
		# Let real workers progress; this is a functional ownership check, not
		# a throughput benchmark or an attempt to emulate a fixed frame rate.
		OS.delay_msec(1)
	var station: Dictionary=w.stations.filter(func(s):return s.code=="STKT")[0]
	var progressed: bool=[w.trains.K1,w.trains.B002].all(func(t):return InputData.chainage(w,t)>station.s+station.yard_half)
	var okay: bool=w.events.is_empty() and progressed and accepted>0 and not workers.is_empty() and OS.get_thread_caller_id() not in workers and (not manual or returned)
	e.predictive.configure(false)
	return {ok=okay,manual_pause=manual,progressed=progressed,accepted_samples=accepted,stations=stations.keys(),worker_threads=workers,
		discarded_stale=stale_peak,events=w.events,clock=w.clock_seconds(),closed=not e.predictive._worker.busy(),holds=hold_changes,completed_pass=passed}
