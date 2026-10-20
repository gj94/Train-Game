extends RefCounted
## Separate immutable baselines. Selecting one never edits another timetable or save.
const DAYS := [
	{id="standard",name="Standard · 100 services",description="The original hundred-service schedule, with the existing booked departure times.",
		starts="res://data/service_starts",times="res://data/railway_times",count=100},
	{id="intensive",name="Intensive · 140 services",description="More limited-stop relief trains and a slower all-stations K1. Extra traffic concentrates on the double-line middle section.",
		starts="res://data/timetables/intensive/starts",times="res://data/timetables/intensive/times",count=140}]

static func index_of(id: String) -> int:
	for i in DAYS.size():
		if DAYS[i].id==id:return i
	return 0

static func definition(id: String) -> Dictionary:
	return DAYS[index_of(id)]

static func available(id: String) -> bool:
	var day:=definition(id)
	var starts:=preload("res://persistence/service_starts.gd").catalogue(day.starts)
	var times:=preload("res://persistence/railway_times.gd").catalogue(day.times)
	return starts.ok and times.ok and starts.data.services.size()==day.count

static func stage_start(tree: SceneTree,choice: Dictionary) -> void:
	# Capture the selected day before clearing the previous journey's metadata.
	# Departure loaders carry an explicit ID; time-browser entries inherit it.
	choice.timetable_id=definition(str(choice.get("timetable_id",tree.get_meta("timetable_id","standard")))).id
	for key in preload("res://game/save_load.gd").META:
		if tree.has_meta(key):tree.remove_meta(key)
	tree.set_meta("prepared_start",choice)
