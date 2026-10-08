class_name Train
extends RefCounted
## One train: physics and where it sits on the track graph.
##
## `path` lists the edges the train occupies, head first: [{edge, dir}, ...].
## `head_s` is the head's distance along path[0].edge. The train always moves
## towards its head; reversing swaps head and tail (driving from the other cab).

var id: String
var length: float
var path: Array = []
var head_s := 0.0
var speed := 0.0            # m/s, >= 0, towards the head
var odometer := 0.0         # metres travelled in total (for sound: rail joints, etc.)

## Combined power/brake handle, like an EMU master controller:
## +1 full power, 0 coast, -1 full service brake.
var controller := 0.0
var emergency := false
var automatic := false
var service_name := "MEMU local"
var stock_kind := "memu"       # simulation identity; rendering resolves its own assets
var rake_profile := ""         # shared formation identity for geometry, mass, views and audio
var cab_end := 1               # physical driving end, preserved when the head reverses
var can_change_ends := true    # a single locomotive + coaches needs a run-round instead
var destination := ""
var service_complete := false
var status := "Manual driving"
var timetable = null          # optional pure-sim timetable working
var completed_timetable = null # passenger result retained during empty-stock working
var depot: Dictionary = {}     # unloading / working / stabled, separate from passenger completion
var dispatch_priority := 50   # larger number gets the earliest available route

# Performance — defaults roughly an 8-car Indian Railways MEMU.
var mass := 400000.0            # kg
var max_power := 2400000.0      # W at the wheel
var max_accel := 0.55           # m/s², traction limit at low speed
var max_speed := 105.0 / 3.6    # m/s
var service_decel := 0.9        # m/s² at full service brake
var emergency_decel := 1.3      # m/s²


func _init(train_id: String, train_length: float) -> void:
	id = train_id
	length = train_length


## Acceleration (m/s²) for the current controls and speed.
func acceleration() -> float:
	var a := 0.0
	if emergency:
		a -= emergency_decel
	elif controller > 0.0:
		if speed < max_speed:
			var force := minf(mass * max_accel, max_power / maxf(speed, 1.0))
			a += controller * force / mass
	elif controller < 0.0:
		a += controller * service_decel
	# Running resistance (Davis-style: rolling + aerodynamic).
	a -= 0.006 + 0.00004 * speed * speed
	return a


func update_speed(dt: float) -> void:
	speed = maxf(0.0, speed + acceleration() * dt)


## Metres needed to stop from the current speed at full service brake.
func braking_distance() -> float:
	return speed * speed / (2.0 * service_decel)


## Moves the head `d` metres forward. Returns {} normally, or
## {buffer = true} if the head reached a buffer stop (train is stopped there),
## plus `entered` (edges newly entered, as {edge, dir, switch, against}).
func advance(graph: TrackGraph, d: float) -> Dictionary:
	var result := {entered = []}
	var remaining := d
	odometer += d
	while remaining > 0.0:
		var seg: Dictionary = path[0]
		var end_s := graph.exit_s(seg.edge, seg.dir)
		var to_end := absf(end_s - head_s)
		if remaining <= to_end:
			head_s += seg.dir * remaining
			remaining = 0.0
		else:
			remaining -= to_end
			var nxt := graph.next(seg.edge, seg.dir)
			if nxt.is_empty():
				head_s = end_s
				speed = 0.0
				odometer -= remaining   # didn't actually travel past the buffer
				result.buffer = true
				break
			path.push_front({edge = nxt.edge, dir = nxt.dir})
			head_s = graph.entry_s(nxt.edge, nxt.dir)
			result.entered.append(nxt)
	_trim_tail(graph)
	return result


## Drops edges from the end of `path` that the tail has fully left.
func _trim_tail(graph: TrackGraph) -> void:
	var remaining := length
	for i in path.size():
		var avail := _available_behind(graph, i)
		if remaining <= avail:
			path.resize(i + 1)
			return
		remaining -= avail


## Length of path[i] that lies behind the head point.
func _available_behind(graph: TrackGraph, i: int) -> float:
	var seg: Dictionary = path[i]
	if i == 0:
		return absf(head_s - graph.entry_s(seg.edge, seg.dir))
	return graph.edges[seg.edge].length


## Point `back` metres behind the head, following the occupied path.
## Returns {edge, dir, s}. Clamps to the last path edge if `back` overshoots.
func locate_behind(graph: TrackGraph, back: float) -> Dictionary:
	var remaining := back
	for i in path.size():
		var seg: Dictionary = path[i]
		var avail := _available_behind(graph, i)
		var from_s: float = head_s if i == 0 else graph.exit_s(seg.edge, seg.dir)
		if remaining <= avail or i == path.size() - 1:
			return {edge = seg.edge, dir = seg.dir, s = from_s - seg.dir * minf(remaining, avail)}
		remaining -= avail
	return {}


## Swap ends: the tail becomes the head. Only allowed at a stand.
func reverse(graph: TrackGraph) -> bool:
	if speed > 0.01 or not can_change_ends:
		return false
	var tail := locate_behind(graph, length)
	var new_path := []
	for i in range(path.size() - 1, -1, -1):
		new_path.append({edge = path[i].edge, dir = -path[i].dir})
	path = new_path
	head_s = tail.s
	cab_end = 3 - cab_end
	controller = minf(controller, 0.0)
	return true


func occupies(edge_id: String) -> bool:
	for seg in path:
		if seg.edge == edge_id:
			return true
	return false
