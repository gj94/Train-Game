extends RefCounted
## Analog shaping shared by driving, camera and controller tests.

static func stick(value: Vector2, deadzone: float) -> Vector2:
	var length := minf(value.length(), 1.0)
	var threshold := clampf(deadzone, .05, .45)
	if length <= threshold: return Vector2.ZERO
	return value.normalized() * (length-threshold) / (1.0-threshold)

static func trigger(value: float) -> float:
	return clampf((value-.06)/.94, 0, 1)

static func handle(power: float, brake: float) -> float:
	# Brake always wins if both triggers are squeezed.
	var braking := trigger(brake)
	return -braking if braking > 0 else trigger(power)

static func cardinal(value: Vector2) -> Vector2i:
	if value.length() < .55: return Vector2i.ZERO
	if absf(value.x) > absf(value.y): return Vector2i(signi(int(signf(value.x))), 0)
	return Vector2i(0, signi(int(signf(value.y))))
