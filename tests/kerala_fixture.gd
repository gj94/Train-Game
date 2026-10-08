extends RefCounted
## Locate the real controlled home after geometry changes alter block counts.
static func kumbalam_approach(w) -> String:
	for sig in w.signals.values():
		if str(sig.edge).begins_with("TNU_KUMM_") and sig.dir==1 and sig.id not in w.automatic_signals:return sig.edge
	assert(false,"Kumbalam north-side home is missing")
	return ""

static func kumbalam_call(w) -> int:
	for i in w.trains.K1.timetable.stops.size():
		if str(w.trains.K1.timetable.stops[i].block).begins_with("KUMM_"):return i
	return -1

static func historical_crossing() -> RailWorld:
	# Preserve the original two-face/Tirunettur regression as an explicit synthetic
	# fixture. The current CSV scenario has one Kumbalam face and no TNU call.
	var w:=preload("res://sim/layouts/kerala_coast.gd").build_traffic()
	for st in w.stations:
		if st.code=="TNU":st.passenger_open=true
		if st.code=="KUMM":st.platform_details.KUMM_P2.platform_width=3.43
	for id in ["K1","K2"]:
		var t: Train=w.trains[id]
		var stops:=[]
		for stop in t.timetable.stops:
			stops.append({name=stop.name,block=stop.block,direction=stop.direction,position_m=stop.s,minutes_from_origin=stop.minutes_from_origin,dwell_minutes=stop.dwell_minutes})
		var road: String="TNU_P1" if id=="K1" else "KUMM_P2"
		var direction: int=1 if id=="K1" else -1
		stops.insert(1,{name="Tirunettur" if id=="K1" else "Kumbalam",block=road,direction=direction,position_m=preload("res://sim/berth_clearance.gd").marker(w,t,road,direction),minutes_from_origin=6 if id=="K1" else 13,dwell_minutes=1})
		assert(w.set_timetable(id,{departure="08:00",stops=stops}).ok)
	return w
