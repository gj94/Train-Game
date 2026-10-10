extends RefCounted
## Advances the real railway with AI drivers. No scene, rendering or audio calls.
var world: RailWorld
var service_id := ""
var stop_index := -1
var target_clock := 0.0
var start_clock := 0.0
var done := false
var ok := false
var report := ""
var _event_seq := 0

func _init(w: RailWorld) -> void:
	world=w

func to_time(clock: float) -> Dictionary:
	if not is_finite(clock) or clock<=world.clock_seconds() or clock>world.clock_seconds()+86400:
		return {ok=false,reason="Choose a future time within the next 24 hours"}
	target_clock=clock;stop_index=-1
	_start()
	return {ok=true}

func to_stop(id: String, index: int) -> Dictionary:
	if not world.trains.has(id):return {ok=false,reason="This service is no longer available"}
	var t: Train=world.trains[id]
	if t.timetable==null or t.service_complete or index<0 or index>=t.timetable.stops.size() or t.timetable.actual_arrivals[index]>=0:
		return {ok=false,reason="Choose a stop this service has not reached"}
	if index<t.timetable.index:return {ok=false,reason="This stop has already been passed"}
	if t.timetable.missed_stop:return {ok=false,reason="Resolve the missed call in Journey progress before advancing to another stop"}
	service_id=id;stop_index=index;target_clock=world.clock_seconds()+86400
	_start()
	return {ok=true}

func _start() -> void:
	done=false;ok=false;report=""
	start_clock=world.clock_seconds();_event_seq=world._event_seq
	world.dispatcher().enabled=true
	# The observer's old train may finish and enter depot storage during a skip.
	world.dispatcher().manual_service=""
	for t: Train in world.trains.values():t.automatic=true

func step(seconds: float=.2) -> void:
	if done:return
	world.step(minf(minf(maxf(0,seconds),.2),target_clock-world.clock_seconds()))
	for event in world.events:
		if event.seq>_event_seq:
			done=true;report="Advance stopped: "+event.text;return
	if stop_index>=0:
		if not world.trains.has(service_id):
			done=true;report="The selected service is no longer available";return
		var t: Train=world.trains[service_id]
		var tt=t.completed_timetable if t.completed_timetable!=null else t.timetable
		if tt.actual_arrivals[stop_index]>=0:
			done=true;ok=true;report="Arrived at "+tt.stops[stop_index].name;return
		if tt.index>stop_index:
			done=true;report="The selected stop was passed without a recorded arrival";return
	if world.clock_seconds()>=target_clock-.00001:
		done=true;ok=stop_index<0
		report="Reached "+world.clock_text() if ok else "The stop was not reached within 24 simulated hours; inspect Dispatch"

func cancel() -> void:
	done=true;report="Advance stopped at "+world.clock_text()+"; all drivers remain on AI"
