extends RefCounted
## Axle-over-joint scheduler — port of the scheduling in the user's Sound Lab engine
## (railway-clang-simulator/src/physical.js, AxleJointSynth). Pure logic, no audio.
##
## Rail joints are fixed on the track: on every edge at s = offset + k * spacing
## (0 < s < length). Each frame the caller passes, for every axle, where its
## "look-ahead point" is on the track: the axle itself moved forward by the kernel
## lead distance, because impact kernels begin KERNEL_LEAD seconds before the wheel
## reaches the joint. When that point passes a joint (in either direction), a hit is
## reported; `late` says how far past the kernel start the frame is, so the kernel can
## start that far in and the clang still lands on time.

const Data := preload("res://game/physical_model_data.gd")
const MAX_STEP := 40.0        # metres: bigger per-frame moves (teleports, changing ends) are skipped

var axles: Array = []         # [{x, cls, car}]
var joint_spacing := 13.0
var joint_offset := 6.5
var _prev: Array = []         # per axle: last {edge, s, dir, length} or null


func setup(axle_list: Array, spacing: float, offset: float) -> void:
	axles = axle_list
	joint_spacing = spacing
	joint_offset = offset
	reset()


## Forget previous positions (after a teleport or changing ends): no hits until the next move.
func reset() -> void:
	_prev = []
	_prev.resize(axles.size())


## Joint positions (s) on an edge of the given length.
static func joints_on_edge(length: float, spacing: float, offset: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var s := offset
	while s < length:
		out.append(s)
		s += spacing
	return out


## `positions`: per axle, {edge, s, dir, length} of its look-ahead point this frame.
## Returns hits as {axle, cls, x, edge, joint (k on that edge), late (s), gain}.
func advance(positions: Array, speed: float) -> Array:
	var hits := []
	for i in axles.size():
		var now: Dictionary = positions[i]
		var before = _prev[i]
		_prev[i] = now
		if before == null or speed <= 0.0:
			continue
		var a: Dictionary = axles[i]
		if before.edge == now.edge:
			if absf(now.s - before.s) > MAX_STEP:
				continue
			_crossings(hits, i, a, now.edge, before.s, now.s, now.length, 0.0, now.s, speed)
		else:
			# Moved onto the next edge: rest of the old edge, then the start of the new one.
			var exit_s: float = before.length if before.dir > 0 else 0.0
			var entry_s: float = 0.0 if now.dir > 0 else now.length
			var on_new := absf(now.s - entry_s)
			if absf(exit_s - before.s) + on_new > MAX_STEP:
				continue
			_crossings(hits, i, a, before.edge, before.s, exit_s, before.length, on_new, exit_s, speed)
			_crossings(hits, i, a, now.edge, entry_s, now.s, now.length, 0.0, now.s, speed)
	return hits


## Joints between s0 and s1 (moving from s0 to s1) on one edge. `extra` = metres already
## travelled beyond `end_s` (on a following edge), for the lateness.
func _crossings(hits: Array, i: int, a: Dictionary, edge: String, s0: float, s1: float,
		length: float, extra: float, end_s: float, speed: float) -> void:
	var lo := minf(s0, s1)
	var hi := maxf(s0, s1)
	var k0 := floori((lo - joint_offset) / joint_spacing) + 1
	var k1 := floori((hi - joint_offset) / joint_spacing)
	for k in range(maxi(k0, 0), k1 + 1):
		var sj := joint_offset + k * joint_spacing
		if sj <= 0.0 or sj >= length:
			continue
		var past := absf(end_s - sj) + extra
		hits.append({axle = i, cls = a.cls, x = a.x, edge = edge, joint = k,
			late = past / speed, gain = recorded_gain(a.cls, joint_character(edge, k) + a.car)})


## A fixed per-joint number, so each joint keeps its own loudness pattern.
static func joint_character(edge: String, k: int) -> int:
	return absi(hash(edge)) % 97 + k


## Recorded per-hit loudness for an axle class, cycled (like hitFor() in the JS).
static func recorded_gain(cls: int, index: int) -> float:
	var seq: Array = Data.HITS[cls]
	return seq[posmod(index, seq.size())]


## Axles of a rake: `cars` cars of `pitch` metres, bogie centres `inset` metres in from each
## end of the body, `wheelbase` apart. Classes: 0/1 leading bogie, 2/3 trailing bogie.
static func rake_axles(cars: int, pitch: float, body: float, inset: float, wheelbase: float) -> Array:
	var out := []
	for c in cars:
		var base := c * pitch
		for b in [[inset, 0], [body - inset, 2]]:
			out.append({x = base + b[0] - wheelbase * 0.5, cls = b[1], car = c})
			out.append({x = base + b[0] + wheelbase * 0.5, cls = b[1] + 1, car = c})
	return out


## synth.js loudness laws, relative to the take's speed (1.0 at REFERENCE_SPEED).
static func impact_scale(kmh: float) -> float:
	return _impact_law(kmh) / _impact_law(Data.REFERENCE_SPEED)


static func rolling_scale(kmh: float) -> float:
	return _rolling_law(kmh) / _rolling_law(Data.REFERENCE_SPEED)


static func _impact_law(kmh: float) -> float:
	return minf(1.45, 0.3 + sqrt(maxf(0.0, kmh) / 90.0))


static func _rolling_law(kmh: float) -> float:
	return minf(1.5, pow(maxf(0.0, kmh) / 100.0, 0.8))


## Level of an impact heard `d` metres from where it happens (full level within NEAR_DISTANCE).
static func distance_gain(d: float) -> float:
	return Data.NEAR_DISTANCE / maxf(Data.NEAR_DISTANCE, d)


## Rolling-noise amplitude from wheel distances (1.0 = the take's average situation).
static func rolling_level(distances: PackedFloat32Array) -> float:
	var p := 0.0
	var n2: float = Data.NOISE_NEAR * Data.NOISE_NEAR
	for d in distances:
		p += 1.0 / (1.0 + d * d / n2)
	return sqrt(p / Data.NOISE_REF)
