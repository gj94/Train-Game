extends RefCounted
const Kerala:=preload("res://sim/layouts/kerala_coast.gd")
const Stock:=preload("res://sim/stock/ported_stock.gd")
const Berth:=preload("res://sim/berth_clearance.gd")

static func build(reverse: bool=false) -> RailWorld:
	var w:=Kerala.build()
	w.clock_start=9*3600;w.time=1800
	var entries:=[["K1","icf","passenger","TUVR_P2",1,20,"SRTL_P2"],["K3","vb8","fixed","TUVR_P1",1,95,"SRTL_P1"],["K4","icf","express","TUVR_P3",-1,40,"ERS_P5"]]
	if reverse:entries=[["K1","icf","passenger","TUVR_P3",-1,20,"ERS_P5"],["K3","vb8","fixed","TUVR_P1",-1,95,"ERS_P6"],["K4","icf","express","TUVR_P2",1,40,"SRTL_P2"]]
	for entry in entries:
		var t:=Train.new(entry[0],100);Stock.configure(t,entry[1],entry[2]);t.dispatch_priority=entry[5];t.automatic=true
		var origin: String=("SRTL_P3" if reverse else "KUMM_P3") if t.id=="K3" else entry[3]
		w.place_train(t,origin,Berth.marker(w,t,origin,entry[4]),entry[4])
		var result:=w.set_timetable(t.id,{departure="09:00",stops=[{block=origin,direction=entry[4],minutes_from_origin=0},{block=entry[6],direction=entry[4],minutes_from_origin=40}]})
		if not result.ok:printerr("FIXTURE ",t.id," ",result.reason)
		assert(result.ok,result.reason)
		if t.id=="K3":
			t.timetable.index=1;t.timetable.at_stop=false
			w.place_train(t,entry[3],Berth.marker(w,t,entry[3],entry[4],false),entry[4])
	var st: Dictionary=w.stations.filter(func(s):return s.code=="TUVR")[0]
	w.dispatch_holds.K1={kind="overtake",other="K3",station="TUVR",chainage=st.s,direction=-1 if reverse else 1,created=w.time-1801}
	w.dispatcher().future_clearances.enabled=false
	return w

static func on_approach(w: RailWorld, id: String) -> void:
	var road:="EZP_TUVR_M3"
	w.place_train(w.trains[id],road,w.graph.edges[road].length-100,1)

static func just_departed(w: RailWorld, distance: float) -> void:
	var road:="TUVR_VAY_M0";var edge: Dictionary=w.graph.edges[road]
	var target: float=w.dispatch_holds.K1.chainage+distance
	var at: float=(target-edge.chainage_start)/(edge.chainage_end-edge.chainage_start)*edge.length
	w.place_train(w.trains.K3,road,at,1)
