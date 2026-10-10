extends RefCounted

class DeferredRenderer extends "res://game/render_telemetry.gd":
	var requests: Array[Callable]=[]
	var reads:=0
	func _enqueue(work: Callable) -> void:requests.append(work)
	func _read(_viewport: RID) -> Vector2:
		reads+=1
		return Vector2(12.5,4.25)

func test_slow_renderer_does_not_grow_telemetry_queue_or_block_sampling():
	var timing:=DeferredRenderer.new()
	for i in 100:
		if timing.sample(RID())!=Vector2.ZERO:return false
	if timing.requests.size()!=1 or timing.reads!=0:return "Timing readback ran synchronously or queued every frame"
	timing.requests.pop_front().call()
	var result:=timing.sample(RID())
	timing.close();timing.requests.pop_front().call()
	return result==Vector2(12.5,4.25) and timing.reads==1

func test_teardown_cancels_queued_viewport_reads():
	var timing:=DeferredRenderer.new()
	timing.sample(RID());timing.close()
	timing.requests.pop_front().call()
	timing.sample(RID())
	return timing.reads==0 and timing.requests.is_empty()
