extends RefCounted
## Exclusive ownership of a running Advance and its entire railway transfers to
## this worker until take()/close() joins it. The caller must suspend every live
## world reader/writer first (including scenery jobs). Only copied scalar progress
## crosses the mutex. Physics, dispatch and reservations retain their serial order.
var _thread: Thread
var _mutex := Mutex.new()
var _cancel := false
var _finished := false
var _progress := {}
var _trial
var _steps := 0

func start(advance) -> Error:
	if _thread != null or advance == null or advance.done:return ERR_INVALID_PARAMETER
	_trial=advance;_cancel=false;_finished=false;_steps=0
	_publish(false)
	_thread=Thread.new()
	var error:=_thread.start(_run)
	if error!=OK:_thread=null;_trial=null
	return error

func progress() -> Dictionary:
	_mutex.lock()
	var value:=_progress.duplicate()
	_mutex.unlock()
	return value

func request_cancel() -> void:
	_mutex.lock()
	_cancel=true
	_mutex.unlock()

func take() -> Dictionary:
	_mutex.lock()
	var ready:=_finished
	_mutex.unlock()
	if not ready or _thread==null:return {}
	return _join()

func close() -> Dictionary:
	request_cancel()
	return _join() if _thread!=null else {}

func _join() -> Dictionary:
	var result={trial=_thread.wait_to_finish(),progress=progress()}
	_thread=null;_trial=null
	return result

func _publish(finished: bool) -> void:
	var state:={clock=_trial.world.clock_seconds(),start_clock=_trial.start_clock,
		done=_trial.done,ok=_trial.ok,report=_trial.report,steps=_steps}
	_mutex.lock()
	_progress=state;_finished=finished
	_mutex.unlock()

func _run():
	var next_progress:=Time.get_ticks_usec()+100000
	while not _trial.done:
		_mutex.lock()
		var cancel:=_cancel
		_mutex.unlock()
		if cancel:
			_trial.cancel();break
		_trial.step()
		_steps+=1
		if Time.get_ticks_usec()>=next_progress:
			_publish(false)
			next_progress=Time.get_ticks_usec()+100000
	_publish(true)
	return _trial
