extends RefCounted
## Five seconds of timestamped physical wheel poses, independent of audio/rendering.
var frames := []

func clear() -> void:
	frames.clear()

func append(time: float,speed: float,positions: PackedVector3Array,tangents: PackedVector3Array,curvatures: PackedFloat32Array) -> void:
	frames.append({time=time,speed=speed,positions=positions,tangents=tangents,curvatures=curvatures})
	while frames.size()>2 and frames[1].time<time-5.0: frames.pop_front()

func sample(time: float) -> Dictionary:
	if frames.is_empty(): return {}
	if time<frames[0].time: return {} # No invented pre-seek history.
	if time>=frames[-1].time: return frames[-1]
	var low := 0
	var high := frames.size()-1
	while high-low>1:
		var mid := (low+high)/2
		if frames[mid].time<=time: low=mid
		else: high=mid
	var a: Dictionary=frames[low]
	var b: Dictionary=frames[high]
	var weight: float=(time-a.time)/(b.time-a.time)
	var positions := PackedVector3Array()
	var tangents := PackedVector3Array()
	var curvatures := PackedFloat32Array()
	for i in a.positions.size():
		positions.append(a.positions[i].lerp(b.positions[i],weight))
		tangents.append(a.tangents[i].lerp(b.tangents[i],weight).normalized())
		curvatures.append(lerpf(a.curvatures[i],b.curvatures[i],weight))
	return {time=time,speed=lerpf(a.speed,b.speed,weight),positions=positions,tangents=tangents,curvatures=curvatures}
