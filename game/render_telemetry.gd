extends RefCounted
## Timing getters must execute ON the render thread. Reading them on the main
## thread forces a barrier in separate-render mode and distorts the benchmark.
## Publish only two copied numbers, with at most one outstanding callback.
var _mutex:=Mutex.new()
var _times:=Vector2.ZERO # GPU ms, CPU render ms; last completed sample.
var _pending:=false
var _closed:=false

func sample(viewport: RID) -> Vector2:
	_mutex.lock()
	var result:=_times
	var request:=not _closed and not _pending
	if request:_pending=true
	_mutex.unlock()
	if request:_enqueue(_collect.bind(viewport))
	return result

func _enqueue(work: Callable) -> void:
	RenderingServer.call_on_render_thread(work)

func _read(viewport: RID) -> Vector2:
	return Vector2(RenderingServer.viewport_get_measured_render_time_gpu(viewport),
		RenderingServer.viewport_get_measured_render_time_cpu(viewport))

func _collect(viewport: RID) -> void:
	_mutex.lock()
	var closed:=_closed
	_mutex.unlock()
	if not closed:
		var measured:=_read(viewport)
		_mutex.lock();_times=measured;_pending=false;_mutex.unlock()
	else:
		_mutex.lock();_pending=false;_mutex.unlock()

func close() -> void:
	# Queued callbacks retain this helper, never a scene node. A callback that
	# has not begun skips its RID read after the viewport owner starts teardown.
	_mutex.lock();_closed=true;_mutex.unlock()
