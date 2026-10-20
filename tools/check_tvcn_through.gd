extends SceneTree
## Replay both through VBs from prepared time states before their TVCN approach.
const Times:=preload("res://persistence/railway_times.gd")
const Policy:=preload("res://sim/priority_dispatch.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var directory:=Times.DIRECTORY
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--times="):directory=arg.trim_prefix("--times=")
	var catalogue: Dictionary=Times.catalogue(directory)
	if not catalogue.ok:printerr(catalogue.reason);quit(1);return
	var reports:=[]
	for config in [{id="B012",clock=36900,main="TVCN_P2",home="TVCN_TVP_U0-H"},{id="B001",clock=40200,main="TVCN_P1",home="VELI_TVCN_D0-H"}]:
		var rows: Array=catalogue.data.states.filter(func(r):return int(r.clock)==config.clock)
		if rows.is_empty():printerr("Missing pre-approach state");quit(1);return
		var loaded:=Times.load_state(rows[0],directory)
		if not loaded.ok:printerr(loaded.reason);quit(1);return
		var w: RailWorld=loaded.world
		var train: Train=w.trains[config.id]
		var direction: int=train.path[0].dir
		var st:=Policy.station(w,config.main)
		var committed:={}
		var passed_road:=""
		var peak_speed:=0.0
		var start:=w.clock_seconds()
		while w.clock_seconds()<start+3600 and w.events.is_empty():
			w.step(2)
			var home: Dictionary=w.signals[config.home]
			if committed.is_empty() and not home.route.is_empty() and home.owner in ["",train.id] and w.dispatcher()._planner.approach_signals(w,train).any(func(a):return a.id==config.home):
				committed={clock=w.clock_seconds(),destination=home.destination,road=home.route[-1].edge,
					distance=absf(Policy.chainage(w,train)-st.s),reason=w.dispatcher().states.get(train.id,{}).get("reason","")}
			if train.path[0].edge in st.platform_tracks:
				passed_road=train.path[0].edge;peak_speed=maxf(peak_speed,train.speed*3.6)
			if not passed_road.is_empty() and (Policy.chainage(w,train)-st.s)*direction>st.yard_half+train.length:break
		var ok: bool=passed_road==config.main and w.events.is_empty()
		reports.append({id=train.id,ok=ok,road=passed_road,peak_yard_kmh=peak_speed,prepared=committed,events=w.events,source=rows[0].sha256})
		print(JSON.stringify(reports[-1]))
	FileAccess.open("res://.local/tvcn-through-report.json",FileAccess.WRITE).store_string(JSON.stringify(reports,"\t"))
	quit(0 if reports.all(func(r):return r.ok) else 1)
