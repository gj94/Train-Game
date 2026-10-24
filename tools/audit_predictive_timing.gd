extends SceneTree
## Compare detached numerical arrival forecasts against actual single-train AI runs.
## No prepared-state relabelling, timetable edits or changes to the running railway.
const Layout:=preload("res://sim/layouts/kerala_coast.gd")
const InputData:=preload("res://sim/dispatch_forecast_input.gd")
const Forecast:=preload("res://sim/dispatch_forecast.gd")
const Stock:=preload("res://sim/stock/ported_stock.gd")
const Berth:=preload("res://sim/berth_clearance.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var cases:=[];var okay:=true
	for direction in [1,-1]:
		for stock in ["icf","lhb","vb8","vb16"]:
			var result:=measure(stock,direction);cases.append(result);okay=okay and result.ok
			print("TIMING ",JSON.stringify(result))
	var output:="res://.local/dispatcher-v2-2026-10-24/arrival-calibration.json"
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({ok=okay,cases=cases},"\t"))
	quit(0 if okay else 1)
func measure(stock: String,direction: int) -> Dictionary:
	var w:=Layout.build();var train:=Train.new("PROBE",1)
	Stock.configure(train,stock,"passenger" if stock=="icf" else "express" if stock=="lhb" else "fixed")
	train.automatic=true
	var codes:=["KPY","STKT","MQO","PRND","QLN"]
	if direction==-1:codes.reverse()
	var stops:=[]
	for code: String in codes:
		var station: Dictionary=w.stations.filter(func(s):return s.code==code)[0]
		var roads: Array=station.platform_tracks.filter(func(r):
			var details: Dictionary=station.platform_details[r]
			return details.lane==("D" if direction==1 else "U") and details.platform_width>0 and Berth.limits(w,r,true).y-Berth.limits(w,r,true).x>=train.length)
		roads.sort_custom(func(a,b):return station.platform_details[a].service=="main" and station.platform_details[b].service!="main")
		if roads.is_empty():return {ok=false,stock=stock,direction=direction,reason="No compatible platform at "+code}
		stops.append({block=roads[0],direction=direction,minutes_from_origin=stops.size()*8.0,dwell_minutes=1.5})
	w.place_train(train,stops[0].block,Berth.marker(w,train,stops[0].block,direction),direction)
	var assigned:=w.set_timetable(train.id,{departure="08:00",stops=stops})
	if not assigned.ok:return {ok=false,stock=stock,direction=direction,reason=assigned.reason}
	w.dispatcher().enabled=true
	var f:=Forecast.new(InputData.topology(w));var input:=InputData.train(w,train);var forecasts:=[]
	for i in range(1,stops.size()):
		var stop: Dictionary=train.timetable.stops[i]
		forecasts.append({code=codes[i],road=stop.block,cautious=f.arrival(input,stop.block,stop.s,true,true),nominal=f.arrival(input,stop.block,stop.s,true,false)})
	var tt=train.timetable;var limit:=w.time+3600
	var decisions:=[];var previous_road:=""
	while not tt.complete() and w.time<limit and w.events.is_empty():
		w.step(.5)
		if not tt.at_stop and tt.stops[tt.index].block!=previous_road:
			previous_road=tt.stops[tt.index].block
			var state:=InputData.train(w,train);var stop: Dictionary=tt.stops[tt.index]
			decisions.append({call=tt.index,clock=w.clock_seconds(),road=previous_road,cautious=f.arrival(state,previous_road,stop.s,true,true),nominal=f.arrival(state,previous_road,stop.s,true,false)})
	for i in forecasts.size():
		var item: Dictionary=forecasts[i];item.actual=tt.actual_arrivals[i+1];item.actual_road=tt.stops[i+1].block;item.same_road=item.road==item.actual_road
		item.cautious_error=item.cautious.get("arrival",0)-item.actual
		item.nominal_error=item.nominal.get("arrival",0)-item.actual
	for item: Dictionary in decisions:
		item.actual=tt.actual_arrivals[item.call]
		item.actual_road=tt.stops[item.call].block
		item.same_road=item.road==item.actual_road
		item.cautious_error=item.cautious.get("arrival",0)-item.actual
		item.nominal_error=item.nominal.get("arrival",0)-item.actual
	return {ok=tt.complete() and w.events.is_empty() and forecasts.all(func(r):return r.cautious.ok and r.nominal.ok),stock=stock,direction=direction,events=w.events,forecasts=forecasts,decisions=decisions}
