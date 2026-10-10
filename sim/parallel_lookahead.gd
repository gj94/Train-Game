extends RefCounted
## Per-train passenger exchange and read-only AI work between dispatch/movement.
## Each task exclusively owns ONE train's passenger data. Timetable release times
## are deferred; signals, switches and train motion never mutate in a task.
## Results use preallocated slots and are joined before ordered commits resume.
const Driving := preload("res://sim/automatic_control.gd")
const Passengers := preload("res://sim/passenger_service.gd")
var world: RailWorld
var trains: Array
var results: Array[Dictionary]=[]
var record_threads:=false
var delta:=0.0
var jobs: Array[int]=[]

func prepare(w: RailWorld, active: Array, workers: int, trace: bool=false, seconds: float=0.0) -> Array[Dictionary]:
	world=w;trains=active;record_threads=trace;delta=seconds
	results.resize(trains.size())
	results.fill({});jobs.clear()
	for index in trains.size():
		if useful_work(trains[index]):jobs.append(index)
	if workers>1 and jobs.size()>1:
		var group:=WorkerThreadPool.add_group_task(_calculate,jobs.size(),mini(workers,jobs.size()),true,"Railway train work")
		WorkerThreadPool.wait_for_group_task_completion(group)
	else:
		for index in jobs.size():_calculate(index)
	# Do not retain a world -> frame -> world reference cycle between slices.
	world=null;trains=[]
	return results

static func useful_work(t: Train) -> bool:
	if t.automatic and not t.emergency and t.speed>.01:return true
	if t.passengers.is_empty():return t.stock_kind.begins_with("ported:")
	if t.passengers.phase in ["opening","exchange","closing"]:return true
	var tt=t.completed_timetable if t.completed_timetable!=null else t.timetable
	return tt!=null and tt.at_stop and tt.index!=t.passengers.visit and t.speed<=.001

func _calculate(job_index: int) -> void:
	var index: int=jobs[job_index]
	var t: Train=trains[index]
	var result:={passenger_release=Passengers.update(world,t,delta,true) if delta>0 else -1.0,
		thread=OS.get_thread_caller_id() if record_threads else 0}
	results[index]=result
	# Waiting trains usually return before any look-ahead is needed. Leave their
	# rare departure calculation to the ordered driver instead of wasting a job.
	if not t.automatic or t.emergency or t.speed<=.01:
		return
	if t.timetable!=null:
		if t.timetable.complete() or t.timetable.missed_stop:
			return
		if t.timetable.at_stop and world.clock_seconds()+.000001<t.timetable.release_time():
			return
	var envelope:=Driving.speed_envelope(world,t)
	var reds: Array=[]
	var obstructions: Array=[]
	var cur: Dictionary=t.path[0]
	var from_s:=t.head_s
	var distance:=0.0
	# Preserve the original scan order and horizon semantics. Aspects themselves
	# MUST be read later: an earlier train can change them during the commit loop.
	for i in world.graph.edges.size():
		for sid in world._signals_on.get(world._key(cur.edge,cur.dir),[]):
			var ahead: float=(world.signals[sid].s-from_s)*cur.dir
			if ahead>=0:reds.append({id=sid,distance=distance+ahead})
		distance+=absf(world.graph.exit_s(cur.edge,cur.dir)-from_s)
		var next: Dictionary=world.graph.next(cur.edge,cur.dir)
		if next.is_empty() or distance>envelope.horizon:break
		obstructions.append({edge=next.edge,dir=next.dir,against=next.against,distance=distance})
		cur=next;from_s=world.graph.entry_s(cur.edge,cur.dir)
	result.merge({envelope=envelope,buffer=world.distance_to_buffer(t,envelope.horizon),
		next_signal=world.next_signal(t),red_candidates=reds,obstruction_candidates=obstructions})
