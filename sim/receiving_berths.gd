extends RefCounted
## Shared compatibility rule for admission and crossing/overtake predictions.
## A platform must fit this service and permit its following booked call.
static func roads(w,t: Train,st: Dictionary,edge: String,direction: int,free: Array) -> Array:
	var call:={}
	var final_call:=false
	var following:={}
	if t.timetable!=null:
		for i in range(t.timetable.index+(1 if t.timetable.at_stop else 0),t.timetable.stops.size()):
			var stop: Dictionary=t.timetable.stops[i]
			if str(stop.block).get_slice("_P",0)==st.code:
				call=stop;final_call=i==t.timetable.stops.size()-1
				if not final_call:following=t.timetable.stops[i+1]
				break
	var result:=[]
	for road: String in free:
		if not w.graph.allows(road,direction):continue
		if not call.is_empty() and st.get("platform_details",{}).get(road,{}).get("platform_width",1)<=0:continue
		if final_call and road!=call.block and not (w.scenery.get("geographic",false) and st.get("platform_details",{}).get(call.block,{}).get("platform_width",0)>0):continue
		if preload("res://sim/berth_clearance.gd").capacity(w,road,not call.is_empty())<t.length:continue
		var goal:={block=road,direction=direction,s=preload("res://sim/berth_clearance.gd").marker(w,t,road,direction,not call.is_empty())}
		if is_inf(w._stop_distance(edge,direction,w.graph.entry_s(edge,direction),goal,[])):continue
		if not following.is_empty() and is_inf(w._stop_distance(road,direction,w.graph.entry_s(road,direction),following,[])):continue
		result.append(road)
	return result
