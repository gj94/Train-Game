extends SceneTree
## Long real-time scenery/interior journey. Native Forward+, unchanged quality.
## -- --seconds=3600 --output=res://.local/scenery-soak
var game
var output:="res://.local/scenery-soak"
var duration:=3600
var report: Array=[]
var reloads: Array=[]
var view_name:="cab"
var previous_phase:=-1
var peak_events:=0
var stopped_worlds:=0
func _initialize() -> void:
	set_meta("traffic_seed",0)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="): duration=maxi(30,int(arg.trim_prefix("--seconds=")))
		if arg.begins_with("--output="): output=arg.trim_prefix("--output=")
	call_deferred("run")
func load_journey() -> void:
	var old_world: WeakRef
	if game!=null: old_world=weakref(game.wv)
	game=null
	var started:=Time.get_ticks_msec()
	if current_scene==null: change_scene_to_file("res://game/main.tscn")
	else: reload_current_scene()
	await process_frame
	await process_frame
	game=current_scene
	var journey_index: int=reloads.size()+(1 if old_world!=null else 0)
	game._select_train("T1" if journey_index%2==0 else "T2")
	game._enter_cab()
	game.train.automatic=true
	game.performance_overlay.toggle()
	if old_world!=null:
		var released: bool=old_world.get_ref()==null
		reloads.append({load_ms=Time.get_ticks_msec()-started,old_world_released=released})
		if not released: stopped_worlds+=1
	previous_phase=-1
func phase_at(seconds: float) -> int:
	if seconds<1200: return 0
	if seconds<1500: return 1
	if seconds<1800: return 2
	if seconds<2100: return 3
	if seconds<2400: return 4
	return 0
func apply_view(phase: int) -> void:
	if phase==0:
		game._enter_cab()
		view_name="cab"
	elif phase<4:
		game._passenger_preset(phase-1)
		view_name=["first_coach","middle_coach","last_coach"][phase-1]
		game.cam._look=Vector2(.65,0)
	else:
		game.cam.set_mode(0)
		game._set_cab_visuals(false)
		game.cam.distance=75
		game.cam.pitch=-.25
		view_name="exterior"
	game.train.automatic=true
	game.cam._blend=1
	previous_phase=phase
func stats(values: Array) -> Dictionary:
	if values.is_empty(): return {}
	values.sort()
	var total:=0.0
	for value in values: total+=value
	return {mean=total/values.size(),p95=values[int(values.size()*.95)],max=values.back()}
func run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	await load_journey()
	var start:=Time.get_ticks_msec()
	var next_sample:=30.0
	var next_capture:=60.0
	var reload_at:=1200.0
	var last_tick:=Time.get_ticks_usec()
	var frame_times: Array=[]
	var gpu_times: Array=[]
	var audio_times: Array=[]
	while Time.get_ticks_msec()-start<duration*1000:
		await process_frame
		var now:=Time.get_ticks_usec()
		frame_times.append((now-last_tick)*.001)
		last_tick=now
		var seconds:=(Time.get_ticks_msec()-start)*.001
		if game.paused:
			game._set_paused(false)
			game.hud.show_modal("",false)
		var phase:=phase_at(seconds)
		if phase!=previous_phase: apply_view(phase)
		var audio_ms:=0.0
		var pending:=0
		for sound in game.train_audio.values():
			audio_ms+=sound.last_process_ms
			pending+=sound._events.size()
		peak_events=maxi(peak_events,pending)
		audio_times.append(audio_ms)
		gpu_times.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
		if seconds>=next_sample:
			var row:={seconds=seconds,world_time=game.world.time,view=view_name,train=game.train.id,speed_kmh=game.train.speed*3.6,complete=game.train.service_complete,frame_ms=stats(frame_times),gpu_ms=stats(gpu_times),audio_ms=stats(audio_times),events=pending,peak_events=peak_events,buses=AudioServer.bus_count,memory=Performance.get_monitor(Performance.MEMORY_STATIC),nodes=Performance.get_monitor(Performance.OBJECT_NODE_COUNT)}
			report.append(row)
			print(JSON.stringify(row))
			var file:=FileAccess.open(output+".json",FileAccess.WRITE)
			file.store_string(JSON.stringify({samples=report,reloads=reloads},"\t"))
			frame_times.clear()
			gpu_times.clear()
			audio_times.clear()
			next_sample+=30
		if seconds>=next_capture:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output+"-%04d-%s.png"%[roundi(seconds),view_name])
			next_capture+=300
		if seconds>=reload_at and game.train.service_complete:
			await load_journey()
			reload_at=seconds+900
			last_tick=Time.get_ticks_usec()
	print("Scenery moving soak complete: ",duration," seconds; peak events ",peak_events,"; reloads ",reloads.size(),"; unreleased worlds ",stopped_worlds)
	quit(1 if stopped_worlds else 0)
