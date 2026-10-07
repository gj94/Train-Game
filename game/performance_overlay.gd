extends CanvasLayer
## Optional live diagnostics for target-PC playtests (F10).
var game
var enabled := false
var _label: Label
var _elapsed := 0.0

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

func _process(delta: float) -> void:
	_elapsed+=delta
	if _elapsed<.5 or game==null: return
	_elapsed=0
	var audio_ms:=0.0
	var pending:=0
	for sound in game.train_audio.values():
		audio_ms+=sound.last_process_ms
		pending+=sound._events.size()
	var fps:=Performance.get_monitor(Performance.TIME_FPS)
	var gpu:=RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid())
	var timing = preload("res://game/audio_output_timing.gd")
	timing.refresh()
	_label.text="PERFORMANCE · F10 hide\n%d FPS · %.1f ms/frame · GPU %.1f ms\nAudio control %.2f ms · queued impacts %d · buses %d\nAudio output %s · buffer estimate %.1f ms + mix\nDraw calls %d · primitives %.2f M · nodes %d\nWindow %d × %d" % [
		roundi(fps),1000/maxf(1,fps),gpu,audio_ms,pending,AudioServer.bus_count,
		AudioServer.get_driver_name(),timing.output_latency*1000,
		roundi(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)/1000000,
		roundi(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		get_window().size.x,get_window().size.y]
