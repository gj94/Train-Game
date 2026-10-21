extends SceneTree
## Native 2D map A/B. Identical 09:00 prepared railway, fixed 600 s work, ABBA.
## Separately measures event history/forecasting; never calls these target-PC FPS.
const Snapshot := preload("res://sim/world_snapshot.gd")
const Advance := preload("res://sim/time_skip.gd")
const Events := preload("res://sim/skip_to_event.gd")
const Worker := preload("res://sim/time_skip_worker.gd")
const MapState := preload("res://sim/skip_map_state.gd")
var output := "res://.local/r41-skip-benchmark.json"
var seconds := 600.0
var report := {runs=[]}
var diagram

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
		if arg.begins_with("--sim-seconds="):seconds=float(arg.trim_prefix("--sim-seconds="))
	call_deferred("run")

func restore(checkpoint: Dictionary) -> RailWorld:
	var result:=Snapshot.restore(checkpoint);assert(result.ok,str(result.get("reason","")));return result.world

func write() -> void:
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))

func run() -> void:
	Engine.max_fps=30;OS.low_processor_usage_mode=false
	root.size=Vector2i(1280,720);root.disable_3d=true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	diagram=preload("res://game/skip_map.gd").new();root.add_child(diagram)
	diagram.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var file:=FileAccess.open_compressed("res://data/railway_times/T032400.bin",FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
	var checkpoint: Dictionary=file.get_var(false);file.close()
	report.merge({cpu=OS.get_processor_name(),renderer=RenderingServer.get_video_adapter_name(),engine=Engine.get_version_info().string,simulated_seconds=seconds,
		method="Identical 09:00 all-AI railway, fixed duration, 30 FPS, native 2D map; ABBA, followed by bounded event-history measurement. Development PC."})
	var expected:={}
	for mode in ["hidden","map","map","hidden","event_history"]:
		var w:=restore(checkpoint);var layout:=MapState.geometry(w)
		var advance=Events.new(w) if mode=="event_history" else Advance.new(w)
		if mode!="hidden":advance.configure_preview("K1",layout)
		diagram.layout=layout;diagram.state={};diagram.visible=mode!="hidden"
		var memory_start:=OS.get_static_memory_usage()
		if mode=="event_history":
			advance.to_event("K1",{"stops":false,"signal":false,"crossing":false,"overtaking":false,"overtaken":false})
			# Test-only: exercise the full look-ahead/history cost for the same
			# duration while suppressing event interruptions. No runtime setting.
			advance._lookahead=true;advance._capture()
			advance.target_clock=w.clock_seconds()+seconds
		else:advance.to_time(w.clock_seconds()+seconds)
		var start:=w.clock_seconds();var worker:=Worker.new()
		var frames:=0;var refreshes:=0;var last_clock:=-1.0;var max_memory:=memory_start
		var started:=Time.get_ticks_usec();assert(worker.start(advance)==OK)
		while true:
			var completed: Dictionary=worker.take()
			if not completed.is_empty():break
			var progress:=worker.progress()
			if mode!="hidden" and progress.clock!=last_clock:
				diagram.update_state(progress.map);last_clock=progress.clock;refreshes+=1
			max_memory=maxi(max_memory,OS.get_static_memory_usage())
			await process_frame;frames+=1
		var elapsed:=(Time.get_ticks_usec()-started)/1000000.0
		var state:=Snapshot.capture(w)
		if expected.is_empty():expected=state
		var row:={mode=mode,wall_seconds=elapsed,advanced_seconds=w.clock_seconds()-start,speedup=(w.clock_seconds()-start)/elapsed,
			frames=frames,map_updates=refreshes,peak_extra_heap_bytes=max_memory-memory_start,safety_events=w.events.size(),same_state=state==expected,ok=advance.ok,report=advance.report}
		report.runs.append(row);write();print("SKIP_BENCH ",JSON.stringify(row))
		if mode=="map" and DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(output.trim_suffix(".json")+"-map.png")
		if mode!="event_history" and (not row.same_state or not row.ok):report.error="Map changed railway outcome";write();quit(1);return
		advance=null;w=null
	report.complete=true;write();quit(0)
