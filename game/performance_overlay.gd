extends CanvasLayer
## Optional live diagnostics for target-PC playtests (F10).
var game
var enabled := false
var _label: Label
var _elapsed := 0.0
var _frames: Array=[]
var _last_frame_usec:=0
var _render_timing:=preload("res://game/render_telemetry.gd").new()

func _exit_tree() -> void:
	_render_timing.close()

func _ready() -> void:
	layer=20
	_label=Label.new()
	_label.position=Vector2(20,155)
	_label.add_theme_font_size_override("font_size",16)
	_label.add_theme_constant_override("outline_size",6)
	_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_label.visible=false
	add_child(_label)
	set_process(false)

func toggle() -> void:
	enabled=not enabled
	_label.visible=enabled
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),enabled)
	set_process(enabled)
	_elapsed=1
	_frames.clear()
	_last_frame_usec=Time.get_ticks_usec()

func _process(delta: float) -> void:
	var now:=Time.get_ticks_usec()
	_frames.append((now-_last_frame_usec)*.001)
	_last_frame_usec=now
	if _frames.size()>240:_frames.pop_front()
	_elapsed+=delta
	if _elapsed<.5 or game==null: return
	_elapsed=0
	var audio_ms:=0.0
	var pending:=0
	for sound in game.train_audio.values():
		audio_ms+=sound.last_process_ms
		pending+=sound._events.size()
	var fps:=Performance.get_monitor(Performance.TIME_FPS)
	var gpu:=_render_timing.sample(get_viewport().get_viewport_rid()).x
	var timing = preload("res://game/audio_output_timing.gd")
	timing.refresh()
	var ordered:=_frames.duplicate();ordered.sort()
	_label.text="PERFORMANCE · F10 hide\n%d FPS · %.1f ms/frame · p95 %.1f · p99 %.1f · GPU %.1f ms\nAudio control %.2f ms · queued impacts %d · buses %d\nAudio output %s · buffer estimate %.1f ms + mix\nDraw calls %d · primitives %.2f M · nodes %d\nWindow %d × %d" % [
		roundi(fps),1000/maxf(1,fps),ordered[floori((ordered.size()-1)*.95)],ordered[floori((ordered.size()-1)*.99)],gpu,audio_ms,pending,AudioServer.bus_count,
		AudioServer.get_driver_name(),timing.output_latency*1000,
		roundi(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)/1000000,
		roundi(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		get_window().size.x,get_window().size.y]
	_label.text+="\nGPU allocations %.2f GiB · textures %.2f · buffers %.2f" % [
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1073741824.0,
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)/1073741824.0,
		Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)/1073741824.0]
	if game.geographic_drive:
		var active:=0
		for worker in game.wv.workers:active+=int(not worker.runner.job.is_empty())
		_label.text+="\nScenery workers %d/%d · pending %d · warm %d · reuse %d\nStream main-thread %.2f ms" % [active,game.wv.workers.size(),game.wv.queue.size(),game.wv._warm.size(),game.wv.cache_hits,game.wv.last_stream_ms]
