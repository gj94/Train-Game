extends RefCounted
## Isolated two-train KPY/STKT regression. Positions/timings were measured from
## the Classic Intensive 11:35/11:40 states on 24 Oct 2026. Rebuild physical
## berths on the current layout; never relabel an incompatible saved world.
const Layout:=preload("res://sim/layouts/kerala_coast.gd")
const Stock:=preload("res://sim/stock/ported_stock.gd")
const Berth:=preload("res://sim/berth_clearance.gd")

static func build(clock: int=41700) -> RailWorld:
	var w:=Layout.build();w.clock_start=28800;w.time=clock-w.clock_start
	var late:=clock==42000
	for id in ["K1","B002"]:
		var slow: bool=id=="K1"
		var t:=Train.new(id,1);Stock.configure(t,"icf" if slow else "lhb","passenger" if slow else "express")
		t.automatic=true;t.dispatch_priority=20 if slow else 75
		w.place_train(t,"KYJ_P1",Berth.marker(w,t,"KYJ_P1",1),1)
		var calls: Array=[["KPY_P1",204.6,2.5],["STKT_P3",216.2,2.5],["MQO_P1",224.8,2.5],["PRND_P4",234.6,2.5],["QLN_P1",247.5,2.5],["IRP_P1",256.4,2.5]] if slow else [["KPY_P4" if late else "KPY_P1",102.7,1.5],["QLN_P1",123.63,2.0],["PVU_P1",135.42,1.5],["VAK_P4",145.88,1.5],["KZK_P1",167.14,1.5],["TVCN_P1",174.28,2.0]]
		var stops: Array=[{block="KYJ_P1",direction=1,minutes_from_origin=0.0}]
		for call in calls:stops.append({block=call[0],direction=1,minutes_from_origin=call[1],dwell_minutes=call[2]})
		var result:=w.set_timetable(id,{departure="08:00" if slow else "10:00",stops=stops});assert(result.ok,result.reason)
		t.timetable.index=1;t.timetable.at_stop=late and slow
		var edge: String=("KPY_P1" if late else "OCR_KPY_D3") if slow else ("OCR_KPY_D2" if late else "KYJ_OCR_D0")
		var head: float=(752.889088111752 if late else 835.163362598985) if slow else (781.524796446488 if late else 508.184523765986)
		w.place_train(t,edge,head,1)
		t.speed=(0.0 if late else 27.3777777777777) if slow else (27.3777777777771 if late else 20.6881080637241)
		if not slow and not late:t.path=[{edge=edge,dir=1},{edge="KYJ_DEPOT_RD_ACCESS",dir=1}]
		if slow and late:t.timetable.actual_arrivals[1]=41878.0499999499
	var route:=w.set_route("OCR_KPY_D6-H","KPY-S4" if late else "KPY-S1");assert(route.ok,route.reason)
	if late:w.dispatch_holds.K1={other="B002",station="KPY",chainage=114639.887,kind="overtake",direction=1,created=w.time-55.45,arrived=false}
	w.dispatcher().enabled=true
	return w
