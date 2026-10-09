extends RefCounted
## One persistent, sleeping worker. Only detached data crosses the mailbox;
## submission, completion and shutdown have explicit ownership boundaries.
var thread := Thread.new()
var job := {}
var _mutex := Mutex.new()
var _wake := Semaphore.new()
var _callback: Callable
var _result := {}
var _ready := false
var _stop := false
var _submitted := 0
var _began := 0
var _finished := 0

func start(callback: Callable) -> void:
	_callback=callback
	thread.start(_run,Thread.PRIORITY_LOW)

func submit(value: Dictionary) -> void:
	assert(job.is_empty())
	_mutex.lock()
	job=value
	_submitted=Time.get_ticks_usec()
	_mutex.unlock()
	_wake.post()

func take() -> Dictionary:
	_mutex.lock()
	var result:={}
	if _ready:
		result={job=job,result=_result,submitted_usec=_submitted,began_usec=_began,finished_usec=_finished}
		job={};_result={};_ready=false
	_mutex.unlock()
	return result

func _run() -> void:
	while true:
		_wake.wait()
		_mutex.lock()
		var stopping:=_stop
		var work:=job
		_mutex.unlock()
		if stopping:break
		var began:=Time.get_ticks_usec()
		var result: Dictionary=_callback.call(work)
		_mutex.lock()
		_began=began;_finished=Time.get_ticks_usec()
		_result=result;_ready=true
		_mutex.unlock()

func close() -> Dictionary:
	_mutex.lock()
	_stop=true
	_mutex.unlock()
	_wake.post()
	if thread.is_started():thread.wait_to_finish()
	_callback=Callable()
	return take()
