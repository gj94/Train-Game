extends RefCounted
## Read-only journey summary. Estimates are in simulation seconds, not wall time.
static func snapshot(world: RailWorld,train: Train) -> Dictionary:
	var tt=train.timetable
	if tt==null:return {scheduled=false}
	var completed:=1 # the train starts at its origin; count it among the calls
	for i in range(1,tt.stops.size()):
		if tt.actual_arrivals[i]>=0:completed+=1
	var result:={scheduled=true,total=tt.stops.size(),completed=completed,remaining=tt.stops.size()-completed,
		complete=tt.complete(),current=tt.stops[tt.index].name if tt.at_stop else "",missed=tt.missed_stop}
	if result.complete:return result
	var next: int=mini(tt.index+1,tt.stops.size()-1) if tt.at_stop else tt.index
	var stop: Dictionary=tt.stops[next]
	var distance:=world._stop_distance(train.path[0].edge,train.path[0].dir,train.head_s,stop,[])
	var cruise:=minf(train.max_speed,90.0/3.6)
	var running:=distance/cruise+maxf(0,cruise-train.speed)/maxf(.1,train.max_accel)*.5+cruise/maxf(.1,train.service_decel)*.5
	var dwell:=maxf(0,tt.release_time()-world.clock_seconds()) if tt.at_stop else 0.0
	var waiting: String=preload("res://sim/priority_dispatch.gd").hold_reason(world,train,true)
	var ns:=world.next_signal(train)
	if waiting.is_empty() and train.speed<.1 and not ns.is_empty() and world.aspect(ns.id)==RailWorld.Aspect.RED:
		waiting="Awaiting a proceed signal; the wait can change the arrival time."
	result.merge({next_name=stop.name,distance_m=distance,scheduled_arrival=tt.planned_arrival(next),
		estimated_seconds=running+dwell,waiting=waiting})
	return result
