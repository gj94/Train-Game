extends SceneTree
## Adversarial replay on the measured KPY/STKT fixture. Only driving/dispatcher
## commands change; routes and train positions are never teleported after entry.
const Fixture:=preload("res://tests/predictive_fixture.gd")
const InputData:=preload("res://sim/dispatch_forecast_input.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var results:=[];var okay:=true
	for item in [
		{name="baseline",actor="",duration=0.0,operator=false},
		{name="passenger_manual_three_minutes",actor="K1",duration=180.0,operator=false},
		{name="passenger_manual_ten_minutes",actor="K1",duration=600.0,operator=false},
		{name="express_manual_three_minutes",actor="B002",duration=180.0,operator=false},
		{name="express_operator_hold_three_minutes",actor="B002",duration=180.0,operator=true}]:
		var row:=replay(item);results.append(row);okay=okay and row.ok
		print("DISRUPTION ",JSON.stringify(row))
	FileAccess.open("res://.local/dispatcher-v2-2026-10-24/disruptions.json",FileAccess.WRITE).store_string(JSON.stringify({ok=okay,cases=results},"\t"))
	quit(0 if okay else 1)
func replay(item: Dictionary) -> Dictionary:
	var w:=Fixture.build();var e=w.dispatcher();e.predictive.configure(true,false)
	var began:=w.time;var wall:=Time.get_ticks_msec();var controlled:=false;var released:=false
	var had_forecast:=false;var invalidated:=false;var peak_stopped:=0.0;var stopped:=0.0
	var holds:=[];var last_hold:="";var last_plan:="";var changes:=[]
	while w.time<began+1800+item.duration and w.events.is_empty():
		if item.actor!="" and not controlled and w.time>=began+60:
			controlled=true;had_forecast=not e.predictive.plan(w,w.trains.K1).is_empty()
			if item.operator:e.operator_holds[item.actor]=true
			else:w.trains[item.actor].automatic=false;w.trains[item.actor].controller=-1
			invalidated=e.predictive.plan(w,w.trains.K1).is_empty()
		if controlled and not released and w.time>=began+60+item.duration:
			released=true
			if item.operator:e.operator_holds.erase(item.actor)
			else:w.trains[item.actor].automatic=true
		w.step(.5)
		var slow: Train=w.trains.K1;var fast: Train=w.trains.B002
		var hold: Dictionary=w.dispatch_holds.get("K1",{})
		var key: String=hold.get("station","")+":"+hold.get("other","")
		if key!=last_hold:holds.append({clock=w.clock_seconds(),hold=hold.duplicate(true)});last_hold=key
		var plan: Dictionary=e.predictive.plan(w,slow)
		var pkey: String=plan.get("station","")+":"+plan.get("action","")
		if pkey!=last_plan:changes.append({clock=w.clock_seconds(),station=plan.get("station",""),action=plan.get("action","")});last_plan=pkey
		var ready: bool=not slow.timetable.at_stop or w.clock_seconds()>slow.timetable.release_time()+2
		stopped=stopped+.5 if slow.speed<.1 and ready and not (controlled and not released and item.actor=="K1") else 0.0
		peak_stopped=maxf(peak_stopped,stopped)
	var stkt: Dictionary=w.stations.filter(func(s):return s.code=="STKT")[0]
	var progressed: bool=[w.trains.K1,w.trains.B002].all(func(t):return InputData.chainage(w,t)>stkt.s+stkt.yard_half)
	return {name=item.name,ok=w.events.is_empty() and progressed and (item.actor=="" or released) and (not had_forecast or invalidated),
		events=w.events,progressed=progressed,had_forecast=had_forecast,invalidated=invalidated,maximum_stopped_seconds=peak_stopped,
		final_trains=[w.trains.K1,w.trains.B002].map(func(t):return {id=t.id,edge=t.path[0].edge,speed=t.speed,chainage=InputData.chainage(w,t)}),
		holds=holds,plans=changes,wall_seconds=(Time.get_ticks_msec()-wall)*.001}
