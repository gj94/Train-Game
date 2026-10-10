extends RefCounted
## Main-thread coach assembly after background resource loading.
## A partial formation stays hidden and is never published to cameras/audio.
const View:=preload("res://game/ported_train_view.gd")
var pending:={}
var completed:=0
var resources:={}
var requested:={}
var maximum_step_ms:=0.0
var timings:=[]

func request(game,id: String,parent: Node3D,audio: bool=true) -> void:
	if pending.has(id):return
	var paths:=[]
	var choice: String=game.world.trains[id].stock_kind.trim_prefix("ported:")
	for entry in View.Stock.formation(choice,game.world.trains[id].rake_profile):
		var path: String="res://assets/models/ported/%s.glb"%entry.model
		if path in paths:continue
		paths.append(path)
		if not resources.has(path) and not requested.has(path):
			# The dummy renderer cannot safely initialize shader RIDs from concurrent
			# resource threads. Native gameplay still uses background loading.
			if DisplayServer.get_name()=="headless":resources[path]=load(path)
			else:
				ResourceLoader.load_threaded_request(path,"PackedScene")
				requested[path]=true
	parent.hide()
	pending[id]={parent=parent,paths=paths,resources=[],view=null,audio=audio}

func advance(game,id: String="",blocking: bool=false) -> bool:
	for path in requested.keys():
		if ResourceLoader.load_threaded_get_status(path)==ResourceLoader.THREAD_LOAD_LOADED:
			resources[path]=ResourceLoader.load_threaded_get(path);requested.erase(path)
	if pending.is_empty():return false
	if id.is_empty():id=pending.keys()[0]
	if not pending.has(id):return false
	var job: Dictionary=pending[id]
	var began:=Time.get_ticks_usec()
	if job.view==null:
		for path in job.paths:
			if resources.has(path):continue
			var status:=ResourceLoader.load_threaded_get_status(path)
			if status==ResourceLoader.THREAD_LOAD_FAILED or status==ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				push_error("Train resource failed: "+path)
				game.traffic_presentation.release(id)
				return false
			if not blocking and status!=ResourceLoader.THREAD_LOAD_LOADED:return false
		for path in job.paths:
			if not resources.has(path):
				resources[path]=ResourceLoader.load_threaded_get(path);requested.erase(path)
		job.view=View.new();job.view.motion=game.train_motions[id]
		job.view.begin_build(game.world.trains[id],game.world.graph,job.parent)
	var car: int=job.view.cars.size()
	var model: String=job.view.formation[car].model
	var done: bool=job.view.build_next_car()
	var assembled:=Time.get_ticks_usec();var finalized:=assembled
	if done:
		job.view.finish_build()
		finalized=Time.get_ticks_usec()
		game.train_views[id]=job.view
		job.parent.show()
		pending.erase(id);completed+=1
		if job.audio:game.traffic_presentation.ensure_audio(id)
	if not blocking:
		var elapsed: float=(Time.get_ticks_usec()-began)*.001
		maximum_step_ms=maxf(maximum_step_ms,elapsed)
		timings.append({id=id,car=car,model=model,total_ms=elapsed,assembly_ms=(assembled-began)*.001,finish_ms=(finalized-assembled)*.001,audio_ms=(Time.get_ticks_usec()-finalized)*.001 if done else 0.0})
		if timings.size()>128:timings.pop_front()
	return done

func cancel(id: String) -> void:
	pending.erase(id)
