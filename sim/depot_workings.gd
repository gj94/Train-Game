extends RefCounted
## Terminal unloading and signalled empty-stock workings. No teleport/removal.
const Berth := preload("res://sim/berth_clearance.gd")
const Timetable := preload("res://sim/timetable.gd")
const UNLOAD_SECONDS := 90.0

static func active(t: Train) -> bool:
	return t.depot.get("phase", "") == "working"

static func finished(w, t: Train) -> bool:
	return t.service_complete and (w.depots.is_empty() or t.depot.get("phase", "") == "stabled")

static func update(w, t: Train) -> void:
	if w.depots.is_empty() or t.timetable == null: return
	if active(t):
		if not t.timetable.complete(): return
		var road: String=t.depot.road
		# The entire rake must be beyond the fouling point; a head arrival alone
		# cannot release the main line or mark a service as safely stabled.
		if t.path.size()!=1 or t.path[0].edge!=road or not Berth.fits(w,t,road,t.head_s,t.path[0].dir,false):return
		t.depot.phase="stabled";t.depot.stabled_at=w.clock_seconds()
		t.status="Stabled in "+t.depot.name;t.controller=-1.0
		return
	if not t.service_complete or t.depot.get("phase", "")=="stabled":return
	if t.depot.is_empty():
		t.completed_timetable=t.timetable
		t.depot={phase="unloading",release=w.clock_seconds()+UNLOAD_SECONDS}
		t.controller=-1.0
	if w.clock_seconds()<t.depot.release:
		t.status="Service complete · unloading before depot"
		return
	var choice:=choose(w,t)
	if choice.is_empty():
		t.status="Service complete · waiting for a reachable depot berth"
		return
	# Reserve the final berth before departure. Other empty-stock workings may
	# queue at signals but can never claim the same eventual stabling road.
	w.depot_reservations[choice.road]=t.id
	var tt:=Timetable.new()
	tt.departure=w.clock_seconds()
	var dir: int=t.path[0].dir
	tt.stops=[{block=t.path[0].edge,name="Terminal unloading",direction=dir,s=t.head_s,minutes_from_origin=0.0,dwell_minutes=0.0},
		{block=choice.road,name=choice.name,direction=choice.direction,s=choice.s,minutes_from_origin=choice.distance/600.0+2.0,dwell_minutes=0.0}]
	tt.actual_arrivals.assign([w.clock_seconds(),-1.0]);tt.actual_departures.assign([-1.0,-1.0])
	t.timetable=tt;t.depot.merge(choice,true);t.depot.phase="working"
	t.depot.was_automatic=t.automatic;t.automatic=true;t.dispatch_priority=15
	t.status="Empty stock to "+choice.name
	w.dispatch_holds.erase(t.id)
	w.dispatcher().platform_preferences.erase(t.id)

static func choose(w, t: Train) -> Dictionary:
	var selected:={};var shortest:=INF
	var occ: Dictionary=w.occupancy()
	for road: String in w.depots:
		if w.depot_reservations.has(road) or occ.has(road):continue
		var entry: Dictionary=w.depots[road]
		if Berth.capacity(w,road,false)<t.length:continue
		var stop:={block=road,direction=entry.direction,s=Berth.marker(w,t,road,entry.direction,false)}
		var distance: float=w._stop_distance(t.path[0].edge,t.path[0].dir,t.head_s,stop,[])
		if distance<shortest:
			shortest=distance;selected={road=road,name=entry.name,direction=entry.direction,s=stop.s,distance=distance}
	return selected
