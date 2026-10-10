extends RefCounted
const Worker:=preload("res://game/stream_worker.gd")
const View:=preload("res://game/geographic_world.gd")
const Profile:=preload("res://game/performance_profile.gd")
class EmptyBoards:
	var jobs:=[]

func test_worker_busy_clears_only_after_callback_finishes_without_consuming_result():
	var worker:=Worker.new();var gate:=Semaphore.new()
	worker.start(func(_job):gate.wait();return {complete=true})
	worker.submit({id="handoff"})
	var valid: bool=worker.busy()
	gate.post()
	var deadline:=Time.get_ticks_msec()+5000
	while worker.busy() and Time.get_ticks_msec()<deadline:OS.delay_usec(200)
	valid=valid and not worker.busy() and not worker.job.is_empty()
	var result: Dictionary=worker.take()
	worker.close()
	return valid and not result.is_empty() and result.result.complete

func test_persistent_workers_reuse_thread_and_publish_complete_results():
	var workers:=[]
	for i in 4:
		var worker:=Worker.new()
		worker.start(func(job):return {value=job.value*3,thread=OS.get_thread_caller_id()})
		workers.append(worker)
	var identities:={}
	var valid:=true
	for round_index in 3:
		for i in workers.size():workers[i].submit({value=round_index*10+i})
		for i in workers.size():
			var result:={}
			var deadline:=Time.get_ticks_msec()+5000
			while result.is_empty() and Time.get_ticks_msec()<deadline:
				result=workers[i].take()
				if result.is_empty():OS.delay_usec(200)
			if result.is_empty():valid=false;continue
			valid=valid and result.result.value==(round_index*10+i)*3 and result.result.thread!=OS.get_main_thread_id()
			if round_index==0:identities[i]=result.result.thread
			else:valid=valid and identities[i]==result.result.thread
	for worker in workers:worker.close()
	return valid and identities.values().size()==4

func test_worker_shutdown_reclaims_an_unconsumed_result_and_idle_workers():
	var worker:=Worker.new()
	var began:=Semaphore.new()
	worker.start(func(_job):began.post();OS.delay_msec(5);return {node=Node3D.new()})
	worker.submit({id="shutdown"})
	began.wait()
	var finished:=worker.close()
	var valid: bool=not finished.is_empty() and finished.job.id=="shutdown" and not worker.thread.is_started()
	if not finished.is_empty():finished.result.node.free()
	var idle:=Worker.new();idle.start(func(_job):return {})
	idle.close()
	return valid and not idle.thread.is_started()

func test_activation_budget_preserves_transforms_and_rebase_then_cancels():
	var view:=View.new()
	view.root=Node3D.new()
	view.performance={activation_usec=100000,activation_children=2}
	view.materials.water=ShaderMaterial.new()
	view.materials.water.shader=load("res://game/shaders/geographic_water.gdshader")
	var source:=Node3D.new()
	source.set_meta("kerala_details",{fields=12})
	for i in 5:
		var child:=Node3D.new();child.position=Vector3(i,1,2);source.add_child(child)
	view.wanted={a={}}
	view._stage("a",{node=source,origin=Vector3(2048,0,0)})
	view._activate()
	var valid: bool=view._activating.a.holder.get_child_count()==2 and not view.loaded.has("a")
	view.rebase(Vector3(1024,0,0))
	view._activate();view._activate()
	valid=valid and view.loaded.a.node.position==Vector3(1024,0,0) and view.loaded.a.node.get_child_count()==5
	valid=valid and view.loaded.a.node.get_meta("kerala_details").fields==12
	for i in 5:valid=valid and view.loaded.a.node.get_child(i).position==Vector3(i,1,2)
	var cancelled:=Node3D.new();cancelled.add_child(Node3D.new())
	view._stage("cancelled",{node=cancelled,origin=Vector3.ZERO})
	view._activate()
	valid=valid and not view._activating.has("cancelled") and not view.loaded.has("cancelled")
	view.root.free()
	return valid

func test_warm_cache_is_bounded_without_evicting_visible_chunks():
	var view:=View.new()
	view.root=Node3D.new()
	view.performance={warm_seconds=120,warm_chunks=1,gpu_cache_ceiling=INF}
	for id in ["visible","old","new"]:
		var node:=Node3D.new();view.root.add_child(node)
		view.loaded[id]={node=node}
	view._warm={old=Time.get_ticks_msec(),new=Time.get_ticks_msec()}
	view._trim_warm()
	var valid:=view.loaded.has("visible") and view.loaded.has("new") and not view.loaded.has("old")
	var id:="tile:"+str(Vector2i.ZERO)
	var cached:=Node3D.new();cached.visible=false;view.root.add_child(cached)
	view.loaded[id]={node=cached};view._warm[id]=Time.get_ticks_msec()
	view.world=RailWorld.new();view.speed_boards=EmptyBoards.new()
	view.corridor_tiles[Vector2i.ZERO]=true
	view._loading_panel=ColorRect.new();view.root.add_child(view._loading_panel)
	view._loading_label=Label.new();view.root.add_child(view._loading_label)
	view._request(Vector3(256,0,256))
	valid=valid and cached.visible and view.cache_hits==1 and not view._warm.has(id) and not view.queue.any(func(job):return job.id==id)
	view.root.free()
	return valid

func test_worker_budget_reserves_cpu_capacity():
	return Profile.worker_count(8)==2 and Profile.worker_count(16)==4 and Profile.worker_count(24)==6 and Profile.worker_count(32)==8 and Profile.worker_count(128)==8

func test_benchmark_statistics_preserve_long_stalls_and_original_samples():
	var values: Array=[500.0]
	for i in 99:values.append(8.0)
	var result:=preload("res://game/performance_benchmark.gd").stats(values)
	return values[0]==500 and result.median==8 and result.maximum==500 and result.over_16_7==1 and result.over_50==1
