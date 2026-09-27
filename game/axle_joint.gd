extends RefCounted
## Axle-over-joint scheduler — port of the scheduling in the user's Sound Lab engine
## (railway-clang-simulator/src/physical.js, AxleJointSynth). Pure logic, no audio.
##
## Every axle is a point `x` metres behind the train's head. Rail joints sit every
## `joint_spacing` metres of travel. Feed it the train's odometer each frame; it returns
## every axle-over-joint hit whose impact kernel should have started by now. Kernels
## begin KERNEL_LEAD seconds before the wheel reaches the joint, so a hit reported a
## few ms late can still land on time by starting the kernel `late` seconds in.

const Data := preload("res://game/physical_model_data.gd")
const MAX_STEP := 40.0        # metres: bigger odometer jumps (teleports) are skipped, not machine-gunned

var axles: Array = []         # [{x, cls, car}]
var joint_spacing := 13.0
var odometer := 0.0
var _next := PackedInt32Array()


func setup(axle_list: Array, spacing: float, start_odometer: float) -> void:
	axles = axle_list
	joint_spacing = spacing
	_reset(start_odometer)


func _reset(odo: float) -> void:
	odometer = odo
	_next.resize(axles.size())
	for i in axles.size():
		_next[i] = floori((odo - axles[i].x) / joint_spacing) + 1


## Advance to `new_odometer` at `speed` m/s. Returns hits as
## {axle, cls, x, joint, late (s past the kernel start), gain (recorded loudness)}.
func advance(new_odometer: float, speed: float) -> Array:
	var hits := []
	if new_odometer - odometer > MAX_STEP or new_odometer < odometer:
		_reset(new_odometer)
		return hits
	if speed <= 0.0:
		odometer = new_odometer
		return hits
	var ahead := Data.KERNEL_LEAD * speed
	for i in axles.size():
		var a: Dictionary = axles[i]
		while true:
			var k := _next[i]
			var start_at: float = k * joint_spacing + a.x - ahead   # odometer where the kernel starts
			if start_at > new_odometer:
				break
			hits.append({axle = i, cls = a.cls, x = a.x, joint = k,
				late = (new_odometer - start_at) / speed, gain = recorded_gain(a.cls, a.car + k)})
			_next[i] = k + 1
	odometer = new_odometer
	return hits


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
