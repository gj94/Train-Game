extends RefCounted
## Five seconds of timestamped physical wheel poses, independent of audio/rendering.
var frames := []

func clear() -> void:
	frames.clear()

func append(time: float,speed: float,positions: PackedVector3Array,tangents: PackedVector3Array,curvatures: PackedFloat32Array) -> void:
	frames.append({time=time,speed=speed,positions=positions,tangents=tangents,curvatures=curvatures})
	while frames.size()>2 and frames[1].time<time-5.0: frames.pop_front()

func sample(time: float,indices: Array=[]) -> Dictionary:
	if frames.is_empty(): return {}
	if time<frames[0].time: return {} # No invented pre-seek history.
	if time>=frames[-1].time and indices.is_empty(): return frames[-1]
	var low := 0
	var high := frames.size()-1
	while high-low>1:
		var mid := (low+high)/2
		if frames[mid].time<=time: low=mid
		else: high=mid
	var a: Dictionary=frames[low]
	var b: Dictionary=frames[high]
	var weight: float=clampf((time-a.time)/maxf(.000001,b.time-a.time),0,1)
	var positions := PackedVector3Array()
	var tangents := PackedVector3Array()
	var curvatures := PackedFloat32Array()
	# A retarded bogie query needs only its 2/3 wheels, not the entire consist.
	var selected: Array=range(a.positions.size()) if indices.is_empty() else indices
	for i in selected:
		positions.append(a.positions[i].lerp(b.positions[i],weight))
		tangents.append(a.tangents[i].lerp(b.tangents[i],weight).normalized())
		curvatures.append(lerpf(a.curvatures[i],b.curvatures[i],weight))
	return {time=time,speed=lerpf(a.speed,b.speed,weight),positions=positions,tangents=tangents,curvatures=curvatures}
