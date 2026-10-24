extends RefCounted
## At most one detached group is in flight. Polling never joins unfinished work.
## The owner applies returned proposals later, after revalidating current state.
const Solver:=preload("res://sim/overtake_solver.gd")
var _topology: Dictionary
var _group: int=-1
var _job

class Job extends RefCounted:
	var topology: Dictionary
	var frame: Dictionary
	var results: Array=[]
	var began: int
	func _init(network: Dictionary,snapshot: Dictionary) -> void:
		topology=network;frame=snapshot.duplicate(true)
		frame.trains.sort_custom(func(a,b):return a.id<b.id)
		results.resize(frame.trains.size());began=Time.get_ticks_usec()
	func calculate(index: int) -> void:
		var start:=Time.get_ticks_usec()
		var plan: Dictionary=Solver.new(topology).for_train(frame,frame.trains[index])
		# Each task owns one preallocated slot. No dictionary/list resizing is
		# shared between workers, and nobody reads results before the group joins.
		results[index]={plan=plan,thread=OS.get_thread_caller_id(),usec=Time.get_ticks_usec()-start}
	func finish() -> Dictionary:
		var plans:=[];var threads:=[];var cpu:=0
		for result: Dictionary in results:
			if not result.plan.is_empty():plans.append(result.plan)
			if result.thread not in threads:threads.append(result.thread)
			cpu+=result.usec
		return {clock=frame.clock,time=frame.time,generation=frame.get("generation",0),plans=plans,inputs=frame.trains,
			occupied=frame.occupied,claims=frame.claims,worker_threads=threads,cpu_usec=cpu,wall_usec=Time.get_ticks_usec()-began}

func _init(topology: Dictionary) -> void:_topology=topology.duplicate(true)

func submit(frame: Dictionary,threads: int=2) -> bool:
	if _group>=0 or frame.trains.is_empty():return false
	_job=Job.new(_topology,frame)
	_group=WorkerThreadPool.add_group_task(_job.calculate,_job.results.size(),clampi(threads,1,4),false,"Predictive dispatcher forecasts")
	return true

func take() -> Dictionary:
	if _group<0 or not WorkerThreadPool.is_group_task_completed(_group):return {}
	WorkerThreadPool.wait_for_group_task_completion(_group)
	var result: Dictionary=_job.finish();_group=-1;_job=null
	return result

func busy() -> bool:return _group>=0

func close() -> void:
	# Shutdown only. The live dispatch loop exclusively uses nonblocking take().
	if _group>=0:WorkerThreadPool.wait_for_group_task_completion(_group)
	_group=-1;_job=null

func _notification(what: int) -> void:
	if what==NOTIFICATION_PREDELETE and _group>=0:
		WorkerThreadPool.wait_for_group_task_completion(_group)
		_group=-1;_job=null

func synchronous(frame: Dictionary) -> Dictionary:
	var job:=Job.new(_topology,frame)
	for i in job.results.size():job.calculate(i)
	return job.finish()

func parallel_complete(frame: Dictionary,threads: int=4) -> Dictionary:
	# Offline preparation / the dedicated time-skip owner only. Parallel compute
	# with an ordered join gives repeatable railway states without renderer waits.
	if frame.trains.is_empty():return synchronous(frame)
	assert(not busy())
	submit(frame,threads)
	WorkerThreadPool.wait_for_group_task_completion(_group)
	var result: Dictionary=_job.finish();_group=-1;_job=null
	return result
