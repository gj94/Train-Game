extends "res://tools/prepare_timetable_variant.gd"
## Identical physical stepping, waits, traffic, starts and safety audit.
## Construction-only timeline: omit redundant snapshots before the first train.
const ConstructionSnapshots = preload("res://tools/lib/construction_snapshots.gd")
var first_departure := INF

func write_time(w: RailWorld, timeline: Dictionary) -> bool:
	if first_departure == INF:
		for train: Train in w.trains.values():
			first_departure = minf(first_departure, train.timetable.departure)
	if not ConstructionSnapshots.needed(w.clock_seconds(), first_departure, timeline.states.size()):
		return true
	return super.write_time(w, timeline)
