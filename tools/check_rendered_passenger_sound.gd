extends SceneTree
## Diagnostic replay in the actual rendered game. Historical snapshots are
## explicitly fixtures, never installed or certified as current-source data.
const Snapshot:=preload("res://sim/world_snapshot.gd")
var source:="res://data/timetables/intensive_v2/times/T042600.bin"
var folder:="res://.local/realism-2026-10-26/rendered-sound-stkt"
var target_ids:=["B002","B014"]
var duration:=240.0
var rotating:=true
var captures:={}
var report:={bins=[],failures=[],snapshots_are_historical_fixtures=true}

func _initialize() -> void:call_deferred("run")
func frames(count: int=5) -> void:
	for i in count:await process_frame
func capture(name: String,bus: String) -> void:
	var index:=AudioServer.get_bus_index(bus)
	if index<0:return
	var effect:=AudioEffectCapture.new();effect.buffer_length=2
	AudioServer.add_bus_effect(index,effect);captures[name]=effect
func drain() -> Dictionary:
	var out:={}
	for name in captures:
		var pcm: PackedVector2Array=captures[name].get_buffer(captures[name].get_frames_available())
		var sum:=0.0;var peak:=0.0
		for sample in pcm:sum+=sample.length_squared()*.5;peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		out[name]={rms=sqrt(sum/maxi(1,pcm.size())),peak=peak,samples=pcm.size()}
	return out
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--snapshot="):source=arg.trim_prefix("--snapshot=")
		elif arg.begins_with("--output="):folder=arg.trim_prefix("--output=")
		elif arg.begins_with("--targets="):target_ids=Array(arg.trim_prefix("--targets=").split(","))
		elif arg.begins_with("--seconds="):duration=float(arg.trim_prefix("--seconds="))
		elif arg=="--fixed":rotating=false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var catalogue=JSON.parse_string(FileAccess.get_file_as_string(source.get_base_dir()+"/catalogue.json"))
	if not catalogue is Dictionary:printerr("Missing fixture provenance");quit(1);return
	var rows: Array=catalogue.get("states",[]).filter(func(row):return row.file==source.get_file())
	if rows.size()!=1 or rows[0].sha256!=FileAccess.get_sha256(source):printerr("Fixture hash mismatch");quit(1);return
	var file:=FileAccess.open_compressed(source,FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
	if file==null:printerr("Missing diagnostic snapshot");quit(1);return
	var restored:=Snapshot.restore(file.get_var());file.close()
	if not restored.ok:printerr(restored.reason);quit(1);return
	var w: RailWorld=restored.world
	report.source=source;report.source_sha256=FileAccess.get_sha256(source);report.rotating=rotating
	report.initial_clock=w.clock_seconds();report.target_ids=target_ids
	report.command_arguments=Array(OS.get_cmdline_args())
	set_meta("benchmark",true)
	set_meta("prepared_start",{world=w,service="K1",mode="ride",timetable_id="intensive_v2",passenger_start=true})
	root.size=Vector2i(1280,720);Engine.max_fps=60
	change_scene_to_file("res://game/main.tscn");await frames()
	var game=current_scene
	var began:=Time.get_ticks_msec()
	while game.wv.loading and Time.get_ticks_msec()-began<150000:await process_frame
	if game.wv.loading:printerr("Scene did not finish loading");quit(1);return
	game.audio_options.headphones=true;game.audio_options.quiet=false;game.audio_options.reference=false
	for key in game.audio_options.levels:game.audio_options.levels[key]=0.0;game.audio_options.muted[key]=false
	game.audio_options.apply();AudioServer.set_bus_volume_db(0,-80)
	game.audio.track_level=0 # Isolate external rail; own ambience cannot mask it.
	game.hud.show_modal("");game._set_paused(false)
	capture("impacts","RailImpacts");capture("air","PassingAir")
	await frames(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"/start.png")
	var start_clock:=w.clock_seconds();began=Time.get_ticks_msec()
	var next_bin:=.25;var last:=Time.get_ticks_usec();var max_frame:=0.0;var shots:={}
	while w.clock_seconds()-start_clock<duration and Time.get_ticks_msec()-began<720000:
		await process_frame
		var now:=Time.get_ticks_usec();max_frame=maxf(max_frame,(now-last)*.000001);last=now
		var wall:=(Time.get_ticks_msec()-began)*.001
		if rotating:game.cam._look=Vector2(sin(wall*.8)*PI,sin(wall*.31)*.15)
		for id in target_ids:
			if game.train_audio.has(id) and not captures.has(id):capture(id,game.train_audio[id]._buses[0])
		if wall<next_bin:continue
		next_bin=wall+.25
		var row:={wall=wall,clock=w.clock_seconds(),own_speed=game.train.speed,paused=game.paused,loading=game.wv.loading,mode=game.cam.mode,yaw=game.cam._look.x,pcm=drain(),targets={},maximum_frame=max_frame}
		max_frame=0
		for id in target_ids:
			var state:={resident=game.train_audio.has(id),distance=game.traffic_presentation.distance_to(id),speed=w.trains[id].speed}
			if state.resident:
				var sound=game.train_audio[id];var nearest:=INF
				state.initialized=sound._ear.has("position") and sound._bogies.all(func(b):return b.has("position"))
				if state.initialized:
					for bogie in sound._bogies:nearest=minf(nearest,bogie.position.distance_to(sound._ear.position))
				state.merge({paused=sound._paused,nearest_bogie=nearest,events=sound._events.size(),receiver_error=sound._ear.position.distance_to(game.cam.global_position+game.wv.coordinate_origin) if state.initialized else null})
				if nearest<30 and not shots.has(id):
					shots[id]=true;await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(folder+"/near-"+id+".png")
			row.targets[id]=state
		report.bins.append(row)
		if game.paused:report.failures.append("Actual game paused during capture");break
		if report.bins.size()%40==0:
			FileAccess.open(folder+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
			print("RENDERED_SOUND clock=",w.clock_text()," bins=",report.bins.size())
	report.final_clock=w.clock_seconds();report.safety_events=w.events.duplicate(true)
	for id in target_ids:
		for row in report.bins:
			if row.targets[id].distance<100 and row.targets[id].speed>3 and not row.loading and not row.targets[id].resident:
				report.failures.append(id+": nearby train lost audio residency at "+str(row.clock))
		var near: Array=report.bins.filter(func(b):return b.targets[id].get("nearest_bogie",INF)<100 and b.targets[id].speed>3 and not b.loading and not b.paused)
		if near.size()<5:report.failures.append(id+": insufficient nearby moving samples")
		for row in near:
			if row.targets[id].paused or not row.pcm.has(id) or row.pcm[id].samples<100 or row.pcm[id].rms<.0000001:report.failures.append(id+": nearby rail dropout at "+str(row.clock))
	if not w.events.is_empty():report.failures.append("Safety events in diagnostic continuation")
	FileAccess.open(folder+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("RENDERED_SOUND_END bins=",report.bins.size()," failures=",report.failures)
	captures.clear();game._return_to_landing();began=Time.get_ticks_msec()
	while is_instance_valid(game) and Time.get_ticks_msec()-began<150000:await process_frame
	await frames();quit(0 if report.failures.is_empty() else 1)
