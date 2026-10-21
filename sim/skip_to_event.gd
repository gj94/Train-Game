extends "res://sim/time_skip.gd"
## One actual simulation, with a bounded 60-second delayed committed view.
## Detect encounters in the look-ahead; restore in-place to the earliest trigger.
const Options := preload("res://sim/skip_options.gd")
const History := preload("res://sim/skip_history.gd")
const Encounters := preload("res://sim/skip_encounters.gd")
const MapState := preload("res://sim/skip_map_state.gd")
const LEAD := 60.0
const CHECKPOINT_SECONDS := 5.0
var options := {}
var last_event := {}
var ignored: Array = []
var _history := History.new()
var _encounters := Encounters.new()
var _frames: Array = []
var _candidate := {}
var _held_signal := ""
var _next_capture := 0.0
var _lookahead := false
var _replaying := false
var _finish_at := 0.0
var _finish_ok := true
var _finish_report := ""

func to_event(id: String, requested: Dictionary, dismissed: Array=[]) -> Dictionary:
	if not world.trains.has(id) or world.trains[id].lifecycle!="active" or world.trains[id].service_complete:
		return {ok=false,reason="Choose an active passenger service before skipping to its next event"}
	var t: Train=world.trains[id]
	if t.timetable!=null and t.timetable.missed_stop:
		return {ok=false,reason="Resolve the missed call in Journey progress before skipping"}
	service_id=id;options=Options.normalized(requested);ignored=dismissed.duplicate(true)
	_lookahead=Options.encounters(options);target_clock=world.clock_seconds()+86400
	_start();_encounters.sample(world,id)
	_watch_signal(t)
	_observe()
	if _lookahead:_capture()
	return {ok=true}

func presentation() -> Dictionary:
	if not _lookahead or done or _replaying:return super.presentation()
	var frame:=_committed_frame()
	return {clock=frame.clock,map=frame.get("map",{}),forecasting=true}

func _committed_frame() -> Dictionary:
	var limit:=maxf(start_clock,world.clock_seconds()-LEAD)
	var chosen: Dictionary=_frames[0]
	for f in _frames:
		if f.clock>limit+.00001:break
		chosen=f
	return chosen

func _capture() -> void:
	var state:=_history.capture(world)
	state.map=MapState.capture(world,preview_service,preview_layout) if preview_enabled else {}
	_frames.append(state);_next_capture=world.clock_seconds()+CHECKPOINT_SECONDS
	# Retain the checkpoint immediately before the 60-second horizon.
	while _frames.size()>2 and _frames[1].clock<world.clock_seconds()-LEAD-CHECKPOINT_SECONDS:
		_frames.pop_front()

func step(seconds: float=.2) -> void:
	if done:return
	if _replaying:
		var remaining:=_finish_at-world.clock_seconds()
		if remaining>.00001:world.step(minf(.2,remaining))
		if world.clock_seconds()>=_finish_at-.00001:_finish()
		return
	if not _lookahead and not _candidate.is_empty():
		_begin_return(_candidate);return
	world.step(minf(clampf(seconds,0,.2),target_clock-world.clock_seconds()))
	for event in world.events:
		if event.seq>_event_seq:
			# Never continue through a protection event merely to fill look-ahead.
			if _candidate.is_empty():_candidate={clock=world.clock_seconds(),kind="safety",text="Advance stopped: "+event.text,ok=false}
			_begin_return(_candidate);return
	_observe()
	if not _candidate.is_empty() and (not _lookahead or world.clock_seconds()>=_candidate.clock+LEAD-.00001):
		_begin_return(_candidate);return
	if world.clock_seconds()>=target_clock-.00001:
		_begin_return(_candidate if not _candidate.is_empty() else {clock=world.clock_seconds(),kind="timeout",text="No selected event within 24 simulated hours. Inspect Dispatch.",ok=false});return
	if _lookahead and world.clock_seconds()>=_next_capture-.00001:_capture()

func _observe() -> void:
	if not world.trains.has(service_id):
		_consider({clock=world.clock_seconds(),kind="complete",text="Your service is no longer available"});return
	var t: Train=world.trains[service_id]
	if t.lifecycle!="active" or t.service_complete:
		_consider({clock=world.clock_seconds(),kind="complete",text="Your passenger service has finished"});return
	if options.signal:
		if not _held_signal.is_empty():
			var ns:=world.next_signal(t)
			if not ns.is_empty() and ns.id==_held_signal and world.aspect(_held_signal)!=RailWorld.Aspect.RED:
				_consider({clock=world.clock_seconds(),kind="signal",signal_id=_held_signal,text="Signal "+_held_signal+" now permits movement"})
				_held_signal=""
		_watch_signal(t)
	if options.stops and t.timetable!=null and not t.timetable.at_stop:
		var tt=t.timetable;var stop: Dictionary=tt.stop_ahead()
		var distance:=world._stop_distance(t.path[0].edge,t.path[0].dir,t.head_s,stop,[])
		var braking:=t.speed*t.speed/(2*t.service_decel*.45)+t.speed*4+100
		if distance<=maxf(1000,braking):
			_consider({clock=world.clock_seconds(),kind="stops",stop=tt.index,text="Approaching %s · %d m remaining%s" % [stop.name,roundi(distance)," · early braking point" if distance>1000 else ""]})
	if _lookahead:
		for event in _encounters.sample(world,service_id):
			if not options[event.kind]:continue
			event.clock=maxf(start_clock,event.time-LEAD)
			var seconds:=maxf(0,event.time-event.clock)
			var action: String={crossing="Oncoming pass",overtaking="You begin overtaking",overtaken="You begin being overtaken by"}[event.kind]
			event.text="%s %s (%s) in about %d seconds. This is the simulated start of the pass; manual driving can change it." % [action,event.name,event.other,roundi(seconds)]
			_consider(event)

func _watch_signal(t: Train) -> void:
	if not options.signal or t.speed>.5:return
	# A red during booked dwell is not yet a departure hold.
	if t.timetable!=null and t.timetable.at_stop and world.clock_seconds()<t.timetable.release_time():return
	var ns:=world.next_signal(t,250)
	if not ns.is_empty() and world.aspect(ns.id)==RailWorld.Aspect.RED:_held_signal=ns.id

func _consider(event: Dictionary) -> void:
	for old in ignored:
		if old.get("kind","")!=event.kind:continue
		if event.kind=="stops" and old.get("stop",-1)==event.stop:return
		if event.has("other") and old.get("other","")==event.other and absf(old.get("time",-1000)-event.time)<30:return
	if _candidate.is_empty() or event.clock<_candidate.clock:_candidate=event

func _begin_return(event: Dictionary) -> void:
	last_event=event.duplicate(true);_finish_at=event.clock
	_finish_ok=event.get("ok",true);_finish_report=event.text
	if _lookahead:
		var frame: Dictionary=_frames[0]
		for f in _frames:
			if f.clock>_finish_at+.00001:break
			frame=f
		_history.restore(world,frame)
	_frames.clear();_replaying=true
	if world.clock_seconds()>=_finish_at-.00001:_finish()

func _finish() -> void:
	done=true;ok=_finish_ok;report=_finish_report
	_frames.clear();_history._passenger_cache.clear()

func cancel() -> void:
	if done:return
	# Stop at the last committed, displayed position, never in unseen look-ahead.
	if _lookahead and not _replaying:
		var frame:=_committed_frame();_history.restore(world,frame)
	done=true;ok=false;report="Advance stopped at "+world.clock_text()+"; all drivers remain on AI"
	_frames.clear();_history._passenger_cache.clear()
