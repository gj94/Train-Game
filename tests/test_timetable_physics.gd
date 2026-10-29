extends RefCounted
const Physics = preload("res://tools/lib/timetable_physics.gd")

func source() -> Dictionary:
	return {id="LOCAL",stock="icf",rake="passenger",departure="06:00",day=1,priority=30,
		stops=[{block="A",direction=1,minutes_from_origin=0.0,dwell_minutes=0.0},
		{block="B",direction=1,minutes_from_origin=50.0,dwell_minutes=2.0},
		{block="C",direction=1,minutes_from_origin=100.0,dwell_minutes=0.0}]}

func test_measurement_does_not_inherit_scheduled_holds_or_mutate_service():
	var original := source();var before := var_to_bytes(original)
	var measured := Physics.probe(original)
	if var_to_bytes(original)!=before:return "Probe mutated its source"
	if measured.stops[1].minutes_from_origin>=1 or not is_equal_approx(measured.stops[2].minutes_from_origin,2.0+2.0/60.0):return "Old schedule still controls probe releases"
	for i in original.stops.size():
		var a: Dictionary=original.stops[i].duplicate();var b: Dictionary=measured.stops[i].duplicate()
		a.erase("minutes_from_origin");b.erase("minutes_from_origin")
		if a!=b:return "Probe changed calls, dwell or berth geometry"
	return measured.priority==original.priority and measured.stock==original.stock and measured.rake==original.rake

func test_profiles_share_departure_changes_but_not_physics_or_calls():
	var original:=source();var other:=original.duplicate(true)
	other.id="OTHER";other.departure="20:00";other.stops[1].minutes_from_origin=55.0
	if Physics.identity(original)!=Physics.identity(other):return "Departure or old allowance split identical physical workings"
	other.stops[1].dwell_minutes=3.0
	if Physics.identity(original)==Physics.identity(other):return "Changed dwell reused a measurement"
	other=original.duplicate(true);other.stock="lhb"
	if Physics.identity(original)==Physics.identity(other):return "Different equipment reused a measurement"
	other=original.duplicate(true);other.stops[1].block="D"
	return Physics.identity(original)!=Physics.identity(other)
