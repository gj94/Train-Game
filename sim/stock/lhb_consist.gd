extends RefCounted
## Geometry and playable formation, independent of renderer and imported assets.

const LOCO_LENGTH := 20.562
const COACH_LENGTH := 24.0
const BOGIE_HALF_SPACING := 7.45
const AXLE_HALF_SPACING := 1.28
const WHEEL_RADIUS := .4575
const FORMATION := ["EOG1", "B1", "B2", "B3", "B4", "B5", "B6", "B7", "B8", "B9", "B10", "B11", "B12", "B13", "B14", "B15", "B16", "A1", "A2", "EOG2"]
const COACH_COUNT := 20
const LENGTH := LOCO_LENGTH + COACH_LENGTH * COACH_COUNT
# RDSO gross masses: 3A 51.36 t, 2A 48.66 t, generator/luggage van 59.31 t.
const MASS := 108000.0 + 16 * 51360.0 + 2 * 48660.0 + 2 * 59310.0


static func coach_kind(index: int) -> String:
	return "eog" if FORMATION[index].begins_with("EOG") else ("3a" if FORMATION[index].begins_with("B") else "2a")


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
