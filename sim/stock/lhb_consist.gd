extends RefCounted
## Geometry and playable formation, independent of renderer and imported assets.

const LOCO_LENGTH := 20.562
const COACH_LENGTH := 24.0
const BOGIE_HALF_SPACING := 7.45
const AXLE_HALF_SPACING := 1.28
const WHEEL_RADIUS := .4575
const FORMATION := ["B1", "B2", "B3", "B4", "A1", "A2"]
const LENGTH := LOCO_LENGTH + COACH_LENGTH * 6
const MASS := 408000.0  # 108 t locomotive + approximately 50 t loaded per coach


static func coach_center(index: int) -> float:
	return LOCO_LENGTH + (index + .5) * COACH_LENGTH


static func sound_axles() -> Array:
	var result := []
	for i in 2:
		for j in 3:
			result.append({x = LOCO_LENGTH * .5 - 6 + i * 12 + (j - 1) * 1.85,
				cls = i * 2 + j % 2, car = 0})
	for coach in FORMATION.size():
		for bogie in 2:
			for axle in 2:
				result.append({x = coach_center(coach) + (bogie * 2 - 1) * BOGIE_HALF_SPACING + (axle * 2 - 1) * AXLE_HALF_SPACING,
					cls = bogie * 2 + axle, car = coach + 1})
	return result
